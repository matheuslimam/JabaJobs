import '../core/app_exception.dart';
import '../core/shell_utils.dart';
import '../models/admin_snapshot.dart';
import '../models/connection_profile.dart';
import '../models/diagnostic_check.dart';
import '../models/gpu_info.dart';
import '../models/job_info.dart';
import '../models/machine_resource.dart';
import '../models/node_info.dart';
import '../models/server_health.dart';
import '../models/session_info.dart';
import '../models/submit_context.dart';
import '../services/admin_detector.dart';
import '../services/cluster_parser.dart';
import '../services/preferences_service.dart';
import '../services/ssh_service.dart';

class ClusterRepository {
  ClusterRepository({
    required SshService ssh,
    required ClusterParser parser,
    required PreferencesService preferences,
    AdminDetector adminDetector = const AdminDetector(),
  }) : _ssh = ssh,
       _parser = parser,
       _preferences = preferences,
       _adminDetector = adminDetector;

  final SshService _ssh;
  final ClusterParser _parser;
  final PreferencesService _preferences;
  final AdminDetector _adminDetector;

  SavedConnection loadSavedConnection() => _preferences.loadConnection();

  bool get isConnected => _ssh.isConnected;

  Future<SessionInfo> connect(ConnectionProfile profile) async {
    if (!profile.isValid) {
      throw const ValidationException('Preencha host, usuário e senha.');
    }

    await _preferences.saveConnection(
      host: profile.host.trim(),
      username: profile.username.trim(),
      remember: profile.rememberHostAndUser,
    );

    await _ssh.connect(profile);

    final hostname = await _ssh.runText('hostname');
    final remoteUser = await _ssh.runText('whoami');
    final groupsRaw = await _ssh.runText('id -nG');
    final groups = _parser.parseGroups(groupsRaw);

    return SessionInfo(
      host: profile.host.trim(),
      username: profile.username.trim(),
      remoteUser: remoteUser.trim(),
      hostname: hostname.trim(),
      groups: groups,
      isAdmin: _adminDetector.isAdmin(groups),
    );
  }

  Future<bool> ping() => _ssh.ping();

  Future<ServerHealth> getBasicHealth() async {
    final uptime = await _ssh.runText('uptime -p || uptime');
    final memoryRaw = await _ssh.runText('LC_ALL=C free -h');
    final diskRaw = await _ssh.runText(
      'LC_ALL=C df -h --total -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null || LC_ALL=C df -h /home',
    );
    final loadRaw = await _ssh.runText('cat /proc/loadavg');

    return ServerHealth(
      uptime: uptime,
      loadAverage: _parser.parseLoadAverage(loadRaw),
      memory: _parser.parseMemory(memoryRaw),
      homeDisk: _parser.parseTotalDisk(diskRaw),
      refreshedAt: DateTime.now(),
    );
  }

  Future<List<JobInfo>> getMyJobs(String username) async {
    final user = shellQuote(username);
    final command =
        '''
if command -v myjobs >/dev/null 2>&1; then
  myjobs
else
  squeue -u $user -h -o "%i|%P|%j|%u|%T|%M|%D|%R"
fi
''';
    final result = await _ssh.run(command);
    final output = result.stdout.trim().isNotEmpty
        ? result.stdout
        : result.stderr;
    return _parser.parseJobs(output);
  }

  Future<List<JobInfo>> getAllJobs() async {
    final raw = await _ssh.runText('squeue -h -o "%i|%P|%j|%u|%T|%M|%D|%R"');
    return _parser.parseJobs(raw);
  }

  Future<List<JobInfo>> getJobsForUser(String username) async {
    final user = sanitizeLinuxUsername(username);
    final raw = await _ssh.runText(
      'squeue -u ${shellQuote(user)} -h -o "%i|%P|%j|%u|%T|%M|%D|%R"',
    );
    return _parser.parseJobs(raw);
  }

  Future<String> getJobStatus(String jobId) async {
    final safeJobId = sanitizeJobId(jobId);
    final result = await _ssh.run('''
if command -v jobstatus >/dev/null 2>&1; then
  jobstatus $safeJobId
else
  squeue -j $safeJobId -o "%.18i %.12P %.30j %.12u %.12T %.10M %.6D %R"
  scontrol show job $safeJobId 2>/dev/null | head -n 20
fi
''', timeout: const Duration(seconds: 12));
    return result.combinedOutput.trim().isEmpty
        ? 'Sem status para o job $safeJobId.'
        : result.combinedOutput;
  }

  Future<String> getJobLog(String jobId) async {
    final safeJobId = sanitizeJobId(jobId);
    final result = await _ssh.run('''
tail -n 240 ~/logs/slurm-$safeJobId.out 2>&1
''', timeout: const Duration(seconds: 10));
    final output = _cleanTerminalOutput(result.combinedOutput);
    if (output.trim().isEmpty) {
      return 'Log vazio ou ainda não criado: ~/logs/slurm-$safeJobId.out';
    }
    return output;
  }

  Future<String> watchJob(String jobId) async {
    final safeJobId = sanitizeJobId(jobId);
    final result = await _ssh.run('''
if command -v watchjob >/dev/null 2>&1; then
  timeout 7s watchjob $safeJobId 2>&1 || true
else
  squeue -j $safeJobId -o "%.18i %.12P %.30j %.12u %.12T %.10M %.6D %R"
  printf '\\n--- log ---\\n'
  tail -n 80 ~/logs/slurm-$safeJobId.out 2>&1
fi
''', timeout: const Duration(seconds: 12));
    final output = _cleanTerminalOutput(result.combinedOutput);
    return output.trim().isEmpty
        ? 'Sem saída de watchjob para o job $safeJobId.'
        : output;
  }

  Future<String> cancelJob(String jobId) async {
    final safeJobId = sanitizeJobId(jobId);
    final command =
        '''
if command -v canceljob >/dev/null 2>&1; then
  canceljob $safeJobId
else
  scancel $safeJobId
fi
''';
    final result = await _ssh.run(
      command,
      timeout: const Duration(seconds: 15),
    );
    if (!result.succeeded) {
      throw RemoteCommandException(
        'Não foi possível cancelar o job $safeJobId.',
        details: result.combinedOutput,
      );
    }
    return result.combinedOutput.trim().isEmpty
        ? 'Cancelamento solicitado para o job $safeJobId.'
        : result.combinedOutput;
  }

  Future<String> submitJob({
    required String partition,
    required String command,
    String workingDirectory = '~',
    String condaEnvironment = '',
  }) async {
    final cleanCommand = sanitizeSubmitCommand(command);
    final cleanDirectory = sanitizeRemoteDirectory(workingDirectory);
    final cleanConda = sanitizeCondaEnvironment(condaEnvironment);
    final cdCommand = _buildCdCommand(cleanDirectory);
    final wrapper = switch (partition) {
      'a4000' => 'run-a4000',
      'gtx1660' => 'run-1660',
      _ => throw const ValidationException('Partição inválida.'),
    };

    final condaActivation = cleanConda.isEmpty
        ? ''
        : '''
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh 2>/dev/null || true
conda activate ${shellQuote(cleanConda)}
''';
    final result = await _ssh.run('''
$cdCommand
$condaActivation
$wrapper $cleanCommand
''', timeout: const Duration(seconds: 30));
    if (!result.succeeded) {
      throw RemoteCommandException(
        'Falha ao submeter o job.',
        details: result.combinedOutput,
      );
    }

    final jobId = _parser.parseSubmittedJobId(result.combinedOutput);
    if (jobId != null) {
      return 'Job $jobId submetido em $partition.';
    }
    return result.combinedOutput.trim().isEmpty
        ? 'Job submetido em $partition.'
        : result.combinedOutput;
  }

  Future<SubmitContext> getSubmitContext() async {
    final workingDirectory = await _ssh.runText('pwd');
    final condaPrefix = await _ssh.runText('printf "%s" "\${CONDA_PREFIX:-}"');
    final condaVersion = await _ssh.run(
      '/opt/miniconda3/bin/conda --version 2>&1 || conda --version 2>&1 || true',
      timeout: const Duration(seconds: 8),
    );
    final helpers = await _ssh.run(r'''
for cmd in run-a4000 run-1660 shell-a4000 myjobs canceljob jobstatus joblog watchjob; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "OK  %s -> %s\\n" "$cmd" "$(command -v "$cmd")"
  else
    printf "NOK %s\\n" "$cmd"
  fi
done
''', timeout: const Duration(seconds: 10));
    return SubmitContext(
      workingDirectory: workingDirectory.trim().isEmpty
          ? '~'
          : workingDirectory.trim(),
      condaPrefix: condaPrefix.trim(),
      condaVersion: condaVersion.combinedOutput,
      helperStatus: helpers.combinedOutput,
    );
  }

  Future<List<SinfoRow>> getSinfo() async {
    final raw = await _ssh.runText('sinfo -h -o "%P|%a|%l|%D|%t|%N"');
    return _parser.parseSinfo(raw);
  }

  Future<List<NodeInfo>> getNodeHealth() async {
    final raw = await _ssh.runText('sinfo -N -h -o "%N|%T|%P|%c|%m|%G"');
    return _parser.parseNodes(raw);
  }

  Future<List<MachineResource>> getMachineResources() async {
    final loginMemoryRaw = await _runBestEffort(
      'LC_ALL=C free -h',
      timeout: const Duration(seconds: 8),
    );
    final loginDiskRaw = await _runBestEffort(
      'LC_ALL=C df -h --total -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null || LC_ALL=C df -h /',
      timeout: const Duration(seconds: 8),
    );
    final loginVramRaw = await _runBestEffort(
      'nvidia-smi --query-gpu=memory.total,memory.used --format=csv,noheader,nounits 2>&1 || true',
      timeout: const Duration(seconds: 10),
    );

    final a4000MemoryRaw = await _runBestEffort(
      'ssh -o BatchMode=yes -o ConnectTimeout=5 gpu-a4000 LC_ALL=C free -h 2>&1',
      timeout: const Duration(seconds: 14),
    );
    final a4000DiskRaw = await _runBestEffort(
      'ssh -o BatchMode=yes -o ConnectTimeout=5 gpu-a4000 "LC_ALL=C df -h --total -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null || LC_ALL=C df -h /" 2>&1',
      timeout: const Duration(seconds: 14),
    );
    final a4000VramRaw = await _runBestEffort(
      'ssh -o BatchMode=yes -o ConnectTimeout=5 gpu-a4000 "nvidia-smi --query-gpu=memory.total,memory.used --format=csv,noheader,nounits 2>&1 || true"',
      timeout: const Duration(seconds: 14),
    );
    final a4000SlurmRaw = await _runBestEffort(
      'scontrol show node gpu-a4000 2>&1 | head -n 40',
      timeout: const Duration(seconds: 10),
    );

    return [
      MachineResource(
        name: 'cluster-login',
        role: 'MSI / login / GTX 1660',
        expectedRam: '32 GB',
        expectedDisk: '1.5 TB',
        expectedVram: '6 GB',
        observedRam: _observedRam(loginMemoryRaw),
        observedDisk: _observedDisk(loginDiskRaw),
        observedVram: _observedVram(loginVramRaw),
        source: 'Coleta direta no host conectado',
      ),
      MachineResource(
        name: 'gpu-a4000',
        role: 'Dell / treino / RTX A4000',
        expectedRam: '64 GB',
        expectedDisk: '2.5 TB',
        expectedVram: '16 GB',
        observedRam: _observedRam(a4000MemoryRaw, slurmFallback: a4000SlurmRaw),
        observedDisk: _observedDisk(a4000DiskRaw),
        observedVram: _observedVram(a4000VramRaw, slurmFallback: a4000SlurmRaw),
        source:
            'SSH interno quando disponível; fallback parcial via Slurm para RAM/VRAM',
      ),
    ];
  }

  Future<GpuInfo> getGpuInfo() async {
    const query =
        'nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,utilization.gpu --format=csv,noheader,nounits 2>&1 || true';
    final a4000Helper = await _runBestEffort(
      _clusterCtlCommand('gpu-info a4000'),
      timeout: const Duration(seconds: 15),
    );
    final loginNode = await _runBestEffort(
      'nvidia-smi 2>&1 || true',
      timeout: const Duration(seconds: 12),
    );
    final loginNodeSummary = await _runBestEffort(
      query,
      timeout: const Duration(seconds: 12),
    );
    final a4000 = await _runBestEffort(
      'ssh -o BatchMode=yes -o ConnectTimeout=5 gpu-a4000 nvidia-smi 2>&1 || true',
      timeout: const Duration(seconds: 20),
    );
    final a4000Summary = await _runBestEffort(
      'ssh -o BatchMode=yes -o ConnectTimeout=5 gpu-a4000 ${shellQuote(query)}',
      timeout: const Duration(seconds: 20),
    );
    final helperAvailable =
        a4000Helper.trim().isNotEmpty &&
        !_looksLikeRemoteFailure(a4000Helper) &&
        !a4000Helper.toLowerCase().contains('not found');
    final a4000AccessDenied =
        _looksLikeRemoteFailure(a4000) || _looksLikeRemoteFailure(a4000Summary);
    return GpuInfo(
      loginNodeOutput: loginNode,
      a4000Output: helperAvailable
          ? a4000Helper
          : a4000AccessDenied
          ? _a4000DirectAccessUnavailableMessage(a4000)
          : a4000,
      loginNodeSummary: _formatGpuSummary(loginNodeSummary),
      a4000Summary: helperAvailable
          ? _formatGpuSummary(a4000Helper)
          : a4000AccessDenied
          ? 'RTX A4000 | VRAM esperada 16 GB | leitura direta indisponível'
          : _formatGpuSummary(a4000Summary),
      refreshedAt: DateTime.now(),
    );
  }

  Future<String> runGpuSlurmTest(String partition) async {
    final cleanPartition = switch (partition) {
      'a4000' => 'a4000',
      'gtx1660' => 'gtx1660',
      _ => throw const ValidationException('Partição inválida.'),
    };
    final result = await _ssh.run(
      'timeout 25s srun -p $cleanPartition --gres=gpu:1 nvidia-smi 2>&1 || true',
      timeout: const Duration(seconds: 35),
    );
    return result.combinedOutput.trim().isEmpty
        ? 'Sem saída do teste Slurm em $cleanPartition.'
        : result.combinedOutput;
  }

  Future<List<DiagnosticCheck>> getDiagnostics() async {
    final checks = <({String title, String command})>[
      (
        title: 'Helpers de usuário',
        command:
            r'for cmd in run-a4000 run-1660 shell-a4000 myjobs canceljob jobstatus joblog watchjob; do command -v "$cmd" || echo "MISSING $cmd"; done',
      ),
      (
        title: 'Tailscale',
        command: 'tailscale ip 2>&1; tailscale status 2>&1 | head -n 20',
      ),
      (
        title: 'Conda local',
        command: '/opt/miniconda3/bin/conda --version 2>&1',
      ),
      (title: 'clusterctl health', command: _clusterCtlCommand('health')),
      (title: 'MUNGE local', command: 'munge -n | unmunge 2>&1'),
      (
        title: 'Nó gpu-a4000 no Slurm',
        command: 'sinfo -N -n gpu-a4000 -o "%N %T %P %c %m %G" 2>&1',
      ),
      (
        title: 'Detalhes gpu-a4000 no Slurm',
        command: 'scontrol show node gpu-a4000 2>&1 | head -n 80',
      ),
      (
        title: 'Nós Slurm detalhados',
        command: 'scontrol show nodes 2>&1 | head -n 120',
      ),
      (
        title: 'Logs slurmctld',
        command: 'journalctl -u slurmctld -n 80 --no-pager 2>&1',
      ),
      (
        title: 'Logs slurmd',
        command: 'journalctl -u slurmd -n 80 --no-pager 2>&1',
      ),
      (
        title: 'Logs munge',
        command: 'journalctl -u munge -n 80 --no-pager 2>&1',
      ),
      (title: 'Logs ssh', command: 'journalctl -u ssh -n 80 --no-pager 2>&1'),
    ];

    final results = <DiagnosticCheck>[];
    for (final check in checks) {
      try {
        final result = await _ssh.run(
          check.command,
          timeout: const Duration(seconds: 14),
        );
        results.add(
          DiagnosticCheck(
            title: check.title,
            command: check.command,
            output: result.combinedOutput,
            succeeded: result.succeeded,
          ),
        );
      } on AppException catch (error) {
        results.add(
          DiagnosticCheck(
            title: check.title,
            command: check.command,
            output: error.toString(),
            succeeded: false,
          ),
        );
      }
    }
    return results;
  }

  Future<AdminSnapshot> getAdminSnapshot() async {
    final ping = await _ssh.run(
      'scontrol ping 2>&1 || true',
      timeout: const Duration(seconds: 10),
    );
    final sinfo = await getSinfo();
    final nodes = await getNodeHealth();
    final jobs = await getAllJobs();
    final gpu = await getGpuInfo();
    final machineResources = await getMachineResources();
    final diagnostics = await getDiagnostics();

    return AdminSnapshot(
      slurmPing: ping.combinedOutput,
      sinfoRows: sinfo,
      nodeRows: nodes,
      allJobs: jobs,
      gpuInfo: gpu,
      machineResources: machineResources,
      diagnostics: diagnostics,
      refreshedAt: DateTime.now(),
    );
  }

  Future<String> previewCreateUserCommand({
    required String username,
    required String dellAdmin,
    required bool forcePasswordChange,
  }) async {
    final user = username.trim();
    final admin = dellAdmin.trim();
    sanitizeLinuxUsername(user);
    if (admin.isEmpty) {
      throw const ValidationException('Informe o admin remoto da Dell.');
    }

    final todo = forcePasswordChange
        ? '\nsudo chage -d 0 ${shellQuote(user)}'
        : '';
    return 'sudo -n /usr/local/sbin/clusterctl create-user ${shellQuote(user)} ${shellQuote(admin)}'
        '\nsudo passwd ${shellQuote(user)}'
        '$todo';
  }

  Future<String> runCreateUserHelper({
    required String username,
    required String dellAdmin,
    required bool forcePasswordChange,
  }) async {
    final user = sanitizeLinuxUsername(username);
    final admin = dellAdmin.trim();
    if (admin.isEmpty) {
      throw const ValidationException('Informe o admin remoto da Dell.');
    }

    final result = await _ssh.run(
      _clusterCtlCommand(
        'create-user ${shellQuote(user)} ${shellQuote(admin)}',
      ),
      timeout: const Duration(seconds: 30),
    );
    if (!result.succeeded) {
      throw RemoteCommandException(
        'Falha ao criar usuário via clusterctl.',
        details:
            '${result.combinedOutput}\n\nVerifique se /usr/local/sbin/clusterctl existe e se o sudoers contém:\n%clusteradmins ALL=(root) NOPASSWD: /usr/local/sbin/clusterctl',
      );
    }

    final forceChange = forcePasswordChange
        ? '\nDepois force troca de senha, se desejar: sudo chage -d 0 $user'
        : '';
    return '${result.combinedOutput}\nPróximo passo seguro: defina a senha manualmente no cluster-login com:\n  sudo passwd $user$forceChange';
  }

  void disconnect() => _ssh.close();

  String _buildCdCommand(String directory) {
    if (directory == '~') {
      return 'cd -- "\$HOME"';
    }
    if (directory.startsWith('~/')) {
      return 'cd -- "\$HOME"/${shellQuote(directory.substring(2))}';
    }
    return 'cd -- ${shellQuote(directory)}';
  }

  String _formatGpuSummary(String raw) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return 'Sem dados de VRAM.';
    }
    return lines
        .map((line) {
          final parts = line.split(',').map((part) => part.trim()).toList();
          if (parts.length < 5) {
            return line;
          }
          return '${parts[0]} | VRAM ${parts[2]}/${parts[1]} MiB | livre ${parts[3]} MiB | GPU ${parts[4]}%';
        })
        .join('\n');
  }

  String _clusterCtlCommand(String args) {
    return '''
clusterctl_status=127
if [ -x /usr/local/sbin/clusterctl ]; then
  sudo -n /usr/local/sbin/clusterctl $args 2>&1
  clusterctl_status=\$?
  if [ \$clusterctl_status -eq 0 ]; then
    exit 0
  fi
fi
if command -v clusterctl >/dev/null 2>&1; then
  clusterctl $args 2>&1
  clusterctl_status=\$?
  if [ \$clusterctl_status -eq 0 ]; then
    exit 0
  fi
fi
if [ \$clusterctl_status -eq 127 ]; then
  printf '%s\\n' 'clusterctl não instalado. Instale /usr/local/sbin/clusterctl e configure sudoers NOPASSWD para clusteradmins.'
fi
exit \$clusterctl_status
''';
  }

  bool _isClusterCtlUnavailable(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('clusterctl não instalado') ||
        lower.contains('clusterctl nao instalado') ||
        lower.contains('a password is required') ||
        lower.contains('sudo: a password') ||
        lower.contains('not in the sudoers') ||
        lower.contains('is not allowed to execute') ||
        lower.contains('clusterctl: command not found');
  }

  String _observedRam(String freeRaw, {String slurmFallback = ''}) {
    if (!_looksLikeRemoteFailure(freeRaw)) {
      final memory = _parser.parseMemory(freeRaw);
      if (memory.total != '-') {
        return '${memory.used}/${memory.total} usado, ${memory.available} livre';
      }
    }
    final realMemoryMb = RegExp(r'RealMemory=(\d+)').firstMatch(slurmFallback);
    if (realMemoryMb != null) {
      final mb = int.tryParse(realMemoryMb.group(1)!);
      if (mb != null) {
        return '${(mb / 1024).toStringAsFixed(1)} GiB total via Slurm';
      }
    }
    return 'Indisponível';
  }

  String _observedDisk(String dfRaw) {
    if (_looksLikeRemoteFailure(dfRaw)) {
      return 'Indisponível';
    }
    final disk = _parser.parseTotalDisk(dfRaw);
    if (disk.size == '-') {
      return 'Indisponível';
    }
    return '${disk.used}/${disk.size} usado, ${disk.available} livre (${disk.usePercent})';
  }

  String _observedVram(String raw, {String slurmFallback = ''}) {
    if (!_looksLikeRemoteFailure(raw)) {
      final line = raw
          .split('\n')
          .map((value) => value.trim())
          .firstWhere((value) => value.contains(','), orElse: () => '');
      final parts = line.split(',').map((value) => value.trim()).toList();
      if (parts.length >= 2) {
        return '${parts[1]}/${parts[0]} MiB usado';
      }
    }
    final gres = RegExp(r'Gres=([^\s]+)').firstMatch(slurmFallback)?.group(1);
    if (gres != null && gres.toLowerCase().contains('a4000')) {
      return '16 GB esperado via Slurm/GRES';
    }
    if (gres != null && gres.toLowerCase().contains('gpu')) {
      return gres;
    }
    return 'Indisponível';
  }

  bool _looksLikeRemoteFailure(String raw) {
    final lower = raw.toLowerCase();
    return raw.trim().isEmpty ||
        _isClusterCtlUnavailable(raw) ||
        lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('permission denied') ||
        lower.contains('publickey,password') ||
        lower.contains('direct nvidia-smi unavailable') ||
        lower.contains('could not resolve') ||
        lower.contains('connection refused') ||
        lower.contains('no route to host') ||
        lower.contains('falha ao executar comando remoto');
  }

  String _a4000DirectAccessUnavailableMessage(String raw) {
    final reason = raw.trim().isEmpty
        ? 'Sem saída do comando SSH.'
        : raw.trim();
    return '''
Leitura direta da A4000 indisponível.

O app está conectado ao cluster-login, mas o usuário da sessão não consegue fazer SSH interno para gpu-a4000 sem interação.

Motivo retornado:
$reason

Admin no cluster-login não implica SSH interno automático para a Dell. Para leitura automática de nvidia-smi na Dell, configure uma destas opções:

1. SSH interno sem senha/chave para esse usuário em gpu-a4000.
2. Helper remoto seguro: clusterctl gpu-info a4000.

Enquanto isso, use o botão "Teste Slurm A4000" para consultar a GPU por srun. Esse teste cria um job curto explicitamente.''';
  }

  Future<String> _runBestEffort(
    String command, {
    required Duration timeout,
  }) async {
    try {
      final result = await _ssh.run(command, timeout: timeout);
      return result.combinedOutput;
    } on AppException catch (error) {
      return error.toString();
    }
  }

  String _cleanTerminalOutput(String value) {
    return value
        .replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '')
        .replaceAll('\r', '\n')
        .trimRight();
  }
}
