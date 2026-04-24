import 'dart:math' as math;

String newTrainingSessionId() {
  final t = DateTime.now().toUtc();
  return 'sess_${t.millisecondsSinceEpoch}_${math.Random().nextInt(1 << 20)}';
}
