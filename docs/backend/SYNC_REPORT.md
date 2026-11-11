# Saiful IPTV Player — Cloud Sync Protocol & Conflict Resolution Report

## 1. Overview & Data Scope

The Saiful IPTV Player cloud synchronization protocol provides bidirectional synchronization between mobile, desktop, TV, and web platforms while adhering to strict privacy and data isolation rules.

### Scope of Synchronized Entities
1. **Playlists**: Metadata, titles, source type (`m3u_url`, `m3u_file`), enabled state, sort order.
2. **Channels**: Channel names, group/category titles, logos, stream kind, sort order.
3. **Favorites**: Bookmarked live channels and VOD movie identifiers.
4. **Watch History**: Watched titles, playback duration, and completion flags.
5. **Watch Progress**: Current playback positions (seconds) for cross-device resume.
6. **User Settings**: UI theme, locale, playback preferences.

### Absolute Exclusions
- **Local Media Files**: Users' local video, photo, and audio files are never uploaded or synced.
- **Provider Credentials**: Xtream Codes passwords, username tokens, and basic-auth credentials remain purely in client-side secure storage (`SecureCredentialVault`).

---

## 2. Synchronization Flow

```
+-----------------------------------------------------------------------------------------+
|                                    LOCAL DEVICE                                         |
|  +-----------------------+     +------------------------+     +-----------------------+ |
|  | Local Library Stores  | --> | SyncOutbox (Offline Q) | --> | CloudSyncRepository   | |
|  +-----------------------+     +------------------------+     +-----------+-----------+ |
+---------------------------------------------------------------------------|-------------+
                                                                            |
                                   1. Push Batch (Up to 100 changes)        |
                                      + Idempotency UUIDs                   |
                                      + Base Revisions                      v
+---------------------------------------------------------------------------+-------------+
|                                    CLOUD BACKEND                                        |
|  +------------------------------------------------------------------------------------+ |
|  | Edge Function: /sync (POST) -> RPC: apply_sync_changes(device_id, changes)         | |
|  | - Verify caller owns registered, unrevoked device_id                               | |
|  | - Check idempotency keys in sync_jobs (Acknowledge duplicates without bumping rev)| |
|  | - Check base_revision vs server_revision                                           | |
|  |     * base_revision >= server_revision -> APPLY UPSERT & bump revision +1          | |
|  |     * base_revision < server_revision  -> CONFLICT (Return server payload & rev)   | |
|  | - Append accepted change to sync_events stream                                     | |
|  +------------------------------------------------------------------------------------+ |
|                                           |                                             |
|                                           | 2. Sync Response Envelope                   |
|                                           |    { accepted: [...], conflicts: [...] }    |
|                                           v                                             |
+-------------------------------------------+---------------------------------------------+
                                            |
                                            | 3. Pull Changes: /sync?cursor=X&device_id=Y
                                            v
+-----------------------------------------------------------------------------------------+
|                                    LOCAL DEVICE                                         |
|  +------------------------------------------------------------------------------------+ |
|  | - Mark accepted mutations clean in LocalSyncStore                                  | |
|  | - Handle Conflicts: Compare updated_at timestamps (LWW)                             | |
|  |     * If local is newer: Rebase pending change with server revision & retry next   | |
|  |     * If remote is newer: Accept remote state & remove from pending queue          | |
|  | - Ingest remote events from sync_events & advance local cursor                     | |
|  | - Update last_sync_at timestamp & report success                                   | |
|  +------------------------------------------------------------------------------------+ |
+-----------------------------------------------------------------------------------------+
```

---

## 3. Conflict Resolution Strategy

1. **Monotonic Revision Numbers**: Every synchronizable entity in PostgreSQL maintains an integer `revision` starting at 1.
2. **Conflict Detection**:
   When the client pushes a mutation with `base_revision = K`, if the server has already progressed to revision `N > K`, the change is immediately flagged as a conflict:
   ```json
   {
     "conflicts": [
       {
         "idempotency_key": "uuid-...",
         "entity_type": "playlist",
         "entity_id": "uuid-...",
         "server_revision": 2,
         "server_payload": { "name": "Sports Ultra", "revision": 2 }
       }
     ]
   }
   ```
3. **Client-Side Last-Write-Wins (LWW)**:
   - The client compares the local modification timestamp (`updated_at`) against the server event timestamp (`conflict_updated_at`).
   - If local modification was made after the remote event, local state wins: the client rebases the base revision to `server_revision` and generates a fresh `idempotency_key` for immediate resubmission.
   - If remote state is newer, the remote payload is accepted into local cache and the pending change is dropped.

---

## 4. Offline Queue & Exponential Backoff Retry Policy

- **Offline Storage**: The `SyncOutbox` and `LocalSyncStore` maintain pending mutations persistently in client storage across application restarts.
- **Maximum Queue Depth**: Capped at 1,000 items per user to prevent storage bloat.
- **Retry Schedule**:
  When a batch receives a transient network error, HTTP 503, or rate limit:
  $$\Delta t = \min(3600, 5 \times 2^{\min(\text{attempts}, 8)}) \text{ seconds}$$
  - Attempt 0: 5 seconds
  - Attempt 1: 10 seconds
  - Attempt 2: 20 seconds
  - Attempt 3: 40 seconds
  - Attempt 4: 80 seconds
  - Attempt 8+: 1280 seconds (capped at 3600s / 1 hr max)

---

## 5. Duplicate Prevention

Each local change is tagged with a client-generated UUID `idempotency_key`:
- The backend ledger table `sync_jobs` records every processed idempotency key.
- If network disconnection causes the client to resubmit a batch, the server recognizes previously applied keys and returns:
  ```json
  { "idempotency_key": "...", "duplicate": true }
  ```
- This prevents duplicate entity creation, avoids duplicate stream events, and preserves ledger integrity.

---

## 6. Sync Failure Reporting

The `SyncReport` model captures comprehensive execution metrics:
- `accepted`: Number of successfully acknowledged mutations.
- `rejected`: Number of permanently rejected changes (e.g. invalid format).
- `conflictsResolved`: Number of conflicts resolved via LWW.
- `lastSyncedAt`: UTC timestamp of the last successful synchronization pass.
- `errorCode`: Standardized failure codes (`sync_service_unavailable`, `device_not_authorized`, `invalid_sync_batch`, `rate_limited`).

