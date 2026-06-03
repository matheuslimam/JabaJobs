import 'package:flutter/material.dart';

import '../../models/job_info.dart';
import '../../models/job_monitor_alert.dart';
import '../../state/cluster_app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/jaba_progress_card.dart';
import '../widgets/terminal_output.dart';

class MobileLogsPage extends StatelessWidget {
  const MobileLogsPage({super.key, required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedJob;
    final selectedId = state.selectedJobId;
    final compactHeight = MediaQuery.of(context).size.height < 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Monitor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _MonitorStatePill(state: state),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          selectedId == null
              ? 'Nenhum job selecionado'
              : 'slurm-$selectedId.out',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 14),
        GlassCard(
          title: 'Jobs',
          trailing: IconButton(
            tooltip: 'Atualizar jobs',
            onPressed: state.refreshMyJobs,
            icon: const Icon(Icons.refresh),
          ),
          child: _MobileJobSelector(
            jobs: state.myJobs,
            selectedJobId: selectedId,
            onSelected: state.selectJob,
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          title: selected == null ? 'Log do job' : 'Job ${selected.jobId}',
          subtitle: selected == null
              ? 'Selecione um job.'
              : '${selected.state} | ${selected.time} | ${selected.partition}',
          trailing: Wrap(
            spacing: 6,
            children: [
              IconButton(
                tooltip: 'Status',
                onPressed: state.loadSelectedJobStatus,
                icon: const Icon(Icons.info_outline),
              ),
              IconButton(
                tooltip: 'Atualizar log',
                onPressed: state.loadSelectedJobLog,
                icon: const Icon(Icons.article_outlined),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MobileSwitchRow(
                icon: Icons.sync_alt_outlined,
                label: 'Seguir log',
                value: state.followLog,
                onChanged: state.setFollowLog,
              ),
              const SizedBox(height: 10),
              _MobileSwitchRow(
                icon: Icons.notifications_active_outlined,
                label: 'Notificar parada/erro',
                value: state.notifyOnSelectedJobEvent,
                onChanged: state.setNotifyOnSelectedJobEvent,
              ),
              if (state.jobMonitorLastCheckedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Checado ${_formatClock(state.jobMonitorLastCheckedAt!)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
              if (state.jobMonitorAlert != null) ...[
                const SizedBox(height: 12),
                _MonitorAlertBox(alert: state.jobMonitorAlert!),
              ],
              if (state.jobStatus.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                TerminalOutput(text: state.jobStatus, minHeight: 96),
              ],
              const SizedBox(height: 12),
              JabaProgressCard(logText: '${state.jobStatus}\n${state.jobLog}'),
              const SizedBox(height: 12),
              TerminalOutput(
                text: state.jobLog,
                minHeight: compactHeight ? 320 : 430,
              ),
            ],
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  static String _formatClock(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _MobileJobSelector extends StatelessWidget {
  const _MobileJobSelector({
    required this.jobs,
    required this.selectedJobId,
    required this.onSelected,
  });

  final List<JobInfo> jobs;
  final String? selectedJobId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Nenhum job encontrado.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final job = jobs[index];
          final selected = selectedJobId == job.jobId;
          return _MobileJobTile(
            job: job,
            selected: selected,
            onTap: () => onSelected(job.jobId),
          );
        },
      ),
    );
  }
}

class _MobileJobTile extends StatelessWidget {
  const _MobileJobTile({
    required this.job,
    required this.selected,
    required this.onTap,
  });

  final JobInfo job;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 218,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : const Color(0xFF101720),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.55)
                  : const Color(0xFF303844),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.jobId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _JobStatePill(state: job.state),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Text(
                '${job.partition} | ${job.time}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileSwitchRow extends StatelessWidget {
  const _MobileSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF101720),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF303844)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MonitorAlertBox extends StatelessWidget {
  const _MonitorAlertBox({required this.alert});

  final JobMonitorAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = alert.isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alert.isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(alert.message, style: TextStyle(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitorStatePill extends StatelessWidget {
  const _MonitorStatePill({required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    final enabled = state.notifyOnSelectedJobEvent;
    final color = enabled
        ? Theme.of(context).colorScheme.secondary
        : Colors.white54;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            enabled ? 'Ativo' : 'Inativo',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _JobStatePill extends StatelessWidget {
  const _JobStatePill({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final normalized = state.toUpperCase();
    final color = normalized.startsWith('R')
        ? Colors.greenAccent
        : normalized.startsWith('PD')
        ? Colors.amberAccent
        : normalized.startsWith('FAIL') || normalized.startsWith('CANCEL')
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(maxWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        state,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
