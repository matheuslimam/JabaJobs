class MemoryInfo {
  const MemoryInfo({
    required this.total,
    required this.used,
    required this.free,
    required this.available,
    required this.raw,
  });

  final String total;
  final String used;
  final String free;
  final String available;
  final String raw;
}

class DiskInfo {
  const DiskInfo({
    required this.filesystem,
    required this.size,
    required this.used,
    required this.available,
    required this.usePercent,
    required this.mountPoint,
    required this.raw,
  });

  final String filesystem;
  final String size;
  final String used;
  final String available;
  final String usePercent;
  final String mountPoint;
  final String raw;
}

class ServerHealth {
  const ServerHealth({
    required this.uptime,
    required this.loadAverage,
    required this.memory,
    required this.homeDisk,
    required this.refreshedAt,
  });

  final String uptime;
  final String loadAverage;
  final MemoryInfo memory;
  final DiskInfo homeDisk;
  final DateTime refreshedAt;
}
