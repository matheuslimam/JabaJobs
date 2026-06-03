class JobInfo {
  const JobInfo({
    required this.jobId,
    required this.partition,
    required this.name,
    required this.user,
    required this.state,
    required this.time,
    required this.nodes,
    required this.nodeList,
    required this.raw,
  });

  final String jobId;
  final String partition;
  final String name;
  final String user;
  final String state;
  final String time;
  final String nodes;
  final String nodeList;
  final String raw;

  bool get isRunning => state.toUpperCase().startsWith('R');
  bool get isPending => state.toUpperCase().startsWith('PD');
  bool get isActive => isRunning || isPending;
  bool get hasErrorState {
    final normalized = state.toUpperCase().replaceAll(' ', '_');
    return normalized.startsWith('FAIL') ||
        normalized.startsWith('CANCEL') ||
        normalized.startsWith('TIMEOUT') ||
        normalized.startsWith('OUT_OF_MEMORY') ||
        normalized.startsWith('OOM') ||
        normalized.startsWith('NODE_FAIL') ||
        normalized.startsWith('PREEMPT');
  }
}
