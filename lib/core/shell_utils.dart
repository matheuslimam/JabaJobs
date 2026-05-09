import 'app_exception.dart';

String shellQuote(String value) {
  return "'${value.replaceAll("'", "'\"'\"'")}'";
}

String sanitizeJobId(String value) {
  final trimmed = value.trim();
  final validJobId = RegExp(r'^[A-Za-z0-9_.-]+$');
  if (trimmed.isEmpty || !validJobId.hasMatch(trimmed)) {
    throw const ValidationException('Job ID inválido.');
  }
  return trimmed;
}

String sanitizeSubmitCommand(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw const ValidationException('Informe um comando para submeter.');
  }
  if (trimmed.length > 500) {
    throw const ValidationException('O comando está longo demais para o MVP.');
  }
  if (trimmed.contains('\n') ||
      trimmed.contains('\r') ||
      trimmed.contains('\u0000')) {
    throw const ValidationException('Use um comando de uma única linha.');
  }
  return trimmed;
}

String sanitizeLinuxUsername(String value) {
  final trimmed = value.trim();
  if (!RegExp(r'^[a-z_][a-z0-9_-]*[$]?$').hasMatch(trimmed)) {
    throw const ValidationException('Nome de usuário Linux inválido.');
  }
  return trimmed;
}

String sanitizeRemoteDirectory(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '~';
  }
  if (trimmed.contains('\n') ||
      trimmed.contains('\r') ||
      trimmed.contains('\u0000')) {
    throw const ValidationException('Diretório remoto inválido.');
  }
  return trimmed;
}

String sanitizeCondaEnvironment(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (!RegExp(r'^[A-Za-z0-9_.\/~:-]+$').hasMatch(trimmed)) {
    throw const ValidationException('Ambiente Conda inválido.');
  }
  return trimmed;
}
