import '../models/event.dart';

class ScoreMetrics {
  const ScoreMetrics({
    required this.accuracyImmediate,
    required this.avgLatencyMs,
    required this.scoreNorm,
    required this.accuracyDelayed,
    required this.retention,
  });

  final double accuracyImmediate;
  final double avgLatencyMs;
  final double scoreNorm;
  final double accuracyDelayed;
  final double retention;
}

class ScoreCalculator {
  static ScoreMetrics computeFromEvents({
    required List<TrainingEvent> immediate,
    required List<TrainingEvent> delayed,
  }) {
    if (immediate.isEmpty) {
      return const ScoreMetrics(
        accuracyImmediate: 0,
        avgLatencyMs: 0,
        scoreNorm: 0,
        accuracyDelayed: 0,
        retention: 0,
      );
    }
    final totalI = immediate.length;
    var correctI = 0;
    for (final e in immediate) {
      if (e.errorType == null) correctI++;
    }
    final accI = correctI / totalI;
    var sumL = 0;
    for (final e in immediate) {
      sumL += (e.latencyMs ?? 0);
    }
    var avgL = totalI == 0 ? 0.0 : sumL / totalI;
    if (avgL < 1) {
      avgL = 1;
    }
    final raw = accI * (1000.0 / avgL);
    final sn = raw > 1.0 ? 1.0 : raw;

    final totalD = delayed.length;
    if (totalD == 0) {
      return ScoreMetrics(
        accuracyImmediate: accI,
        avgLatencyMs: avgL,
        scoreNorm: sn,
        accuracyDelayed: 0,
        retention: 0,
      );
    }
    var correctD = 0;
    for (final e in delayed) {
      if (e.errorType == null) correctD++;
    }
    final accD = correctD / totalD;
    final ret = accI <= 0 ? 0.0 : accD / accI;
    return ScoreMetrics(
      accuracyImmediate: accI,
      avgLatencyMs: avgL,
      scoreNorm: sn,
      accuracyDelayed: accD,
      retention: ret,
    );
  }
}
