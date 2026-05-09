class GpuInfo {
  const GpuInfo({
    required this.loginNodeOutput,
    required this.a4000Output,
    required this.loginNodeSummary,
    required this.a4000Summary,
    required this.refreshedAt,
  });

  final String loginNodeOutput;
  final String a4000Output;
  final String loginNodeSummary;
  final String a4000Summary;
  final DateTime refreshedAt;
}
