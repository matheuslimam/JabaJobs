class JobProgress {
  const JobProgress({
    required this.percent,
    required this.label,
    required this.rawLine,
    this.current,
    this.total,
    this.elapsed,
    this.remaining,
    this.rate,
  });

  final double percent;
  final String label;
  final String rawLine;
  final int? current;
  final int? total;
  final String? elapsed;
  final String? remaining;
  final String? rate;

  bool get hasProgress => percent >= 0;

  static JobProgress? fromLog(String text) {
    final normalized = text.replaceAll('\r', '\n');
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final line in lines.reversed) {
      final parsed = _parseLine(line);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  static JobProgress? _parseLine(String line) {
    final percentMatch = RegExp(r'(\d{1,3}(?:\.\d+)?)%').firstMatch(line);
    final countMatch = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(line);

    double? percent;
    int? current;
    int? total;

    if (percentMatch != null) {
      percent = double.tryParse(percentMatch.group(1)!);
    }

    if (countMatch != null) {
      current = int.tryParse(countMatch.group(1)!);
      total = int.tryParse(countMatch.group(2)!);
      if (percent == null && current != null && total != null && total > 0) {
        percent = (current / total) * 100;
      }
    }

    if (percent == null) {
      return null;
    }

    final timing = RegExp(
      r'\[([^\]<]+)<([^\],]+),?\s*([^\]]*)\]',
    ).firstMatch(line);

    final safePercent = percent.clamp(0, 100).toDouble();
    return JobProgress(
      percent: safePercent,
      label:
          '${safePercent.toStringAsFixed(safePercent == safePercent.roundToDouble() ? 0 : 1)}%',
      rawLine: line,
      current: current,
      total: total,
      elapsed: timing?.group(1)?.trim(),
      remaining: timing?.group(2)?.trim(),
      rate: timing?.group(3)?.trim(),
    );
  }
}
