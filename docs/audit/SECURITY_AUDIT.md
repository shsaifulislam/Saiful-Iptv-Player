# Security Audit

**Audit date:** 2026-11-11  
**Scope:** Static review of present workspace source/configuration only. No deployed Supabase project, secret store, network traffic, executable app, or external security scanner was available. Findings are risks to address, not proof of an exploit.

## Findings

### SEC-01 — Client-bundled environment values can expose secrets

**Risk: HIGH if private values are placed in `.env`; current private-key exposure is not established.** `pubspec.yaml` declares `.env` as a Flutter asset, while `bootstrap.dart` loads it as an asset and `AppConfig` exposes Supabase/API/YouTube keys. Client bundles are inspectable. `.env` is currently absent; `.env.example` contains placeholders. There is no `.gitignore`.

**Required treatment:** Keep only client-safe values in the app. A Supabase anon/publishable key is not a substitute for authorization; enforce RLS. Move service-role, signing, provider-admin, or other privileged credentials to a server-side secret manager. Add ignore rules and a secret-scanning release gate. Review the asset strategy before the first real `.env` is introduced.

### SEC-02 — Playlist credentials have no demonstrated secure persistence boundary

**Risk: HIGH.** `Playlist` includes `username` and `password`; `StorageKeys` defines secure-storage keys, but no secure storage, encryption, repository or serialization policy exists in the source inventory. It is not known whether credentials are currently persisted at all.

**Required treatment:** Treat provider credentials as secrets. Define whether credentials can be retained; use OS-backed secure storage and never place passwords in ordinary Hive/Isar rows, logs, analytics or cloud sync by default. Use least privilege, redaction, deletion semantics and an explicit threat model. Approval is required before implementing high-risk security changes.

### SEC-03 — Supabase authorization and row-level policies cannot be verified

**Risk: HIGH.** Supabase client/Auth source exists, but `supabase/migrations/` and `functions/` are empty; `config.toml` and `seed.sql` are empty. No database schema, RLS policy, grants, server functions or tenant-isolation tests are present. Auth client-side initialization alone does not establish backend security.

**Required treatment:** Design schema and RLS from user/device ownership requirements; default-deny access; test cross-user isolation; keep admin actions server-side. Do not connect real users/content until policy tests pass.

### SEC-04 — Personal identifiers and exception detail may enter logs

**Risk: MEDIUM.** Auth methods log email addresses and log exception objects. Bootstrap prints warning/error records. Release level filters most info logs, but error payloads can still contain sensitive provider/response data. No redaction policy or production sink controls are present.

**Required treatment:** Redact email, stream URLs, credentials, tokens and provider responses; use structured event codes; avoid logging raw exception bodies; define retention and access controls before production telemetry.

### SEC-05 — Global error handler suppresses default uncaught-error behavior

**Risk: MEDIUM.** `PlatformDispatcher.instance.onError` logs and returns `true`, marking errors handled. This may hide failures without crash reporting or recovery; the configured crash-reporting flag is not wired to a service.

**Required treatment:** Add tested error boundaries and production crash reporting with redaction, then choose deliberate propagation/recovery semantics. Do not silently classify an error as handled without evidence.

### SEC-06 — Content authorization and provider policy are not represented in implementation

**Risk: MEDIUM (legal/provider compliance).** README describes IPTV, VOD, catch-up and Xtream support, but no source authorization model, rights metadata, provider policy or legal review exists. The implementation is largely absent, so no unauthorized access was demonstrated.

**Required treatment:** Restrict product language and flows to user-owned/licensed/explicitly authorized content. Do not scrape unauthorized sources, bypass provider auth/DRM, or circumvent YouTube ads. Document user responsibility and provider terms as appropriate.

## Positive Evidence and Limitations

- `.env.example` contains placeholder Supabase values, not an actual credential.
- `.env` is absent in the workspace.
- `flutter_secure_storage` is declared as a dependency, and secure-storage key names exist; no usage was found in the source inventory.
- No dependency vulnerability scan, secret scan, penetration test, backend policy inspection or release-bundle inspection was run. No claim of security clearance is made.

## Required Security Gate Before Production

1. Threat model covering playlist credentials, user data, local device compromise, sync and admin access.
2. Secret inventory and automated prevention of private client-bundle secrets.
3. Secure local credential storage and redaction tests.
4. Supabase RLS/grant tests for anonymous, owner, other-user and admin cases.
5. Dependency and license review against a resolved lockfile.
6. Privacy/retention/consent review for analytics, history, diagnostics and cloud sync.
7. Written content-provider authorization and YouTube policy review.

No destructive or security-sensitive code changes were made in this audit. HIGH/CRITICAL security remediation should be separately approved and reviewed before implementation.
