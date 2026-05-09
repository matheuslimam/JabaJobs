import '../models/job_info.dart';
import '../models/node_info.dart';
import '../models/server_health.dart';

class ClusterParser {
  List<String> parseGroups(String raw) {
    return raw
        .split(RegExp(r'\s+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  MemoryInfo parseMemory(String raw) {
    final lines = raw.split('\n');
    final memLine = lines.firstWhere(
      (line) => line.trimLeft().toLowerCase().startsWith('mem'),
      orElse: () => '',
    );
    final parts = memLine.trim().split(RegExp(r'\s+'));
    return MemoryInfo(
      total: parts.length > 1 ? parts[1] : '-',
      used: parts.length > 2 ? parts[2] : '-',
      free: parts.length > 3 ? parts[3] : '-',
      available: parts.length > 6 ? parts[6] : '-',
      raw: raw.trimRight(),
    );
  }

  DiskInfo parseDisk(String raw) {
    final dataLines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final line = dataLines.length > 1 ? dataLines[1] : '';
    final parts = line.split(RegExp(r'\s+'));
    return DiskInfo(
      filesystem: parts.isNotEmpty ? parts[0] : '-',
      size: parts.length > 1 ? parts[1] : '-',
      used: parts.length > 2 ? parts[2] : '-',
      available: parts.length > 3 ? parts[3] : '-',
      usePercent: parts.length > 4 ? parts[4] : '-',
      mountPoint: parts.length > 5 ? parts.sublist(5).join(' ') : '/home',
      raw: raw.trimRight(),
    );
  }

  DiskInfo parseTotalDisk(String raw) {
    final dataLines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final totalLine = dataLines.lastWhere(
      (line) => line.startsWith('total '),
      orElse: () => dataLines.length > 1 ? dataLines.last : '',
    );
    final parts = totalLine.split(RegExp(r'\s+'));
    return DiskInfo(
      filesystem: parts.isNotEmpty ? parts[0] : 'total',
      size: parts.length > 1 ? parts[1] : '-',
      used: parts.length > 2 ? parts[2] : '-',
      available: parts.length > 3 ? parts[3] : '-',
      usePercent: parts.length > 4 ? parts[4] : '-',
      mountPoint: parts.length > 5 ? parts.sublist(5).join(' ') : 'total',
      raw: raw.trimRight(),
    );
  }

  String parseLoadAverage(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      return '${parts[0]} / ${parts[1]} / ${parts[2]}';
    }
    return raw.trim().isEmpty ? '-' : raw.trim();
  }

  List<JobInfo> parseJobs(String raw) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !line.toUpperCase().startsWith('JOBID'))
        .toList();

    return lines
        .map(_parseJobLine)
        .whereType<JobInfo>()
        .toList(growable: false);
  }

  JobInfo? _parseJobLine(String line) {
    if (line.contains('|')) {
      final parts = line.split('|');
      if (parts.length >= 8) {
        return JobInfo(
          jobId: parts[0].trim(),
          partition: parts[1].trim(),
          name: parts[2].trim(),
          user: parts[3].trim(),
          state: parts[4].trim(),
          time: parts[5].trim(),
          nodes: parts[6].trim(),
          nodeList: parts.sublist(7).join('|').trim(),
          raw: line,
        );
      }
    }

    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 5 || !RegExp(r'^\d+').hasMatch(parts.first)) {
      return null;
    }

    return JobInfo(
      jobId: parts[0],
      partition: parts.length > 1 ? parts[1] : '-',
      name: parts.length > 2 ? parts[2] : '-',
      user: parts.length > 3 ? parts[3] : '-',
      state: parts.length > 4 ? parts[4] : '-',
      time: parts.length > 5 ? parts[5] : '-',
      nodes: parts.length > 6 ? parts[6] : '-',
      nodeList: parts.length > 7 ? parts.sublist(7).join(' ') : '-',
      raw: line,
    );
  }

  List<SinfoRow> parseSinfo(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final parts = line.split('|');
          if (parts.length >= 6) {
            return SinfoRow(
              partition: parts[0].trim(),
              availability: parts[1].trim(),
              timeLimit: parts[2].trim(),
              nodes: parts[3].trim(),
              state: parts[4].trim(),
              nodeList: parts.sublist(5).join('|').trim(),
              raw: line,
            );
          }
          final fallback = line.split(RegExp(r'\s+'));
          return SinfoRow(
            partition: fallback.isNotEmpty ? fallback[0] : '-',
            availability: fallback.length > 1 ? fallback[1] : '-',
            timeLimit: fallback.length > 2 ? fallback[2] : '-',
            nodes: fallback.length > 3 ? fallback[3] : '-',
            state: fallback.length > 4 ? fallback[4] : '-',
            nodeList: fallback.length > 5 ? fallback.sublist(5).join(' ') : '-',
            raw: line,
          );
        })
        .toList(growable: false);
  }

  List<NodeInfo> parseNodes(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final parts = line.split('|');
          return NodeInfo(
            nodeName: parts.isNotEmpty ? parts[0].trim() : '-',
            state: parts.length > 1 ? parts[1].trim() : '-',
            partition: parts.length > 2 ? parts[2].trim() : '-',
            cpus: parts.length > 3 ? parts[3].trim() : '-',
            memory: parts.length > 4 ? parts[4].trim() : '-',
            gres: parts.length > 5 ? parts.sublist(5).join('|').trim() : '-',
            raw: line,
          );
        })
        .toList(growable: false);
  }

  String? parseSubmittedJobId(String raw) {
    final match = RegExp(
      r'(?:Submitted batch job|job(?:\s+id)?|jobid)[:\s#]*([0-9]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match != null) {
      return match.group(1);
    }
    return RegExp(r'\b[0-9]{2,}\b').firstMatch(raw)?.group(0);
  }
}
