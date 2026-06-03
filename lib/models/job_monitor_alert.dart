enum JobMonitorAlertType { stopped, error }

class JobMonitorAlert {
  const JobMonitorAlert({
    required this.id,
    required this.type,
    required this.jobId,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final JobMonitorAlertType type;
  final String jobId;
  final String title;
  final String message;
  final DateTime createdAt;

  bool get isError => type == JobMonitorAlertType.error;
}

class JobMonitorSignals {
  JobMonitorSignals._();

  static final List<RegExp> _errorPatterns = [
    RegExp(
      r'\b(traceback|exception|error|failed|failure|fatal)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(segmentation fault|core dumped|out of memory|oom-kill|cuda error)\b',
      caseSensitive: false,
    ),
    RegExp(r'\b(falha|erro)\b', caseSensitive: false),
  ];

  static String? findErrorLine(String logText) {
    final lines = logText
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final line in lines.reversed) {
      final lower = line.toLowerCase();
      if (_looksLikeNonErrorContext(lower)) {
        continue;
      }
      if (_errorPatterns.any((pattern) => pattern.hasMatch(line))) {
        return line;
      }
    }
    return null;
  }

  static bool _looksLikeNonErrorContext(String lower) {
    return lower.contains('no error') ||
        lower.contains('sem erro') ||
        lower.contains('error rate') ||
        lower.contains('erro medio') ||
        lower.contains('validation error');
  }
}
