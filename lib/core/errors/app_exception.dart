sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AuthException extends AppException {
  const AuthException(super.message);
}

final class ConfigurationException extends AppException {
  const ConfigurationException(super.message);
}