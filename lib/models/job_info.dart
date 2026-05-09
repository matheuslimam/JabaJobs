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
}
