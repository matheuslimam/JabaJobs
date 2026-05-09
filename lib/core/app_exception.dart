class AppException implements Exception {
  const AppException(this.message, {this.details});

  final String message;
  final String? details;

  @override
  String toString() {
    if (details == null || details!.trim().isEmpty) {
      return message;
    }
    return '$message\n$details';
  }
}

class SshConnectionException extends AppException {
  const SshConnectionException(super.message, {super.details});
}

class RemoteCommandException extends AppException {
  const RemoteCommandException(super.message, {super.details});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.details});
}
