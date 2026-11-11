begin;

alter table public.sync_jobs drop constraint sync_entity_check;
alter table public.sync_jobs add constraint sync_entity_check
  check (entity_type in (
    'playlist', 'channel', 'favorite', 'watch_history', 'watch_progress',
    'setting', 'movie_metadata', 'epg_program', 'saved_youtube_link'
  ));
alter table public.sync_events drop constraint sync_events_entity_check;
alter table public.sync_events add constraint sync_events_entity_check
  check (entity_type in (
    'playlist', 'channel', 'favorite', 'watch_history', 'watch_progress',
    'setting', 'movie_metadata', 'epg_program', 'saved_youtube_link'
  ));

create or replace function public.validate_user_settings()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if public.json_contains_forbidden_sync_key(new.settings) then
    raise exception using errcode = '22023', message = 'secret_field_forbidden';
  end if;
  return new;
end;
$$;
create trigger user_settings_secret_guard before insert or update on public.user_settings
  for each row execute function public.validate_user_settings();

create or replace function public.apply_sync_changes(p_device_id uuid, p_changes jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_change jsonb;
  v_payload jsonb;
  v_job_id uuid;
  v_event_id bigint;
  v_entity_id uuid;
  v_idempotency uuid;
  v_entity text;
  v_operation text;
  v_target_type text;
  v_target_id uuid;
  v_base_revision bigint;
  v_current_revision bigint;
  v_new_revision bigint;
  v_found boolean;
  v_accepted jsonb := '[]'::jsonb;
  v_conflicts jsonb := '[]'::jsonb;
  v_rejected jsonb := '[]'::jsonb;
  v_error_code text;
  v_title text;
  v_name text;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'unauthorized';
  end if;
  if jsonb_typeof(p_changes) <> 'array' or jsonb_array_length(p_changes) > 100 then
    raise exception using errcode = '22023', message = 'invalid_batch';
  end if;
  if not exists (
    select 1 from public.devices d
    where d.id = p_device_id and d.user_id = v_user_id and d.revoked_at is null
  ) then
    raise exception using errcode = '42501', message = 'device_not_authorized';
  end if;

  for v_change in select value from jsonb_array_elements(p_changes) loop
    v_job_id := null;
    v_event_id := null;
    v_error_code := null;
    begin
      if jsonb_typeof(v_change) <> 'object'
         or jsonb_typeof(v_change -> 'payload') <> 'object'
         or public.json_contains_forbidden_sync_key(v_change -> 'payload') then
        raise exception using errcode = '22023', message = 'invalid_payload';
      end if;
      if coalesce(v_change ->> 'idempotency_key', '') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
         or coalesce(v_change ->> 'entity_id', '') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
        raise exception using errcode = '22023', message = 'invalid_identifier';
      end if;

      v_idempotency := (v_change ->> 'idempotency_key')::uuid;
      v_entity_id := (v_change ->> 'entity_id')::uuid;
      v_entity := v_change ->> 'entity_type';
      v_operation := v_change ->> 'operation';
      v_payload := v_change -> 'payload';
      v_base_revision := nullif(v_change ->> 'base_revision', '')::bigint;
      if v_entity not in (
        'playlist', 'channel', 'favorite', 'watch_history', 'watch_progress', 'setting'
      ) or v_operation not in ('upsert', 'delete') then
        raise exception using errcode = '22023', message = 'unsupported_change';
      end if;

      insert into public.sync_jobs(
        user_id, device_id, idempotency_key, entity_type, entity_id,
        operation, payload, status
      ) values (
        v_user_id, p_device_id, v_idempotency, v_entity, v_entity_id,
        v_operation, v_payload, 'processing'
      ) on conflict (user_id, idempotency_key) do nothing
      returning id into v_job_id;

      if v_job_id is null then
        v_accepted := v_accepted || jsonb_build_array(jsonb_build_object(
          'idempotency_key', v_idempotency, 'duplicate', true
        ));
        continue;
      end if;

      v_target_type := v_payload ->> 'target_type';
      v_target_id := null;
      if coalesce(v_payload ->> 'target_id', '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
        v_target_id := (v_payload ->> 'target_id')::uuid;
      end if;
      v_current_revision := null;
      v_found := false;

      if v_entity = 'playlist' then
        select revision into v_current_revision from public.playlists
         where id = v_entity_id and owner_id = v_user_id for update;
        v_found := found;
      elsif v_entity = 'channel' then
        select revision into v_current_revision from public.channels
         where id = v_entity_id and owner_id = v_user_id for update;
        v_found := found;
      elsif v_entity = 'favorite' then
        select revision into v_current_revision from public.favorites
         where id = v_entity_id and owner_id = v_user_id for update;
        v_found := found;
      elsif v_entity = 'watch_progress' then
        if v_target_type = 'channel' then
          select revision into v_current_revision from public.watch_progress
           where channel_id = v_target_id and owner_id = v_user_id for update;
          v_found := found;
        elsif v_target_type = 'movie' then
          select revision into v_current_revision from public.watch_progress
           where movie_id = v_target_id and owner_id = v_user_id for update;
          v_found := found;
        end if;
      elsif v_entity = 'setting' then
        if v_entity_id <> v_user_id then
          raise exception using errcode = '42501', message = 'owner_mismatch';
        end if;
        select revision into v_current_revision from public.user_settings
         where user_id = v_user_id for update;
        v_found := found;
      end if;

      if v_operation = 'upsert' and v_base_revision is not null
         and ((v_found and v_base_revision <> v_current_revision)
           or (not v_found and v_base_revision <> 0)) then
        update public.sync_jobs set status = 'retry', error_code = 'revision_conflict'
         where id = v_job_id;
        v_conflicts := v_conflicts || jsonb_build_array(jsonb_build_object(
          'idempotency_key', v_idempotency,
          'entity_type', v_entity,
          'entity_id', v_entity_id,
          'server_revision', v_current_revision
        ));
        continue;
      end if;

      if v_operation = 'delete' then
        if v_entity = 'playlist' then
          delete from public.playlists where id = v_entity_id and owner_id = v_user_id;
        elsif v_entity = 'channel' then
          delete from public.channels where id = v_entity_id and owner_id = v_user_id;
        elsif v_entity = 'favorite' then
          delete from public.favorites where id = v_entity_id and owner_id = v_user_id;
        elsif v_entity = 'watch_history' then
          delete from public.watch_history where client_event_id = v_entity_id and owner_id = v_user_id;
        elsif v_entity = 'watch_progress' then
          delete from public.watch_progress where id = v_entity_id and owner_id = v_user_id;
        elsif v_entity = 'setting' then
          raise exception using errcode = '22023', message = 'setting_delete_not_supported';
        end if;
        v_new_revision := coalesce(v_current_revision, 0) + 1;
        insert into public.sync_events(owner_id, entity_type, entity_id, operation, revision, payload)
        values (v_user_id, v_entity, v_entity_id, 'delete', v_new_revision, '{}'::jsonb)
        returning id into v_event_id;
      else
        v_new_revision := coalesce(v_current_revision, 0) + 1;
        if v_entity = 'playlist' then
          v_name := trim(coalesce(v_payload ->> 'name', ''));
          if char_length(v_name) not between 1 and 120
             or v_payload ->> 'source_kind' not in ('m3u_url', 'm3u_file', 'authorized_provider')
             or (v_payload ? 'source_host' and v_payload ->> 'source_host' !~ '^[A-Za-z0-9.-]{1,253}$') then
            raise exception using errcode = '22023', message = 'invalid_playlist';
          end if;
          insert into public.playlists(id, owner_id, name, source_kind, source_host,
            credentials_required, enabled, sort_order, revision)
          values (v_entity_id, v_user_id, v_name, v_payload ->> 'source_kind',
            nullif(v_payload ->> 'source_host', ''),
            coalesce((v_payload ->> 'credentials_required')::boolean, false),
            coalesce((v_payload ->> 'enabled')::boolean, true),
            coalesce((v_payload ->> 'sort_order')::integer, 0), v_new_revision)
          on conflict (id) do update set
            name = excluded.name, source_kind = excluded.source_kind,
            source_host = excluded.source_host,
            credentials_required = excluded.credentials_required,
            enabled = excluded.enabled, sort_order = excluded.sort_order,
            revision = excluded.revision, updated_at = now()
          where public.playlists.owner_id = v_user_id;
          v_payload := jsonb_build_object('name', v_name,
            'source_kind', v_payload ->> 'source_kind',
            'source_host', nullif(v_payload ->> 'source_host', ''),
            'credentials_required', coalesce((v_payload ->> 'credentials_required')::boolean, false),
            'enabled', coalesce((v_payload ->> 'enabled')::boolean, true),
            'sort_order', coalesce((v_payload ->> 'sort_order')::integer, 0));
        elsif v_entity = 'channel' then
          if not exists (select 1 from public.playlists p
                         where p.id = (v_payload ->> 'playlist_id')::uuid
                           and p.owner_id = v_user_id) then
            raise exception using errcode = '42501', message = 'playlist_not_owned';
          end if;
          v_name := trim(coalesce(v_payload ->> 'name', ''));
          if char_length(v_name) not between 1 and 240
             or v_payload ->> 'stream_kind' not in ('live', 'movie', 'series')
             or (v_payload ? 'logo_url' and v_payload ->> 'logo_url' !~ '^https://') then
            raise exception using errcode = '22023', message = 'invalid_channel';
          end if;
          insert into public.channels(id, owner_id, playlist_id, provider_item_id, name,
            group_title, logo_url, tvg_id, stream_kind, sort_order, revision)
          values (v_entity_id, v_user_id, (v_payload ->> 'playlist_id')::uuid,
            nullif(v_payload ->> 'provider_item_id', ''), v_name,
            nullif(v_payload ->> 'group_title', ''), nullif(v_payload ->> 'logo_url', ''),
            nullif(v_payload ->> 'tvg_id', ''), v_payload ->> 'stream_kind',
            coalesce((v_payload ->> 'sort_order')::integer, 0), v_new_revision)
          on conflict (id) do update set
            playlist_id = excluded.playlist_id, provider_item_id = excluded.provider_item_id,
            name = excluded.name, group_title = excluded.group_title, logo_url = excluded.logo_url,
            tvg_id = excluded.tvg_id, stream_kind = excluded.stream_kind,
            sort_order = excluded.sort_order, revision = excluded.revision, updated_at = now()
          where public.channels.owner_id = v_user_id;
        elsif v_entity = 'favorite' then
          if v_target_type = 'channel' then
            insert into public.favorites(id, owner_id, channel_id, revision)
            values (v_entity_id, v_user_id, v_target_id, v_new_revision)
            on conflict (owner_id, channel_id) where channel_id is not null
            do update set revision = public.favorites.revision + 1, updated_at = now();
          elsif v_target_type = 'movie' then
            insert into public.favorites(id, owner_id, movie_id, revision)
            values (v_entity_id, v_user_id, v_target_id, v_new_revision)
            on conflict (owner_id, movie_id) where movie_id is not null
            do update set revision = public.favorites.revision + 1, updated_at = now();
          else
            raise exception using errcode = '22023', message = 'invalid_favorite_target';
          end if;
        elsif v_entity = 'watch_history' then
          if v_target_id is null or v_target_type not in ('channel', 'movie') then
            raise exception using errcode = '22023', message = 'invalid_history_target';
          end if;
          if coalesce((v_payload ->> 'position_seconds')::bigint, -1) < 0
             or (v_payload ? 'duration_seconds' and (v_payload ->> 'duration_seconds')::bigint < 0) then
            raise exception using errcode = '22023', message = 'invalid_watch_position';
          end if;
          insert into public.watch_history(owner_id, client_event_id, channel_id, movie_id,
            watched_at, position_seconds, duration_seconds)
          values (v_user_id, v_entity_id,
            case when v_target_type = 'channel' then v_target_id end,
            case when v_target_type = 'movie' then v_target_id end,
            coalesce((v_payload ->> 'watched_at')::timestamptz, now()),
            (v_payload ->> 'position_seconds')::bigint,
            nullif(v_payload ->> 'duration_seconds', '')::bigint)
          on conflict (owner_id, client_event_id) do nothing;
        elsif v_entity = 'watch_progress' then
          if v_target_id is null or v_target_type not in ('channel', 'movie')
             or coalesce((v_payload ->> 'position_seconds')::bigint, -1) < 0
             or (v_payload ? 'duration_seconds' and (v_payload ->> 'duration_seconds')::bigint < 0) then
            raise exception using errcode = '22023', message = 'invalid_watch_progress';
          end if;
          if v_target_type = 'channel' then
            insert into public.watch_progress(owner_id, channel_id, position_seconds,
              duration_seconds, completed, revision)
            values (v_user_id, v_target_id, (v_payload ->> 'position_seconds')::bigint,
              nullif(v_payload ->> 'duration_seconds', '')::bigint,
              coalesce((v_payload ->> 'completed')::boolean, false), v_new_revision)
            on conflict (owner_id, channel_id) where channel_id is not null do update set
              position_seconds = excluded.position_seconds,
              duration_seconds = excluded.duration_seconds,
              completed = excluded.completed,
              revision = public.watch_progress.revision + 1,
              updated_at = now();
          else
            insert into public.watch_progress(owner_id, movie_id, position_seconds,
              duration_seconds, completed, revision)
            values (v_user_id, v_target_id, (v_payload ->> 'position_seconds')::bigint,
              nullif(v_payload ->> 'duration_seconds', '')::bigint,
              coalesce((v_payload ->> 'completed')::boolean, false), v_new_revision)
            on conflict (owner_id, movie_id) where movie_id is not null do update set
              position_seconds = excluded.position_seconds,
              duration_seconds = excluded.duration_seconds,
              completed = excluded.completed,
              revision = public.watch_progress.revision + 1,
              updated_at = now();
          end if;
        elsif v_entity = 'setting' then
          if v_entity_id <> v_user_id
             or v_payload ->> 'theme' not in ('dark', 'system', 'light')
             or jsonb_typeof(coalesce(v_payload -> 'settings', '{}'::jsonb)) <> 'object'
             or public.json_contains_forbidden_sync_key(coalesce(v_payload -> 'settings', '{}'::jsonb)) then
            raise exception using errcode = '22023', message = 'invalid_setting';
          end if;
          insert into public.user_settings(user_id, theme, locale, settings, revision)
          values (v_user_id, v_payload ->> 'theme',
            coalesce(nullif(v_payload ->> 'locale', ''), 'en'),
            coalesce(v_payload -> 'settings', '{}'::jsonb), v_new_revision)
          on conflict (user_id) do update set theme = excluded.theme,
            locale = excluded.locale, settings = excluded.settings,
            revision = public.user_settings.revision + 1, updated_at = now();
          select revision into v_new_revision from public.user_settings where user_id = v_user_id;
        end if;

        insert into public.sync_events(owner_id, entity_type, entity_id, operation, revision, payload)
        values (v_user_id, v_entity, v_entity_id, 'upsert', v_new_revision, v_payload)
        returning id into v_event_id;
      end if;

      update public.sync_jobs set status = 'completed', completed_at = now(), error_code = null
       where id = v_job_id;
      update public.devices set last_seen_at = now()
       where id = p_device_id and user_id = v_user_id;
      v_accepted := v_accepted || jsonb_build_array(jsonb_build_object(
        'idempotency_key', v_idempotency,
        'entity_type', v_entity,
        'entity_id', v_entity_id,
        'server_revision', v_new_revision,
        'cursor', v_event_id
      ));
    exception when others then
      v_error_code := case sqlstate
        when '42501' then 'forbidden'
        when '22023' then 'invalid_change'
        when '23503' then 'target_not_found'
        when '23505' then 'duplicate_change'
        else 'sync_rejected'
      end;
      if v_job_id is not null then
        update public.sync_jobs set status = 'rejected', error_code = v_error_code
         where id = v_job_id;
      end if;
      v_rejected := v_rejected || jsonb_build_array(jsonb_build_object(
        'idempotency_key', v_change ->> 'idempotency_key',
        'code', v_error_code
      ));
    end;
  end loop;

  return jsonb_build_object(
    'accepted', v_accepted,
    'conflicts', v_conflicts,
    'rejected', v_rejected
  );
end;
$$;

revoke all on function public.apply_sync_changes(uuid, jsonb) from public, anon;
grant execute on function public.apply_sync_changes(uuid, jsonb) to authenticated;

commit;
