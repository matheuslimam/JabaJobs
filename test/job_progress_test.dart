import 'package:jaba_jobs/models/job_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses classic tqdm percent and counters', () {
    final progress = JobProgress.fromLog(
      'Epoch 1\n'
      ' 42%|####2     | 42/100 [00:12<00:18,  3.10it/s]\n',
    );

    expect(progress, isNotNull);
    expect(progress!.percent, 42);
    expect(progress.current, 42);
    expect(progress.total, 100);
    expect(progress.remaining, '00:18');
  });

  test('parses progress from counters when percent is missing', () {
    final progress = JobProgress.fromLog('batch 5/20 loss=0.41');

    expect(progress, isNotNull);
    expect(progress!.percent, 25);
  });
}
