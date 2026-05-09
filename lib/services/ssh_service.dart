import 'dart:convert';

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
        'Não foi possível conectar por SSH.',
        details:
            'Confira se o Tailscale está conectado, se o host está correto e se usuário/senha estão válidos.\n$error',
      );
    }
  }

  Future<RemoteCommandResult> run(
    String command, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final client = _client;
    if (client == null) {
      throw const SshConnectionException('Não há uma sessão SSH ativa.');
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
}
