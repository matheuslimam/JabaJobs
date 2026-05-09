class RemoteCommandResult {
  const RemoteCommandResult({
    required this.command,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  final String command;
  final String stdout;
  final String stderr;
  final int? exitCode;

  bool get succeeded => exitCode == null || exitCode == 0;

  String get combinedOutput {
    final parts = [
      if (stdout.trim().isNotEmpty) stdout.trimRight(),
      if (stderr.trim().isNotEmpty) stderr.trimRight(),
    ];
    return parts.join('\n');
  }
}
