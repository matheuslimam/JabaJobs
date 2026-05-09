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
