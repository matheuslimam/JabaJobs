class NodeInfo {
  const NodeInfo({
    required this.nodeName,
    required this.state,
    required this.partition,
    required this.cpus,
    required this.memory,
    required this.gres,
    required this.raw,
  });

  final String nodeName;
  final String state;
  final String partition;
  final String cpus;
  final String memory;
  final String gres;
  final String raw;
}

class SinfoRow {
  const SinfoRow({
    required this.partition,
    required this.availability,
    required this.timeLimit,
    required this.nodes,
    required this.state,
    required this.nodeList,
    required this.raw,
  });

  final String partition;
  final String availability;
  final String timeLimit;
  final String nodes;
  final String state;
  final String nodeList;
  final String raw;
}
