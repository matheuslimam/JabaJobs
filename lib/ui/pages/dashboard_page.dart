import 'package:flutter/material.dart';

import '../../state/cluster_app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/job_table.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    final health = state.health;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Dashboard',
          subtitle: session?.isAdmin == true
              ? 'Visão geral com permissões administrativas.'
              : 'Visão do usuário conectado ao cluster.',
        ),
        const SizedBox(height: 18),
        if (state.errorMessage != null)
          _Message(text: state.errorMessage!, error: true),
        if (state.bannerMessage != null) _Message(text: state.bannerMessage!),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 980 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 4 ? 2.5 : 2.2,
              children: [
                StatCard(
                  icon: Icons.link_outlined,
                  label: 'Conexão SSH',
                  value: state.isConnected ? 'Ativa' : 'Inativa',
                  detail: session?.host ?? '-',
                  color: Colors.greenAccent,
                ),
                StatCard(
                  icon: Icons.memory_outlined,
                  label: 'Memória',
                  value: health == null
                      ? '-'
                      : '${health.memory.used}/${health.memory.total}',
                  detail: health == null
                      ? null
                      : 'Disponível ${health.memory.available}',
                ),
                StatCard(
                  icon: Icons.storage_outlined,
                  label: 'Disco total',
                  value: health?.homeDisk.usePercent ?? '-',
                  detail: health == null
                      ? null
                      : '${health.homeDisk.used}/${health.homeDisk.size}',
                ),
                StatCard(
                  icon: Icons.speed_outlined,
                  label: 'Carga',
                  value: health?.loadAverage ?? '-',
                  detail: '1 / 5 / 15 min',
                  color: Colors.amberAccent,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassCard(
                title: 'Conexão',
                subtitle: 'Dados coletados após autenticação SSH.',
                child: _ConnectionDetails(state: state),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: GlassCard(
                title: 'Saúde básica',
                subtitle: 'Comandos: uptime, free -h, df -h --total.',
                child: _HealthDetails(state: state),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Meus jobs',
          subtitle: 'Usa myjobs quando disponível; caso contrário squeue.',
          trailing: OutlinedButton.icon(
            onPressed: state.refreshMyJobs,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
          ),
          child: JobTable(
            jobs: state.myJobs,
            selectedJobId: state.selectedJobId,
            onSelected: state.selectJob,
          ),
        ),
      ],
    );
  }
}

class _ConnectionDetails extends StatelessWidget {
  const _ConnectionDetails({required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    return Column(
      children: [
        _InfoRow(label: 'Host', value: session?.host ?? '-'),
        _InfoRow(label: 'Usuário informado', value: session?.username ?? '-'),
        _InfoRow(label: 'Usuário remoto', value: session?.remoteUser ?? '-'),
        _InfoRow(label: 'Hostname', value: session?.hostname ?? '-'),
        _InfoRow(
          label: 'Grupos',
          value: session == null ? '-' : session.groups.join(', '),
        ),
      ],
    );
  }
}

class _HealthDetails extends StatelessWidget {
  const _HealthDetails({required this.state});

  final ClusterAppState state;

  @override
  Widget build(BuildContext context) {
    final health = state.health;
    return Column(
      children: [
        _InfoRow(label: 'Uptime', value: health?.uptime ?? '-'),
        _InfoRow(label: 'RAM total', value: health?.memory.total ?? '-'),
        _InfoRow(label: 'RAM usada', value: health?.memory.used ?? '-'),
        _InfoRow(
          label: 'Disco livre',
          value: health?.homeDisk.available ?? '-',
        ),
        _InfoRow(label: 'Atualizado', value: _formatTime(health?.refreshedAt)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white60)),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.32)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(color: color)),
      ),
    );
  }
}

String _formatTime(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';
}
