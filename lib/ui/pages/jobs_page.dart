import 'package:flutter/material.dart';

import '../../state/cluster_app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/job_table.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key, required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jobs',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Selecione um job para abrir log ou cancelar.',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Meus jobs',
          subtitle: 'Lista limitada ao usuário conectado.',
          trailing: Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: state.refreshMyJobs,
                icon: const Icon(Icons.refresh),
                label: const Text('Ver meus jobs'),
              ),
              OutlinedButton.icon(
                onPressed: state.loadSelectedJobLog,
                icon: const Icon(Icons.article_outlined),
                label: const Text('Abrir log'),
              ),
              OutlinedButton.icon(
                onPressed: state.cancelSelectedJob,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar'),
              ),
            ],
          ),
          child: JobTable(
            jobs: state.myJobs,
            selectedJobId: state.selectedJobId,
            onSelected: state.selectJob,
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (state.bannerMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            state.bannerMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ],
      ],
    );
  }
}
