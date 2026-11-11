# Production Deployment Guide

**Saiful IPTV Player**  
**Version**: 1.0.0  
**Authority**: Release Manager & DevOps Engineer  

---

## 1. Cloud Infrastructure Overview

Saiful IPTV Player leverages a serverless cloud foundation on Supabase:
- **Database**: Managed PostgreSQL 15 with automated point-in-time recovery (PITR) and Row Level Security.
- **Authentication**: Supabase Auth with OAuth2 / PKCE and JWT token rotation.
- **Storage**: Supabase Object Storage buckets for user avatars (`avatars`) and cached channel logos (`logos`).
- **Edge Functions**: Deno TypeScript functions for server-side playlist synchronization and periodic EPG schedule caching.
- **Admin Portal**: Static single-page dashboard with JWT authentication.

---

## 2. Database Migration Deployment

All database schemas, indexes, constraints, and RLS policies are version-controlled in `supabase/migrations/`:

```
supabase/migrations/
├── 202611110001_backend_foundation.sql
├── 202611110002_sync_rpc.sql
├── 202611110003_storage_and_execute_privileges.sql
└── 202611110004_admin_release_metadata.sql
```

### Applying Migrations via CLI:
```bash
# 1. Login to Supabase CLI
supabase login

# 2. Link your production project
supabase link --project-ref <your-project-ref>

# 3. Push and apply migrations
supabase db push
```

### Applying Migrations via Direct PostgreSQL Connection:
```bash
psql "postgresql://postgres:[PASSWORD]@db.<your-project-ref>.supabase.co:5432/postgres" \
  -f supabase/migrations/202611110001_backend_foundation.sql \
  -f supabase/migrations/202611110002_sync_rpc.sql \
  -f supabase/migrations/202611110003_storage_and_execute_privileges.sql \
  -f supabase/migrations/202611110004_admin_release_metadata.sql
```

---

## 3. Storage Bucket Initialization

Execute SQL or configure through the Supabase Dashboard:
1. Bucket `avatars`: Public read, authenticated user write (`storage.foldername(name)[1] = auth.uid()`).
2. Bucket `logos`: Public read, admin-only write.

---

## 4. Admin Portal Hosting

The admin portal is located in `admin/index.html`. It is a standalone, client-authenticated dashboard that connects directly to the Supabase API:
- Host on any HTTPS static web host: **Cloudflare Pages**, **Vercel**, or **AWS S3 + CloudFront**.
- Ensure CORS in Supabase Dashboard permits the admin portal domain:
  - Allowed Origins: `https://admin.saifuliptv.com`

---

## 5. Mobile & TV Distribution Checklist

### A. Google Play Store (Mobile & Tablet)
- [ ] Upload `app-release.aab` to Production Track.
- [ ] Provide 7" and 10" tablet screenshots.
- [ ] Verify Content Rating Questionnaire (PG-13 / Media Player classification).
- [ ] Link Privacy Policy URL (`docs/PRIVACY.md`).

### B. Android TV Distribution Track
- [ ] Include Leanback banner asset (`320x180 px` PNG).
- [ ] Verify D-Pad remote navigation without touchscreen dependency.
- [ ] Complete Android TV App Quality Review checklist.

### C. Windows Desktop Distribution
- [ ] Package release binaries into signed MSIX installer using Windows SDK `MakeAppx` and `SignTool`.
- [ ] Publish to Microsoft Store or GitHub Releases.

