/// Fila de `metrics/daily.csv` (export al final de cada sesión).
class DailyMetricRow {
  const DailyMetricRow({
    required this.dateUtc,
    required this.sessionId,
    required this.modality,
    required this.scoreNorm,
    required this.accImmediate,
    required this.accDelayed,
    required this.retention,
  });

  final String dateUtc;
  final String sessionId;
  final String modality;
  final double scoreNorm;
  final double accImmediate;
  final double accDelayed;
  final double retention;
}
