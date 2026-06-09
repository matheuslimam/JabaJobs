import 'package:jaba_jobs/models/job_monitor_alert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects the latest relevant error line in logs', () {
    final line = JobMonitorSignals.findErrorLine(
      'epoch 1 ok\n'
      'Traceback (most recent call last):\n'
      'CUDA error: out of memory\n',
    );

    expect(line, 'CUDA error: out of memory');
  });

  test('ignores metric lines that mention error without failure', () {
    final line = JobMonitorSignals.findErrorLine(
      'train loss=0.20\n'
      'validation error rate=0.03\n'
      'epoch complete\n',
    );

    expect(line, isNull);
  });
}
