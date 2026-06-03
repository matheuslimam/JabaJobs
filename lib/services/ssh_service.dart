import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

import '../core/app_exception.dart';
import '../core/shell_utils.dart';
import '../models/connection_profile.dart';
import '../models/remote_command_result.dart';

class SshService {
  SSHClient? _client;
  String? _host;
  String? _username;

  bool get isConnected => _client != null;
  String? get host => _host;
  String? get username => _username;

  Future<void> connect(ConnectionProfile profile) async {
    close();

    try {
      final socket = await SSHSocket.connect(
        profile.host.trim(),
        profile.port,
        timeout: const Duration(seconds: 10),
      );
      final client = SSHClient(
        socket,
        username: profile.username.trim(),
        onPasswordRequest: () => profile.password,
        ident: 'JabaJobs_0.1',
      );

      _client = client;
      _host = profile.host.trim();
      _username = profile.username.trim();

      await run('true', timeout: const Duration(seconds: 10));
    } catch (error) {
      close();
      throw SshConnectionException(
        'Nao foi possivel conectar por SSH.',
        details: _buildConnectionFailureDetails(
          host: profile.host.trim(),
          port: profile.port,
          error: error,
        ),
      );
    }
  }

  Future<RemoteCommandResult> run(
    String command, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final client = _client;
    if (client == null) {
      throw const SshConnectionException('Nao ha uma sessao SSH ativa.');
    }

    final wrappedCommand = 'bash -lc ${shellQuote(command)}';
    try {
      final result = await client
          .runWithResult(wrappedCommand)
          .timeout(timeout);
      return RemoteCommandResult(
        command: command,
        stdout: utf8.decode(result.stdout, allowMalformed: true),
        stderr: utf8.decode(result.stderr, allowMalformed: true),
        exitCode: result.exitCode,
      );
    } catch (error) {
      throw RemoteCommandException(
        'Falha ao executar comando remoto.',
        details: '$command\n$error',
      );
    }
  }

  Future<String> runText(
    String command, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final result = await run(command, timeout: timeout);
    if (!result.succeeded) {
      throw RemoteCommandException(
        'O comando remoto retornou erro.',
        details: result.combinedOutput,
      );
    }
    return result.stdout.trimRight();
  }

  Future<bool> ping() async {
    final client = _client;
    if (client == null) {
      return false;
    }
    try {
      await client.ping().timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  void close() {
    _client?.close();
    _client = null;
    _host = null;
    _username = null;
  }

  String _buildConnectionFailureDetails({
    required String host,
    required int port,
    required Object error,
  }) {
    final rawError = error.toString();
    final lower = rawError.toLowerCase();
    final timedOut =
        error is TimeoutException ||
        error is SocketException && lower.contains('timed out');
    final refused = lower.contains('connection refused');
    final authLike =
        lower.contains('auth') ||
        lower.contains('password') ||
        lower.contains('permission denied');

    final details = StringBuffer();
    if (timedOut) {
      details.writeln('O Android nao conseguiu abrir TCP em $host:$port.');
      if (_looksLikeTailscaleIp(host)) {
        details.writeln(
          'Como o host e um IP Tailscale, o celular tambem precisa estar no Tailscale: app Tailscale instalado, logado no mesmo tailnet, VPN ativa e ACL liberando SSH para esse node.',
        );
        details.writeln(
          'Estar conectado ao Tailscale no PC nao coloca o APK do celular dentro da rede Tailscale.',
        );
      }
      details.writeln(
        'Teste decisivo: no proprio Android, tente SSH para $host:$port usando Termux ou outro cliente SSH. Se tambem der timeout, o problema e Tailscale/rota/ACL/sshd, nao usuario/senha do app.',
      );
    } else if (refused) {
      details.writeln(
        'O host respondeu, mas a porta $port recusou a conexao. Verifique se o sshd esta rodando e escutando nessa interface.',
      );
    } else if (authLike) {
      details.writeln(
        'O app chegou ao SSH, mas a autenticacao falhou. Confira usuario, senha e se login por senha esta habilitado.',
      );
    } else {
      details.writeln(
        'Confira host, porta, Tailscale, rota de rede e credenciais SSH.',
      );
    }

    details.writeln();
    details.writeln('Erro original:');
    details.write(rawError);
    return details.toString();
  }

  bool _looksLikeTailscaleIp(String host) {
    final parts = host.split('.');
    if (parts.length != 4) {
      return false;
    }
    final first = int.tryParse(parts.first);
    return first == 100;
  }
}
