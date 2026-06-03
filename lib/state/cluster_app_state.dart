import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/admin_snapshot.dart';
import '../models/connection_profile.dart';
import '../models/job_info.dart';
import '../models/job_monitor_alert.dart';
import '../models/server_health.dart';
import '../models/session_info.dart';
import '../models/submit_context.dart';
import '../repositories/cluster_repository.dart';
import '../services/preferences_service.dart';

class ClusterAppState extends ChangeNotifier {
  ClusterAppState(this._repository) {
    savedConnection = _repository.loadSavedConnection();
  }

  final ClusterRepository _repository;

  late SavedConnection savedConnection;
  SessionInfo? session;
  ServerHealth? health;
  AdminSnapshot? adminSnapshot;
  List<JobInfo> myJobs = const [];
  List<JobInfo> adminUserJobs = const [];
  String? adminUserJobsOwner;
  SubmitContext? submitContext;
  String a4000SlurmTestOutput = '';
  String gtx1660SlurmTestOutput = '';
  String? selectedJobId;
  String jobLog = '';
  String jobStatus = '';
  String? bannerMessage;
  String? errorMessage;
  JobMonitorAlert? jobMonitorAlert;
  DateTime? jobMonitorLastCheckedAt;
  bool isBusy = false;
  bool autoRefresh = false;
  bool followLog = false;
  bool notifyOnSelectedJobEvent = false;

  Timer? _refreshTimer;
  Timer? _logTimer;
  Timer? _jobMonitorTimer;
  bool _logRefreshInFlight = false;
  bool _jobMonitorInFlight = false;
  bool _monitorWasActive = false;
  String? _monitorJobId;
  String? _lastMonitorAlertKey;

  bool get isConnected => session != null && _repository.isConnected;
  bool get isAdmin => session?.isAdmin ?? false;
  JobInfo? get selectedJob {
    final id = selectedJobId;
    if (id == null) {
      return null;
    }
    return _findJobById(myJobs, id);
  }

  Future<void> connect(ConnectionProfile profile) async {
    await _guard(() async {
      session = await _repository.connect(profile);
      savedConnection = _repository.loadSavedConnection();
      await refreshDashboard(includeAdmin: session!.isAdmin);
    });
  }

  Future<void> refreshDashboard({bool includeAdmin = false}) async {
    final current = session;
    if (current == null) {
      return;
    }

    await _guard(() async {
      health = await _repository.getBasicHealth();
      myJobs = await _repository.getMyJobs(current.remoteUser);
      selectedJobId ??= myJobs.isNotEmpty ? myJobs.first.jobId : null;
      if (includeAdmin || current.isAdmin) {
        adminSnapshot = await _repository.getAdminSnapshot();
      }
    }, setBusy: false);
  }

  Future<void> refreshMyJobs() async {
    final current = session;
    if (current == null) {
      return;
    }
    await _guard(() async {
      myJobs = await _repository.getMyJobs(current.remoteUser);
    }, setBusy: false);
  }

  void selectJob(String? jobId) {
    selectedJobId = jobId;
    jobLog = '';
    jobStatus = '';
    jobMonitorAlert = null;
    _resetJobMonitorBaseline();
    if (notifyOnSelectedJobEvent) {
      _startJobMonitorTimer();
      unawaited(_checkSelectedJobMonitor());
    }
    notifyListeners();
  }

  Future<void> loadSelectedJobLog() async {
    final jobId = selectedJobId;
    if (jobId == null || jobId.isEmpty) {
      errorMessage = 'Selecione um job primeiro.';
      notifyListeners();
      return;
    }
    await _refreshLogSafely(() => _repository.getJobLog(jobId));
  }

  Future<void> loadSelectedJobStatus() async {
    final jobId = selectedJobId;
    if (jobId == null || jobId.isEmpty) {
      errorMessage = 'Selecione um job primeiro.';
      notifyListeners();
      return;
    }
    await _guard(() async {
      jobStatus = await _repository.getJobStatus(jobId);
    }, setBusy: false);
  }

  Future<void> watchSelectedJob() async {
    final jobId = selectedJobId;
    if (jobId == null || jobId.isEmpty) {
      errorMessage = 'Selecione um job primeiro.';
      notifyListeners();
      return;
    }
    await _refreshLogSafely(() => _repository.watchJob(jobId));
  }

  Future<void> cancelSelectedJob() async {
    final jobId = selectedJobId;
    if (jobId == null || jobId.isEmpty) {
      errorMessage = 'Selecione um job para cancelar.';
      notifyListeners();
      return;
    }
    await _guard(() async {
      bannerMessage = await _repository.cancelJob(jobId);
      await refreshDashboard(includeAdmin: isAdmin);
    });
  }

  Future<void> submitJob({
    required String partition,
    required String command,
    String workingDirectory = '~',
    String condaEnvironment = '',
  }) async {
    await _guard(() async {
      bannerMessage = await _repository.submitJob(
        partition: partition,
        command: command,
        workingDirectory: workingDirectory,
        condaEnvironment: condaEnvironment,
      );
      await refreshDashboard(includeAdmin: isAdmin);
    });
  }

  Future<void> loadSubmitContext() async {
    await _guard(() async {
      submitContext = await _repository.getSubmitContext();
    }, setBusy: false);
  }

  Future<void> refreshAdminJobsForUser(String username) async {
    await _guard(() async {
      adminUserJobs = await _repository.getJobsForUser(username);
      adminUserJobsOwner = username.trim();
    }, setBusy: false);
  }

  Future<void> runGpuSlurmTest(String partition) async {
    await _guard(() async {
      final output = await _repository.runGpuSlurmTest(partition);
      if (partition == 'a4000') {
        a4000SlurmTestOutput = output;
      } else {
        gtx1660SlurmTestOutput = output;
      }
    });
  }

  Future<String> previewCreateUserCommand({
    required String username,
    required String dellAdmin,
    required bool forcePasswordChange,
  }) async {
    return _repository.previewCreateUserCommand(
      username: username,
      dellAdmin: dellAdmin,
      forcePasswordChange: forcePasswordChange,
    );
  }

  Future<void> runCreateUserHelper({
    required String username,
    required String dellAdmin,
    required bool forcePasswordChange,
  }) async {
    await _guard(() async {
      bannerMessage = await _repository.runCreateUserHelper(
        username: username,
        dellAdmin: dellAdmin,
        forcePasswordChange: forcePasswordChange,
      );
    });
  }

  void setAutoRefresh(bool value) {
    autoRefresh = value;
    _refreshTimer?.cancel();
    if (value) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        refreshDashboard(includeAdmin: isAdmin);
      });
    }
    notifyListeners();
  }

  void setFollowLog(bool value) {
    followLog = value;
    _logTimer?.cancel();
    if (value) {
      loadSelectedJobLog();
      _logTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        loadSelectedJobLog();
      });
    }
    notifyListeners();
  }

  void setNotifyOnSelectedJobEvent(bool value) {
    if (!value) {
      notifyOnSelectedJobEvent = false;
      jobMonitorAlert = null;
      _jobMonitorTimer?.cancel();
      _jobMonitorTimer = null;
      notifyListeners();
      return;
    }

    if (selectedJobId == null || selectedJobId!.isEmpty) {
      errorMessage = 'Selecione um job primeiro.';
      notifyListeners();
      return;
    }

    notifyOnSelectedJobEvent = true;
    jobMonitorAlert = null;
    errorMessage = null;
    _lastMonitorAlertKey = null;
    _resetJobMonitorBaseline();
    _startJobMonitorTimer();
    unawaited(_checkSelectedJobMonitor());
    notifyListeners();
  }

  void clearJobMonitorAlert() {
    jobMonitorAlert = null;
    notifyListeners();
  }

  void clearMessages() {
    bannerMessage = null;
    errorMessage = null;
    jobMonitorAlert = null;
    notifyListeners();
  }

  void disconnect() {
    _refreshTimer?.cancel();
    _logTimer?.cancel();
    _jobMonitorTimer?.cancel();
    _repository.disconnect();
    session = null;
    health = null;
    adminSnapshot = null;
    myJobs = const [];
    adminUserJobs = const [];
    adminUserJobsOwner = null;
    submitContext = null;
    a4000SlurmTestOutput = '';
    gtx1660SlurmTestOutput = '';
    jobLog = '';
    jobStatus = '';
    jobMonitorAlert = null;
    jobMonitorLastCheckedAt = null;
    selectedJobId = null;
    autoRefresh = false;
    followLog = false;
    notifyOnSelectedJobEvent = false;
    _monitorWasActive = false;
    _monitorJobId = null;
    _lastMonitorAlertKey = null;
    notifyListeners();
  }

  Future<void> _guard(
    Future<void> Function() action, {
    bool setBusy = true,
  }) async {
    errorMessage = null;
    bannerMessage = null;
    if (setBusy) {
      isBusy = true;
    }
    notifyListeners();
    try {
      await action();
    } on AppException catch (error) {
      errorMessage = error.toString();
    } catch (error) {
      errorMessage = 'Algo deu errado.\n$error';
    } finally {
      if (setBusy) {
        isBusy = false;
      }
      notifyListeners();
    }
  }

  Future<void> _refreshLogSafely(Future<String> Function() loader) async {
    if (_logRefreshInFlight) {
      return;
    }
    _logRefreshInFlight = true;
    errorMessage = null;
    notifyListeners();
    try {
      final output = await loader();
      if (output.trim().isNotEmpty) {
        jobLog = output;
      }
    } on AppException catch (error) {
      errorMessage = error.toString();
    } catch (error) {
      errorMessage = 'Algo deu errado ao atualizar o log.\n$error';
    } finally {
      _logRefreshInFlight = false;
      notifyListeners();
    }
  }

  void _startJobMonitorTimer() {
    _jobMonitorTimer?.cancel();
    _jobMonitorTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_checkSelectedJobMonitor());
    });
  }

  void _resetJobMonitorBaseline() {
    _monitorJobId = selectedJobId;
    _monitorWasActive = selectedJob?.isActive ?? false;
  }

  Future<void> _checkSelectedJobMonitor() async {
    if (!notifyOnSelectedJobEvent || _jobMonitorInFlight) {
      return;
    }

    final current = session;
    final jobId = selectedJobId;
    if (current == null || jobId == null || jobId.isEmpty) {
      return;
    }

    if (_monitorJobId != jobId) {
      _resetJobMonitorBaseline();
      _lastMonitorAlertKey = null;
    }

    _jobMonitorInFlight = true;
    try {
      final jobs = await _repository.getMyJobs(current.remoteUser);
      myJobs = jobs;

      final currentJob = _findJobById(jobs, jobId);
      final wasActiveBeforeCheck = _monitorWasActive;
      final isActiveNow = currentJob?.isActive ?? false;

      final output = await _repository.getJobLog(jobId);
      if (output.trim().isNotEmpty) {
        jobLog = output;
      }

      jobMonitorLastCheckedAt = DateTime.now();

      final logErrorLine = JobMonitorSignals.findErrorLine(jobLog);
      if (currentJob != null && currentJob.hasErrorState) {
        _publishJobMonitorAlert(
          key: 'state-error:$jobId:${currentJob.state}',
          type: JobMonitorAlertType.error,
          jobId: jobId,
          title: 'Job $jobId com erro',
          message: 'Estado atual: ${currentJob.state}.',
        );
      } else if (logErrorLine != null) {
        _publishJobMonitorAlert(
          key: 'log-error:$jobId:$logErrorLine',
          type: JobMonitorAlertType.error,
          jobId: jobId,
          title: 'Possivel erro no job $jobId',
          message: logErrorLine,
        );
      } else if (wasActiveBeforeCheck && !isActiveNow) {
        _publishJobMonitorAlert(
          key: 'stopped:$jobId:${currentJob?.state ?? 'missing'}',
          type: JobMonitorAlertType.stopped,
          jobId: jobId,
          title: 'Job $jobId parou',
          message: currentJob == null
              ? 'O job saiu da fila do Slurm.'
              : 'Estado atual: ${currentJob.state}.',
        );
      }

      _monitorWasActive = isActiveNow;
      errorMessage = null;
    } on AppException catch (error) {
      errorMessage = error.toString();
      _publishJobMonitorAlert(
        key: 'monitor-app-error:$jobId:${error.runtimeType}',
        type: JobMonitorAlertType.error,
        jobId: jobId,
        title: 'Falha ao monitorar job $jobId',
        message: error.toString(),
      );
    } catch (error) {
      errorMessage = 'Algo deu errado ao monitorar o job.\n$error';
      _publishJobMonitorAlert(
        key: 'monitor-error:$jobId:${error.runtimeType}',
        type: JobMonitorAlertType.error,
        jobId: jobId,
        title: 'Falha ao monitorar job $jobId',
        message: '$error',
      );
    } finally {
      _jobMonitorInFlight = false;
      notifyListeners();
    }
  }

  void _publishJobMonitorAlert({
    required String key,
    required JobMonitorAlertType type,
    required String jobId,
    required String title,
    required String message,
  }) {
    if (_lastMonitorAlertKey == key) {
      return;
    }
    _lastMonitorAlertKey = key;
    jobMonitorAlert = JobMonitorAlert(
      id: '${DateTime.now().microsecondsSinceEpoch}:$key',
      type: type,
      jobId: jobId,
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );
    bannerMessage = message;
  }

  JobInfo? _findJobById(List<JobInfo> jobs, String jobId) {
    for (final job in jobs) {
      if (job.jobId == jobId) {
        return job;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _logTimer?.cancel();
    _jobMonitorTimer?.cancel();
    _repository.disconnect();
    super.dispose();
  }
}
