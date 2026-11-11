# Security Architecture & Audit Report

**Saiful IPTV Player**  
**Classification**: Production Security Specification  
**Version**: 1.0.0  
**Authority**: Principal Security Engineer & Software Architect  

---

## 1. Executive Summary

Saiful IPTV Player employs a **defense-in-depth security model** tailored for modern multi-platform media applications. The architecture guarantees tenant isolation, protects user privacy, sanitizes third-party stream URLs, and enforces strict boundary validation across mobile, desktop, TV, and cloud services.

---

## 2. Threat Modeling & Security Boundaries

```
[ Client App (Flutter) ]
     │
     ├── (1. HTTPS / PKCE Auth) ─────────► [ Supabase Auth ]
     │
     ├── (2. Parameterized RLS) ─────────► [ PostgreSQL 15 Database ]
     │
     ├── (3. Validated Token) ───────────► [ Role-Protected Admin Panel ]
     │
     └── (4. SSRF-Filtered Stream) ──────► [ Third-Party IPTV / CDN Streams ]
```

### Attack Vectors & Mitigations

| Threat Vector | Potential Impact | Architecture Mitigation | Verification Evidence |
| :--- | :--- | :--- | :--- |
| **Insecure Direct Object Reference (IDOR)** | User A reads/edits User B's playlists or history | PostgreSQL Row Level Security (RLS) on all 15 tables (`auth.uid() = user_id`) | `backend_comprehensive_test.mjs` Test #4 passed |
| **Server/Client Request Forgery (SSRF)** | Localhost or cloud metadata extraction (`169.254.169.254`) | Strict `SsrfProtection` parser rejecting private IPv4/IPv6, internal hostnames, and non-HTTP schemes | `iptv_comprehensive_test.mjs` Test #4 passed |
| **Token / Credential Leakage** | Provider credentials or JWTs logged in logs or diagnostics | Redacting Logger and `StreamDiagnosticsService` auto-mask tokens, user-info, and password parameters | `player_engine_test.mjs` Test #1 passed |
| **Cleartext Transmission** | Network eavesdropping on public Wi-Fi | Android Network Security Config enforces `cleartextTrafficPermitted="false"`, macOS/iOS App Transport Security | `android/app/src/main/res/xml/network_security_config.xml` |
| **SQL Injection** | Database compromise or unauthorized exfiltration | 100% Parameterized queries via Supabase PostgREST client; zero raw string concatenation | Codebase Static AST Audit |
| **XML External Entity (XXE)** | File system disclosure via XMLTV EPG ingestion | XMLTV parser uses safe SAX/DOM streaming without resolving external entity references | `iptv_comprehensive_test.mjs` Test #5 passed |
| **Brute-Force & Session Hijacking** | Account takeover | Supabase Auth rate limiting, PKCE token exchange, and encrypted secure storage | `lib/features/auth/repositories/auth_repository.dart` |

---

## 3. Database Security & Row Level Security (RLS)

All 15 version-controlled PostgreSQL tables strictly enforce Row Level Security:

1. `profiles`: `id = auth.uid()`
2. `devices`: `user_id = auth.uid()`
3. `user_settings`: `user_id = auth.uid()`
4. `playlists`: `user_id = auth.uid()`
5. `channels`: Belongs to playlist owned by `auth.uid()`
6. `favorites`: `user_id = auth.uid()`
7. `watch_history`: `user_id = auth.uid()`
8. `watch_progress`: `user_id = auth.uid()`
9. `movie_metadata`: Public licensed read, admin-only write
10. `epg_programs`: Public read, system/admin write
11. `saved_youtube_links`: `user_id = auth.uid()`
12. `sync_jobs`: `user_id = auth.uid()`
13. `app_announcements`: Public read, admin-only write
14. `bug_reports`: Insert by authenticated user, read by owner & admin
15. `admin_audit_logs`: Service-role / Admin role access only

### Verified Isolation Principle
In `test/backend_comprehensive_test.mjs`, tests simulate concurrent access by `User_Alice` and `User_Bob`. Requests by `User_Alice` attempting to query or modify records with `user_id = 'User_Bob'` return 0 rows or throw an HTTP 403 Forbidden.

---

## 4. SSRF & Stream URL Validation

IPTV players inherently interact with user-supplied URLs. To protect the host machine and local network, `lib/core/security/ssrf_protection.dart` applies deterministic validation before any HTTP request:

```dart
// Blocked Subnets
127.0.0.0/8       // IPv4 Loopback
10.0.0.0/8        // RFC 1918 Private Class A
172.16.0.0/12     // RFC 1918 Private Class B
192.168.0.0/16    // RFC 1918 Private Class C
169.254.0.0/16    // Link-Local / AWS/GCP/Azure Cloud Metadata
::1, fe80::, fc00:: // IPv6 Loopback & Unique Local

// Blocked Hostnames
localhost, metadata.google.internal, instance-data
```

Any URL targeting these hosts is instantly dropped with `SsrfValidationResult.unsafe(...)` before DNS lookup or socket creation.

---

## 5. Client-Side Secret Management

- **Public Anon Key**: The app only embeds the publishable client key (`sb_publishable_...`).
- **Service Role Key**: **Strictly forbidden** in the client repository or Flutter build artifacts. The service role key is retained exclusively in secure backend server environments.
- **Sensitive Storage**: User tokens and cryptographic session secrets are persisted via `flutter_secure_storage` using:
  - Android: EncryptedSharedPreferences backed by Android Keystore.
  - Windows: Data Protection API (DPAPI).
  - macOS/iOS: Keychain Services with kSecAttrAccessibleAfterFirstUnlock.
  - Linux: Secret Service API / libsecret.

---

## 6. Vulnerability Disclosure & Bug Reporting

Security researchers and users can report security vulnerabilities via:
1. In-app Bug & Security Report form (`/support`)
2. Encrypted email: `security@saifuliptv.internal`
3. Response SLA: Critical vulnerabilities reviewed within 24 hours.
