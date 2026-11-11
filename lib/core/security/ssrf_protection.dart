import 'dart:io';

/// Result of SSRF safety validation
class SsrfValidationResult {
  final bool isSafe;
  final String? rejectionReason;
  final String? sanitizedUrl;

  const SsrfValidationResult({
    required this.isSafe,
    this.rejectionReason,
    this.sanitizedUrl,
  });

  factory SsrfValidationResult.safe(String sanitizedUrl) => SsrfValidationResult(
        isSafe: true,
        sanitizedUrl: sanitizedUrl,
      );

  factory SsrfValidationResult.unsafe(String reason) => SsrfValidationResult(
        isSafe: false,
        rejectionReason: reason,
      );
}

/// SSRF (Server/Client-Side Request Forgery) and Network Security Guard
class SsrfProtection {
  // Blocked private and loopback IPv4 subnets
  static const List<String> _blockedSubnets = [
    '127.', // 127.0.0.0/8 Loopback
    '10.', // 10.0.0.0/8 Private
    '192.168.', // 192.168.0.0/16 Private
    '169.254.', // 169.254.0.0/16 Link-local / Cloud Metadata (169.254.169.254)
    '0.0.0.0', // Any local
  ];

  // Blocked hostnames
  static const Set<String> _blockedHostnames = {
    'localhost',
    'metadata.google.internal',
    'instance-data',
    '169.254.169.254',
  };

  /// Validate whether a remote URL is safe to fetch
  static SsrfValidationResult validateUrl(String rawUrl) {
    if (rawUrl.trim().isEmpty) {
      return SsrfValidationResult.unsafe('URL cannot be empty');
    }

    final trimmed = rawUrl.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri == null || !uri.hasScheme) {
      return SsrfValidationResult.unsafe('Invalid URL format');
    }

    // Only allow HTTP and HTTPS
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return SsrfValidationResult.unsafe('Disallowed protocol: $scheme. Only HTTP and HTTPS are permitted');
    }

    // Validate host
    final host = uri.host.toLowerCase().trim();
    if (host.isEmpty) {
      return SsrfValidationResult.unsafe('Missing hostname');
    }

    // Check blocked hostnames
    if (_blockedHostnames.contains(host)) {
      return SsrfValidationResult.unsafe('Forbidden hostname: $host (Localhost / Metadata access blocked)');
    }

    // Check Class B private range 172.16.0.0 - 172.31.255.255
    if (host.startsWith('172.')) {
      final parts = host.split('.');
      if (parts.length >= 2) {
        final secondOctet = int.tryParse(parts[1]);
        if (secondOctet != null && secondOctet >= 16 && secondOctet <= 31) {
          return SsrfValidationResult.unsafe('Forbidden private IP address in 172.16.0.0/12 range');
        }
      }
    }

    // Check standard blocked subnets
    for (final subnet in _blockedSubnets) {
      if (host.startsWith(subnet)) {
        return SsrfValidationResult.unsafe('Forbidden private or loopback IP address: $host');
      }
    }

    // IPv6 checks
    if (host == '::1' || host == '[::1]' || host.startsWith('fe80:') || host.startsWith('fc00:')) {
      return SsrfValidationResult.unsafe('Forbidden IPv6 loopback or private address: $host');
    }

    // Return safe with sanitized credentials
    return SsrfValidationResult.safe(sanitizeUrl(trimmed));
  }

  /// Sanitizes sensitive user info and query parameters from URL for display/logs
  static String sanitizeUrl(String rawUrl) {
    try {
      final parsed = Uri.parse(rawUrl);
      var clean = parsed;
      if (parsed.userInfo.isNotEmpty) {
        clean = parsed.replace(userInfo: '***:***');
      }

      var result = clean.toString();

      // Mask Xtream Codes path credentials /live/user/pass/id or /movie/user/pass/id
      final xtreamRegex = RegExp(r'(/(?:live|movie|series)/)([^/]+)/([^/]+)/([0-9a-zA-Z._]+)');
      result = result.replaceAllMapped(xtreamRegex, (match) {
        return '${match.group(1)}****/****/${match.group(4)}';
      });

      // Mask sensitive query parameters
      final queryRegex = RegExp(r'([?&])(token|key|password|pass|auth|hash|secret)=([^&]+)', caseSensitive: false);
      result = result.replaceAllMapped(queryRegex, (match) {
        return '${match.group(1)}${match.group(2)}=[REDACTED]';
      });

      return result;
    } catch (_) {
      return '[Invalid URI]';
    }
  }
}

