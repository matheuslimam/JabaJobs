import 'package:flutter/material.dart';

import '../../models/connection_profile.dart';
import '../../state/cluster_app_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.state});

  final ClusterAppState state;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostController;
  late final TextEditingController _userController;
  final _passwordController = TextEditingController();
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.state.savedConnection;
    _hostController = TextEditingController(text: saved.host);
    _userController = TextEditingController(text: saved.username);
    _remember = saved.rememberHostAndUser;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? 480 : 1040,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(compact ? 18 : 32),
                        child: compact
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _LoginIntro(compact: compact),
                                  const SizedBox(height: 20),
                                  _buildLoginCard(context),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 44),
                                      child: _LoginIntro(compact: compact),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 420,
                                    child: _buildLoginCard(context),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Conectar ao cluster',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Host',
                  prefixIcon: Icon(Icons.dns_outlined),
                  hintText: '100.104.26.64',
                ),
                validator: _required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Usuario Linux',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: _required,
                onFieldSubmitted: (_) => _connect(),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _remember,
                onChanged: widget.state.isBusy
                    ? null
                    : (value) {
                        setState(() {
                          _remember = value ?? false;
                        });
                      },
                title: const Text('Lembrar host e usuario'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: widget.state.isBusy ? null : _connect,
                icon: widget.state.isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(widget.state.isBusy ? 'Conectando...' : 'Conectar'),
              ),
              if (widget.state.errorMessage != null) ...[
                const SizedBox(height: 16),
                _MessageBox(text: widget.state.errorMessage!, isError: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await widget.state.connect(
      ConnectionProfile(
        host: _hostController.text,
        username: _userController.text,
        password: _passwordController.text,
        rememberHostAndUser: _remember,
      ),
    );
  }
}

class _LoginIntro extends StatelessWidget {
  const _LoginIntro({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        _JabaLogo(size: compact ? 150 : 450),
        Text(
          'Acompanhamento visual de jobs do cluster via Tailscale e SSH.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        const _StatusLine(
          icon: Icons.vpn_lock_outlined,
          text: 'Use o IP Tailscale do no cluster-login.',
        ),
        const SizedBox(height: 10),
        const _StatusLine(
          icon: Icons.password_outlined,
          text: 'A senha fica apenas na memoria da sessao.',
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}

class _JabaLogo extends StatelessWidget {
  const _JabaLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('jena.png', fit: BoxFit.contain, width: size);
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
