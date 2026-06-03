import 'package:flutter/material.dart';

import '../../state/cluster_app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/jaba_progress_card.dart';
import '../widgets/terminal_output.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key, required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedJobId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logs',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          selected == null
              ? 'Selecione um job na aba Jobs.'
              : '~/logs/slurm-$selected.out',
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Status e log do job',
          subtitle:
              'Seguir usa tail estável; Watch roda o helper interativo sob demanda.',
          trailing: Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Seguir'),
                  Switch(value: state.followLog, onChanged: state.setFollowLog),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Notificar'),
                  Switch(
                    value: state.notifyOnSelectedJobEvent,
                    onChanged: state.setNotifyOnSelectedJobEvent,
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: state.loadSelectedJobStatus,
                icon: const Icon(Icons.info_outline),
                label: const Text('Status'),
              ),
              OutlinedButton.icon(
                onPressed: state.loadSelectedJobLog,
                icon: const Icon(Icons.article_outlined),
                label: const Text('Joblog'),
              ),
              OutlinedButton.icon(
                onPressed: state.watchSelectedJob,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Watch'),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JabaProgressCard(logText: '${state.jobStatus}\n${state.jobLog}'),
              const SizedBox(height: 14),
              if (state.jobMonitorAlert != null) ...[
                _MonitorAlertText(
                  title: state.jobMonitorAlert!.title,
                  message: state.jobMonitorAlert!.message,
                  isError: state.jobMonitorAlert!.isError,
                ),
                const SizedBox(height: 14),
              ],
              if (state.jobStatus.trim().isNotEmpty) ...[
                TerminalOutput(text: state.jobStatus, minHeight: 120),
                const SizedBox(height: 14),
              ],
              TerminalOutput(text: state.jobLog, minHeight: 360),
            ],
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _MonitorAlertText extends StatelessWidget {
  const _MonitorAlertText({
    required this.title,
    required this.message,
    required this.isError,
  });

  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.notifications_active_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title\n$message',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
