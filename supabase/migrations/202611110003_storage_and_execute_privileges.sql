begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-avatars', 'profile-avatars', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = false,
  file_size_limit = 5242880,
  allowed_mime_types = excluded.allowed_mime_types;

create policy profile_avatars_read_own on storage.objects
  for select to authenticated
  using (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy profile_avatars_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy profile_avatars_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy profile_avatars_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

revoke all on function public.create_profile_for_new_user() from public, anon, authenticated;
revoke all on function public.register_device(text, text, text, text) from public, anon;
revoke all on function public.revoke_device(uuid) from public, anon;
revoke all on function public.submit_bug_report(uuid, text, text, text, text, text, boolean, jsonb) from public, anon;
revoke all on function public.apply_sync_changes(uuid, jsonb) from public, anon;
revoke all on function public.is_app_admin() from public, anon;
grant execute on function public.is_app_admin() to authenticated;

grant execute on function public.register_device(text, text, text, text) to authenticated;
grant execute on function public.revoke_device(uuid) to authenticated;
grant execute on function public.submit_bug_report(uuid, text, text, text, text, text, boolean, jsonb) to authenticated;
grant execute on function public.apply_sync_changes(uuid, jsonb) to authenticated;

commit;
