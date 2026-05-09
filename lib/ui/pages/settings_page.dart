import 'package:flutter/material.dart';

import '../../state/cluster_app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/terminal_output.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Preferências e pontos de extensão do MVP.',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Sessão atual',
          subtitle: 'A senha não é persistida em disco.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Info(label: 'Host', value: session?.host ?? '-'),
              _Info(label: 'Usuário', value: session?.remoteUser ?? '-'),
              _Info(label: 'Hostname', value: session?.hostname ?? '-'),
              _Info(label: 'Admin', value: state.isAdmin ? 'Sim' : 'Não'),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Atualização automática'),
                  const SizedBox(width: 12),
                  Switch(
                    value: state.autoRefresh,
                    onChanged: state.setAutoRefresh,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const GlassCard(
          title: 'Preparado para clusterctl',
          subtitle: 'A UI conversa apenas com ClusterRepository.',
          child: TerminalOutput(
            minHeight: 150,
            text: '''
connect()
getCurrentUser()
isAdmin()
getBasicHealth()
getMyJobs()
getAllJobs()
getJobLog(jobId)
cancelJob(jobId)
submitJob(partition, command)
getNodeHealth()
getGpuInfo()

Fase 2: trocar comandos SSH diretos por clusterctl <acao> nesta camada.''',
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
