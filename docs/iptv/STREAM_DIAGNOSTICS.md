# Saiful IPTV Player: Stream Diagnostics Specification

## 1. Overview and Architecture

Stream diagnostics allow users, network operators, and support engineers to pinpoint the root cause of stream stalls, playback errors, and network disconnects without guessing.

Source code implementation:
- Service: [`lib/features/iptv/services/stream_diagnostics_service.dart`](file:///d:/Saiful%20iptv%20player/lib/features/iptv/services/stream_diagnostics_service.dart)
- Model: `StreamHealthReport`
- UI Integration: Fullscreen Player Diagnostics Modal & Channel Details

---

## 2. Technical Diagnostics Metrics

| Metric | Source / Method | Range / Format | Description |
| :--- | :--- | :--- | :--- |
| **HTTP Status Code** | Probed via `HttpClient` | `200`, `401`, `403`, `404`, `500+` | Identifies server response status. |
| **Latency / TTFB** | Stopwatch measurement | Milliseconds (ms) | Time To First Byte for manifest delivery. |
| **HLS Manifest Validity** | Header verification | `Boolean` | Verifies presence of `#EXTM3U` and media sequence. |
| **Detected Resolution** | Manifest `RESOLUTION` tag | `1920x1080`, `3840x2160`, etc. | Target video pixel dimensions. |
| **Video Codec** | Manifest `CODECS` attribute | `avc1.64002a`, `hvc1.2.4.L153` | Encoded video compression format. |
| **Audio Codec** | Manifest `CODECS` attribute | `mp4a.40.2`, `ac-3`, `ec-3` | Audio track compression format. |
| **Error Code** | Diagnostic classification | `ERR_SSRF_BLOCKED`, `HTTP_403`, `ERR_TIMEOUT` | Machine-readable failure key. |
| **Recovery Suggestion** | Dynamic decision engine | String | Human-readable actionable advice. |

---

## 3. Error Classification & Recovery Rules

1. **`HTTP_401` / `HTTP_403` (Access Denied / Forbidden)**:
   - *Cause*: Provider subscription token or credentials have expired, or MAC address registration has lapsed.
   - *Suggested Action*: Re-authenticate your playlist subscription in Playlist Manager.
2. **`HTTP_404` (Channel Not Found)**:
   - *Cause*: The channel stream has been removed, renamed, or relocated by the upstream IPTV provider.
   - *Suggested Action*: Check with your provider for updated channel URLs or refresh the playlist.
3. **`ERR_TIMEOUT` (Connection Timeout)**:
   - *Cause*: Host server is unreachable or client device network dropped.
   - *Suggested Action*: Verify your internet connectivity or test stream server availability.
4. **`ERR_DNS_SOCKET` (Host Resolution Failure)**:
   - *Cause*: DNS lookup failed or server IP is blocked by ISP.
   - *Suggested Action*: Check device DNS configuration (e.g. 1.1.1.1 or 8.8.8.8) or verify provider host.
5. **`ERR_SSRF_BLOCKED` (Security Restriction)**:
   - *Cause*: The requested stream URL targets a private, loopback, or cloud metadata network address.
   - *Suggested Action*: Forbidden IP range or protocol. Only public HTTP/HTTPS streams are permitted.

---

## 4. Zero-Credential Leakage Guarantee

IPTV streams frequently embed sensitive credentials in URLs. Saiful IPTV Player enforces strict URL redaction before rendering or logging:

### 4.1 Xtream Codes Redaction
- Raw: `http://iptv.server:8080/live/customer_99/secret_password_42/12345.m3u8`
- Sanitized: `http://iptv.server:8080/live/****/****/12345.m3u8`

### 4.2 Query Parameter Redaction
- Raw: `https://stream.provider.com/feed.m3u8?token=a1b2c3d4e5&key=secret99`
- Sanitized: `https://stream.provider.com/feed.m3u8?token=[REDACTED]&key=[REDACTED]`

### 4.3 HTTP Basic Auth Redaction
- Raw: `http://admin:master_key@198.51.100.5:8000/stream.ts`
- Sanitized: `http://***:***@198.51.100.5:8000/stream.ts`

