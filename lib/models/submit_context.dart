class SubmitContext {
  const SubmitContext({
    required this.workingDirectory,
    required this.condaPrefix,
    required this.condaVersion,
    required this.helperStatus,
  });

  final String workingDirectory;
  final String condaPrefix;
  final String condaVersion;
  final String helperStatus;

  bool get hasActiveConda => condaPrefix.trim().isNotEmpty;
}
