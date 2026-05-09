import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/admin_snapshot.dart';
import '../models/connection_profile.dart';
import '../models/job_info.dart';
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
  bool isBusy = false;
  bool autoRefresh = false;
  bool followLog = false;

  Timer? _refreshTimer;
  Timer? _logTimer;
  bool _logRefreshInFlight = false;

  bool get isConnected => session != null && _repository.isConnected;
  bool get isAdmin => session?.isAdmin ?? false;
  JobInfo? get selectedJob {
    final id = selectedJobId;
    if (id == null) {
      return null;
    }
    for (final job in myJobs) {
      if (job.jobId == id) {
        return job;
      }
    }
    return null;
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

  void clearMessages() {
    bannerMessage = null;
    errorMessage = null;
    notifyListeners();
  }

  void disconnect() {
    _refreshTimer?.cancel();
    _logTimer?.cancel();
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
    selectedJobId = null;
    autoRefresh = false;
    followLog = false;
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _logTimer?.cancel();
    _repository.disconnect();
    super.dispose();
  }
}
