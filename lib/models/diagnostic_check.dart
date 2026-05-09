class DiagnosticCheck {
  const DiagnosticCheck({
    required this.title,
    required this.command,
    required this.output,
    required this.succeeded,
  });

  final String title;
  final String command;
  final String output;
  final bool succeeded;
}
