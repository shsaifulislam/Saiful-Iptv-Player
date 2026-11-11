# Technical Debt and Prioritized Issue Queue

**Audit date:** 2026-11-11  
**Priority convention:** P0 blocks a credible build/release baseline; P1 is required before user data/content is introduced; P2 is feature delivery; P3 is cleanup/scope alignment. Risk values are LOW, MEDIUM, HIGH, CRITICAL. No CRITICAL vulnerability was confirmed by this static-only audit; this is not a security clearance.

## P0 — Establish a Verifiable Baseline

### AUD-001 — Resolve missing source/generated references
- **Severity:** HIGH
- **Description:** Eleven model files reference 22 absent generated part files. Auth references absent `result.dart`, `app_exception.dart`, `app_logger.dart`, and generated `auth_state.freezed.dart`.
- **Root cause:** Code generation and shared core implementations are absent or omitted from the workspace.
- **Proposed fix:** Confirm intended source ownership; implement/restore the core contracts and run the pinned code generator. Avoid hand-editing generated output.
- **Dependencies:** Flutter/Dart toolchain and dependency resolution.
- **Acceptance criteria:** `flutter pub get`, `dart run build_runner build`, `flutter analyze`, all tests and at least one target debug build complete with recorded output.

### AUD-002 — Create an executable application shell
- **Severity:** HIGH
- **Description:** App root displays a loading placeholder; route names are constants only; no screen/router is connected.
- **Root cause:** UI/navigation scaffolding has not been implemented.
- **Proposed fix:** Add a minimal feature-first shell, real router, loading/error/empty states, and a reachable first-run/home flow.
- **Dependencies:** AUD-001; product MVP/platform decision.
- **Acceptance criteria:** Widget tests verify initial route and navigation; Android debug build launches to a non-placeholder screen.

### AUD-003 — Add test and CI evidence
- **Severity:** HIGH
- **Description:** `test/` and `integration_test/` are empty; no CI configuration or successful diagnostics are evidenced.
- **Root cause:** Verification gates were not established.
- **Proposed fix:** Add focused unit/widget tests and CI steps for dependency resolution, analyze, tests and target build.
- **Dependencies:** AUD-001; SDK/toolchain pinned.
- **Acceptance criteria:** CI records reproducible passing commands for every merged change; feature claims map to tests/device evidence.

## P1 — Protect Data and Define Local-First Contracts

### SEC-001 — Define secret/environment handling
- **Severity:** HIGH
- **Description:** `.env` is bundled as an asset if present; `.gitignore` is absent; client config exposes environment getters.
- **Root cause:** Development configuration and client-safe versus private values are not distinguished.
- **Proposed fix:** Add explicit client-safe configuration policy, ignore rules and secret scanning; keep privileged keys server-side; validate Supabase authorization independently of anon key secrecy.
- **Dependencies:** Security review and deployment/config ownership.
- **Acceptance criteria:** No private credential in source, assets or release bundle; CI blocks known secret patterns; startup works with documented safe config.

### SEC-002 — Secure playlist/provider credentials and backend access
- **Severity:** HIGH
- **Description:** Playlist model carries username/password; no secure persistence or Supabase schema/RLS evidence exists.
- **Root cause:** Credential lifecycle, data ownership, local encryption and cloud synchronization rules are undefined.
- **Proposed fix:** Threat-model and approve credential policy; use OS-backed secure storage; exclude secrets from logs/analytics/cloud sync; create default-deny RLS and isolation tests.
- **Dependencies:** Explicit approval for HIGH security remediation; selected local DB and backend schema.
- **Acceptance criteria:** Tests prove credentials are protected/redacted/deleted as specified and users cannot read/write another user's records; migration/RLS tests run in CI.

### AUD-004 — Select and implement local-first persistence
- **Severity:** HIGH
- **Description:** Hive and Isar are both declared; only Hive initialization exists. No repository/local adapter/migration/outbox exists.
- **Root cause:** Persistence choice, ownership boundaries and schema migration strategy were not decided.
- **Proposed fix:** Select a primary store based on query/offline needs, define repository interfaces and migrations, add transactional outbox and conflict policy.
- **Dependencies:** Data inventory, security classification, selected database.
- **Acceptance criteria:** App can add/read/update/delete authorized local playlist metadata offline; migration and restart tests pass; sync retry/conflict behavior is deterministic.

## P2 — Product Implementation and Platform Proofs

### AUD-005 — Implement playback abstraction and lawful MVP flow
- **Severity:** HIGH
- **Description:** Player controller/engine files are empty and no player UI/adapter exists.
- **Root cause:** Playback package is listed as a dependency but no app-owned contract or stream flow exists.
- **Proposed fix:** Define lifecycle/track/error contracts, inject platform adapters, then implement an Android-first authorized test-stream flow.
- **Dependencies:** AUD-001, AUD-002, lawful content test source, platform capability matrix.
- **Acceptance criteria:** Tests cover play/pause/stop/error/dispose and track state; device test plays an explicitly authorized fixture; UI imports no concrete engine package.

### AUD-006 — Build feature workflows from the inventory
- **Severity:** HIGH
- **Description:** The 23 requested capabilities are mostly missing or represented only by models/constants.
- **Root cause:** No approved MVP scope or feature acceptance criteria.
- **Proposed fix:** Deliver vertical slices in the audited sequence; gate each by ownership/legal policy, tests and platform support.
- **Dependencies:** AUD-002, AUD-004, AUD-005; provider/API contracts.
- **Acceptance criteria:** Each inventory item has a linked issue, acceptance test and truthful supported-platform status; no feature is labeled complete by declaration alone.

### AUD-007 — Prove TV and smart-TV platform feasibility
- **Severity:** MEDIUM
- **Description:** Android TV is only represented by constants; Tizen/webOS are empty folders without adapters/build projects.
- **Root cause:** Platform integration strategy is assumed rather than tested.
- **Proposed fix:** Run separate Android TV, Tizen and webOS feasibility spikes; choose native bridges/embedders as needed and keep unsupported platforms disabled.
- **Dependencies:** Playback contract, device/vendor SDK access, provider licensing/DRM constraints.
- **Acceptance criteria:** Reproducible build and device test for remote navigation and authorized playback on each claimed platform; otherwise publish unsupported status.

### AUD-008 — Define Cloud Auth, sync and profiles
- **Severity:** MEDIUM
- **Description:** Auth wrapper exists in incomplete form; no schema, RLS, profile/device flow or sync engine exists.
- **Root cause:** Cloud contracts and conflict/identity lifecycle are missing.
- **Proposed fix:** Define auth lifecycle, profile/device limits, sync schema, idempotency, conflict resolution and offline logout behavior.
- **Dependencies:** AUD-001, SEC-002, AUD-004; Supabase project/policy ownership.
- **Acceptance criteria:** Integration tests cover sign-up/sign-in/refresh/sign-out, offline queueing, retry, conflict handling and cross-user isolation.

## P3 — Release Hygiene and Scope Alignment

### AUD-009 — Make dependency resolution reproducible
- **Severity:** MEDIUM
- **Description:** No `pubspec.lock`; caret constraints have not been resolved or audited; plugin support is unverified.
- **Root cause:** No pinned SDK/release dependency workflow.
- **Proposed fix:** Pin Flutter in CI, resolve/commit the application lockfile, scan dependency advisories/licenses and verify plugins per platform.
- **Dependencies:** Toolchain availability.
- **Acceptance criteria:** Lockfile is reviewed; outdated/advisory/license results are documented; upgrades are tested on supported targets.

### AUD-010 — Repair bootstrap/config failure handling
- **Severity:** MEDIUM
- **Description:** `.env` is absent but declared as an asset and loaded unconditionally; Supabase may be skipped while Auth provider assumes it exists; global async handler marks errors handled.
- **Root cause:** Startup and optional-service state are not modeled or tested.
- **Proposed fix:** Validate configuration at startup, represent unavailable cloud services explicitly, avoid constructing Auth without a client, and test recovery/error propagation.
- **Dependencies:** AUD-001, AUD-002, environment policy.
- **Acceptance criteria:** Cold-start tests pass with valid config, missing optional cloud config, and invalid config; failures produce actionable sanitized states rather than a blank/loading screen.

### AUD-011 — Align README and target claims with evidence
- **Severity:** LOW
- **Description:** README claims product features/platforms not implemented and lists architecture folders different from actual code. Current requirements exclude iOS/Web but README includes them.
- **Root cause:** Documentation is aspirational and not tied to verification.
- **Proposed fix:** Label roadmap vs implemented features; align target list and legal-content language with acceptance-tested capabilities.
- **Dependencies:** Product/platform decisions and feature gates.
- **Acceptance criteria:** README's support table matches release-tested platforms; every “supported” feature has verification evidence and lawful-source caveat.

## Approval Gate

AUD-001–AUD-011 are findings and proposed work only. This audit made no destructive or security-sensitive runtime changes. Obtain explicit approval before implementing HIGH/CRITICAL security remediation, data migrations, credential transformations, or other irreversible operations.
