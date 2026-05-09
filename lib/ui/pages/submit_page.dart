import 'package:flutter/material.dart';

import '../../state/cluster_app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/terminal_output.dart';

class SubmitPage extends StatefulWidget {
  const SubmitPage({super.key, required this.state});

  final ClusterAppState state;

  @override
  State<SubmitPage> createState() => _SubmitPageState();
}

class _SubmitPageState extends State<SubmitPage> {
  final _commandController = TextEditingController(text: 'python train.py');
  final _directoryController = TextEditingController(text: '~');
  final _condaController = TextEditingController();
  String _partition = 'a4000';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.state.loadSubmitContext();
      final context = widget.state.submitContext;
      if (!mounted || context == null) {
        return;
      }
      if (_directoryController.text == '~') {
        _directoryController.text = context.workingDirectory;
      }
      if (_condaController.text.isEmpty && context.condaPrefix.isNotEmpty) {
        _condaController.text = context.condaPrefix;
      }
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    _directoryController.dispose();
    _condaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wrapper = _partition == 'a4000' ? 'run-a4000' : 'run-1660';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submit',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Submissão via wrappers do cluster com diretório e Conda opcionais.',
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Contexto remoto',
          subtitle: 'Cada submit roda em um shell SSH novo.',
          trailing: OutlinedButton.icon(
            onPressed: widget.state.loadSubmitContext,
            icon: const Icon(Icons.refresh),
            label: const Text('Detectar'),
          ),
          child: TerminalOutput(minHeight: 130, text: _contextText()),
        ),
        const SizedBox(height: 18),
        GlassCard(
          title: 'Executar comando',
          subtitle:
              'O app executa cd, ativa Conda se informado e chama o wrapper.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'a4000',
                    label: Text('a4000'),
                    icon: Icon(Icons.memory_outlined),
                  ),
                  ButtonSegment(
                    value: 'gtx1660',
                    label: Text('gtx1660'),
                    icon: Icon(Icons.developer_board_outlined),
                  ),
                ],
                selected: {_partition},
                onSelectionChanged: (values) {
                  setState(() => _partition = values.first);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _directoryController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Diretório remoto',
                        prefixIcon: Icon(Icons.folder_outlined),
                        hintText: '~/projects/meu_modelo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _condaController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Ambiente Conda opcional',
                        prefixIcon: Icon(Icons.science_outlined),
                        hintText: 'meu_env ou /home/user/.conda/envs/meu_env',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commandController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Comando',
                  prefixIcon: Icon(Icons.terminal_outlined),
                  hintText: 'python train.py',
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              TerminalOutput(minHeight: 118, text: _previewCommand(wrapper)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: widget.state.isBusy ? null : _submit,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Submeter job'),
                ),
              ),
            ],
          ),
        ),
        if (widget.state.bannerMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.state.bannerMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ],
        if (widget.state.errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    await widget.state.submitJob(
      partition: _partition,
      command: _commandController.text,
      workingDirectory: _directoryController.text,
      condaEnvironment: _condaController.text,
    );
  }

  String _previewCommand(String wrapper) {
    final conda = _condaController.text.trim();
    return [
      'cd ${_directoryController.text.trim().isEmpty ? '~' : _directoryController.text.trim()}',
      if (conda.isNotEmpty) 'conda activate $conda',
      '$wrapper ${_commandController.text.trim()}',
    ].join('\n');
  }

  String _contextText() {
    final context = widget.state.submitContext;
    if (context == null) {
      return 'Clique em Detectar para consultar pwd, Conda e helpers remotos.';
    }
    return [
      'pwd: ${context.workingDirectory}',
      'CONDA_PREFIX: ${context.condaPrefix.isEmpty ? '(vazio no shell SSH do app)' : context.condaPrefix}',
      'conda: ${context.condaVersion.trim()}',
      '',
      context.helperStatus.trim(),
    ].join('\n');
  }
}
