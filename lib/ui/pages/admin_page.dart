import 'package:flutter/material.dart';

import '../../core/app_exception.dart';
import '../../models/diagnostic_check.dart';
import '../../models/machine_resource.dart';
import '../../models/node_info.dart';
import '../../state/cluster_app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/job_table.dart';
import '../widgets/terminal_output.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.state});

  final ClusterAppState state;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _jobsUserController = TextEditingController();
  final _newUserController = TextEditingController();
  final _dellAdminController = TextEditingController();
  bool _forcePasswordChange = true;
  String _createUserPreview = 'Preencha os campos para gerar a prévia.';

  @override
  void dispose() {
    _jobsUserController.dispose();
    _newUserController.dispose();
    _dellAdminController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.state.adminSnapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Visão expandida para operação do cluster.',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () =>
                  widget.state.refreshDashboard(includeAdmin: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar tudo'),
            ),
            OutlinedButton.icon(
              onPressed: _refreshJobsForUser,
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Ver jobs por usuário'),
            ),
            OutlinedButton.icon(
              onPressed: widget.state.cancelSelectedJob,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar selecionado'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassCard(
                title: 'Saúde do Slurm',
                subtitle: 'scontrol ping e sinfo.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TerminalOutput(
                      text: snapshot?.slurmPing ?? '',
                      minHeight: 80,
                    ),
                    const SizedBox(height: 16),
                    _SinfoTable(rows: snapshot?.sinfoRows ?? const []),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: GlassCard(
                title: 'Nós',
                subtitle: 'Resumo de cluster-login e gpu-a4000 via Slurm.',
                child: _NodeTable(nodes: snapshot?.nodeRows ?? const []),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Recursos das máquinas',
          subtitle:
              'Capacidade esperada do cluster e leitura ao vivo quando acessível.',
          child: _MachineResourceGrid(
            resources: snapshot?.machineResources ?? const [],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Todos os jobs',
          subtitle: 'squeue completo para administradores.',
          child: JobTable(
            jobs: snapshot?.allJobs ?? const [],
            selectedJobId: widget.state.selectedJobId,
            onSelected: widget.state.selectJob,
            emptyText: 'Nenhum job atual no cluster.',
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Jobs por usuário',
          subtitle: 'Consulta administrativa com squeue -u.',
          trailing: OutlinedButton.icon(
            onPressed: _refreshJobsForUser,
            icon: const Icon(Icons.search),
            label: const Text('Consultar'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _jobsUserController,
                decoration: const InputDecoration(
                  labelText: 'Usuário Linux',
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
                onSubmitted: (_) => _refreshJobsForUser(),
              ),
              const SizedBox(height: 14),
              JobTable(
                jobs: widget.state.adminUserJobs,
                selectedJobId: widget.state.selectedJobId,
                onSelected: widget.state.selectJob,
                emptyText: widget.state.adminUserJobsOwner == null
                    ? 'Informe um usuário para consultar.'
                    : 'Nenhum job para ${widget.state.adminUserJobsOwner}.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassCard(
                title: 'GPU no cluster-login',
                subtitle: 'nvidia-smi local, sem criar job Slurm.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TerminalOutput(
                      text: snapshot?.gpuInfo.loginNodeSummary ?? '',
                      minHeight: 86,
                    ),
                    const SizedBox(height: 12),
                    TerminalOutput(
                      text: snapshot?.gpuInfo.loginNodeOutput ?? '',
                      minHeight: 220,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: GlassCard(
                title: 'GPU no gpu-a4000',
                subtitle:
                    'Tenta clusterctl/SSH interno; se falhar, use o teste Slurm.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TerminalOutput(
                      text: snapshot?.gpuInfo.a4000Summary ?? '',
                      minHeight: 86,
                    ),
                    const SizedBox(height: 12),
                    TerminalOutput(
                      text: snapshot?.gpuInfo.a4000Output ?? '',
                      minHeight: 220,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassCard(
                title: 'Teste Slurm A4000',
                subtitle: 'Ação explícita: cria um job curto via srun.',
                trailing: OutlinedButton.icon(
                  onPressed: () => widget.state.runGpuSlurmTest('a4000'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Rodar'),
                ),
                child: TerminalOutput(
                  text: widget.state.a4000SlurmTestOutput,
                  minHeight: 220,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: GlassCard(
                title: 'Teste Slurm GTX 1660',
                subtitle: 'Ação explícita: cria um job curto via srun.',
                trailing: OutlinedButton.icon(
                  onPressed: () => widget.state.runGpuSlurmTest('gtx1660'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Rodar'),
                ),
                child: TerminalOutput(
                  text: widget.state.gtx1660SlurmTestOutput,
                  minHeight: 220,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Diagnóstico do ambiente',
          subtitle: 'Checklist baseado no tutorial administrativo.',
          child: _DiagnosticsList(checks: snapshot?.diagnostics ?? const []),
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Criação de usuário',
          subtitle: 'Executa sudo -n /usr/local/sbin/clusterctl create-user.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newUserController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do usuário',
                        prefixIcon: Icon(Icons.person_add_alt_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _dellAdminController,
                      decoration: const InputDecoration(
                        labelText: 'Admin remoto da Dell',
                        prefixIcon: Icon(Icons.computer_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.22),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'O app não envia senha inicial. Depois de criar a conta, defina a senha manualmente no cluster-login com sudo passwd usuario.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _forcePasswordChange,
                onChanged: (value) {
                  setState(() => _forcePasswordChange = value ?? true);
                },
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Forçar troca de senha no primeiro login'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _previewCreateUser,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Pré-visualizar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _runCreateUserHelper,
                      icon: const Icon(Icons.security_outlined),
                      label: const Text('Criar via clusterctl'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TerminalOutput(text: _createUserPreview, minHeight: 120),
            ],
          ),
        ),
        if (widget.state.errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (widget.state.bannerMessage != null) ...[
          const SizedBox(height: 14),
          TerminalOutput(text: widget.state.bannerMessage!, minHeight: 100),
        ],
      ],
    );
  }

  Future<void> _previewCreateUser() async {
    try {
      final preview = await widget.state.previewCreateUserCommand(
        username: _newUserController.text,
        dellAdmin: _dellAdminController.text,
        forcePasswordChange: _forcePasswordChange,
      );
      setState(() {
        _createUserPreview =
            '$preview\n\n# A senha inicial ainda não é enviada pelo MVP.';
      });
    } on AppException catch (error) {
      setState(() => _createUserPreview = error.toString());
    }
  }

  Future<void> _refreshJobsForUser() async {
    await widget.state.refreshAdminJobsForUser(_jobsUserController.text);
  }

  Future<void> _runCreateUserHelper() async {
    await widget.state.runCreateUserHelper(
      username: _newUserController.text,
      dellAdmin: _dellAdminController.text,
      forcePasswordChange: _forcePasswordChange,
    );
  }
}

class _SinfoTable extends StatelessWidget {
  const _SinfoTable({required this.rows});

  final List<SinfoRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text(
        'Sem dados de sinfo.',
        style: TextStyle(color: Colors.white60),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Partição')),
          DataColumn(label: Text('Disponível')),
          DataColumn(label: Text('Limite')),
          DataColumn(label: Text('Nós')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Lista')),
        ],
        rows: rows
            .map(
              (row) => DataRow(
                cells: [
                  DataCell(Text(row.partition)),
                  DataCell(Text(row.availability)),
                  DataCell(Text(row.timeLimit)),
                  DataCell(Text(row.nodes)),
                  DataCell(Text(row.state)),
                  DataCell(Text(row.nodeList)),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _NodeTable extends StatelessWidget {
  const _NodeTable({required this.nodes});

  final List<NodeInfo> nodes;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const Text(
        'Sem dados dos nós.',
        style: TextStyle(color: Colors.white60),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nó')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Partição')),
          DataColumn(label: Text('CPU')),
          DataColumn(label: Text('RAM MB')),
          DataColumn(label: Text('GRES')),
        ],
        rows: nodes
            .map(
              (node) => DataRow(
                cells: [
                  DataCell(Text(node.nodeName)),
                  DataCell(Text(node.state)),
                  DataCell(Text(node.partition)),
                  DataCell(Text(node.cpus)),
                  DataCell(Text(node.memory)),
                  DataCell(Text(node.gres)),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _MachineResourceGrid extends StatelessWidget {
  const _MachineResourceGrid({required this.resources});

  final List<MachineResource> resources;

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return const Text(
        'Sem dados de recursos carregados.',
        style: TextStyle(color: Colors.white60),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        return GridView.count(
          crossAxisCount: wide ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: wide ? 2.6 : 2.15,
          children: resources
              .map((resource) => _MachineResourceCard(resource: resource))
              .toList(growable: false),
        );
      },
    );
  }
}

class _MachineResourceCard extends StatelessWidget {
  const _MachineResourceCard({required this.resource});

  final MachineResource resource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101720),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF303844)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                resource.name == 'gpu-a4000'
                    ? Icons.memory_outlined
                    : Icons.dns_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      resource.role,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ResourceLine(
            label: 'RAM',
            expected: resource.expectedRam,
            observed: resource.observedRam,
          ),
          _ResourceLine(
            label: 'Disco',
            expected: resource.expectedDisk,
            observed: resource.observedDisk,
          ),
          _ResourceLine(
            label: 'VRAM',
            expected: resource.expectedVram,
            observed: resource.observedVram,
          ),
          const Spacer(),
          Text(
            resource.source,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ResourceLine extends StatelessWidget {
  const _ResourceLine({
    required this.label,
    required this.expected,
    required this.observed,
  });

  final String label;
  final String expected;
  final String observed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: Text(
              'esperado $expected | observado $observed',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsList extends StatelessWidget {
  const _DiagnosticsList({required this.checks});

  final List<DiagnosticCheck> checks;

  @override
  Widget build(BuildContext context) {
    if (checks.isEmpty) {
      return const Text(
        'Sem diagnóstico carregado.',
        style: TextStyle(color: Colors.white60),
      );
    }

    return Column(
      children: checks
          .map((check) {
            final color = check.succeeded
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF303844)),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF303844)),
                ),
                leading: Icon(
                  check.succeeded
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: color,
                ),
                title: Text(check.title),
                subtitle: Text(
                  check.command,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Consolas'),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: TerminalOutput(text: check.output, minHeight: 120),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
