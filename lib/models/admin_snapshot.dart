import 'diagnostic_check.dart';
import 'gpu_info.dart';
import 'job_info.dart';
import 'machine_resource.dart';
import 'node_info.dart';

class AdminSnapshot {
  const AdminSnapshot({
    required this.slurmPing,
    required this.sinfoRows,
    required this.nodeRows,
    required this.allJobs,
    required this.gpuInfo,
    required this.machineResources,
    required this.diagnostics,
    required this.refreshedAt,
  });

  final String slurmPing;
  final List<SinfoRow> sinfoRows;
  final List<NodeInfo> nodeRows;
  final List<JobInfo> allJobs;
  final GpuInfo gpuInfo;
  final List<MachineResource> machineResources;
  final List<DiagnosticCheck> diagnostics;
  final DateTime refreshedAt;
}
