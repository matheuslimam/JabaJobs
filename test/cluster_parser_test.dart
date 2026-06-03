import 'package:cluster_glass/services/cluster_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses pipe formatted squeue output', () {
    final parser = ClusterParser();

    final jobs = parser.parseJobs(
      '123|a4000|train|alice|RUNNING|00:12:30|1|gpu-a4000\n',
    );

    expect(jobs, hasLength(1));
    expect(jobs.first.jobId, '123');
    expect(jobs.first.partition, 'a4000');
    expect(jobs.first.state, 'RUNNING');
    expect(jobs.first.isActive, isTrue);
  });

  test('marks failed Slurm states as monitor errors', () {
    final parser = ClusterParser();

    final jobs = parser.parseJobs(
      '124|a4000|train|alice|FAILED|00:12:30|1|gpu-a4000\n',
    );

    expect(jobs.single.hasErrorState, isTrue);
    expect(jobs.single.isActive, isFalse);
  });

  test('parses free and df summaries without failing on raw text', () {
    final parser = ClusterParser();

    final memory = parser.parseMemory(
      '               total        used        free      shared  buff/cache   available\n'
      'Mem:            31Gi        12Gi       3.0Gi       100Mi        16Gi        18Gi\n',
    );
    final disk = parser.parseDisk(
      'Filesystem      Size  Used Avail Use% Mounted on\n'
      '/dev/sda2       900G  400G  500G  45% /home\n',
    );

    expect(memory.total, '31Gi');
    expect(memory.available, '18Gi');
    expect(disk.usePercent, '45%');
  });

  test('parses localized free memory labels', () {
    final parser = ClusterParser();

    final memory = parser.parseMemory(
      '               total        used        free      shared  buff/cache   available\n'
      'Mem.:           15Gi       6.0Gi       1.0Gi       100Mi       8.0Gi       9.0Gi\n',
    );

    expect(memory.total, '15Gi');
    expect(memory.used, '6.0Gi');
    expect(memory.available, '9.0Gi');
  });

  test('parses df total disk line', () {
    final parser = ClusterParser();

    final disk = parser.parseTotalDisk(
      'Filesystem      Size  Used Avail Use% Mounted on\n'
      '/dev/sda2       900G  400G  500G  45% /\n'
      '/dev/sdb1       600G  100G  500G  17% /data\n'
      'total           1.5T  500G  1.0T  34% -\n',
    );

    expect(disk.filesystem, 'total');
    expect(disk.size, '1.5T');
    expect(disk.usePercent, '34%');
  });
}
