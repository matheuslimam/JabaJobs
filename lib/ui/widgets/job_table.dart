import 'package:flutter/material.dart';

import '../../models/job_info.dart';

class JobTable extends StatelessWidget {
  const JobTable({
    super.key,
    required this.jobs,
    this.selectedJobId,
    this.onSelected,
    this.emptyText = 'Nenhum job encontrado.',
  });

  final List<JobInfo> jobs;
  final String? selectedJobId;
  final ValueChanged<String>? onSelected;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(emptyText, style: const TextStyle(color: Colors.white60)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        headingTextStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
        ),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columns: const [
          DataColumn(label: Text('Job ID')),
          DataColumn(label: Text('Partição')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Tempo')),
          DataColumn(label: Text('Nós')),
          DataColumn(label: Text('Nó / motivo')),
        ],
        rows: jobs
            .map((job) {
              final selected = selectedJobId == job.jobId;
              return DataRow(
                selected: selected,
                onSelectChanged: (_) => onSelected?.call(job.jobId),
                cells: [
                  DataCell(Text(job.jobId)),
                  DataCell(Text(job.partition)),
                  DataCell(_StatePill(state: job.state)),
                  DataCell(Text(job.time)),
                  DataCell(Text(job.nodes)),
                  DataCell(Text(job.nodeList, overflow: TextOverflow.ellipsis)),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final normalized = state.toUpperCase();
    final color = normalized.startsWith('R')
        ? Colors.greenAccent
        : normalized.startsWith('PD')
        ? Colors.amberAccent
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        state,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
