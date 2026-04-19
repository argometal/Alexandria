import 'package:sqlite3/sqlite3.dart';

import '../library_build.dart';

/// Progreso por problema (persistido en `lb_go_problem_progress`).
class GoProblemProgressRow {
  GoProblemProgressRow({
    required this.problemId,
    required this.attempts,
    required this.successCount,
    required this.mastered,
    this.lastPlayedAt,
  });

  final String problemId;
  final int attempts;
  final int successCount;
  final int mastered;
  final String? lastPlayedAt;
}

/// Carga mapa id → fila (solo ids que existen en BD).
Map<String, GoProblemProgressRow> goLoadProblemProgress(Database db) {
  ensureLibrarySchema(db);
  final rows = db.select(
    'SELECT problem_id, attempts, success_count, mastered, last_played_at FROM lb_go_problem_progress',
  );
  final out = <String, GoProblemProgressRow>{};
  for (final r in rows) {
    final id = r['problem_id']! as String;
    out[id] = GoProblemProgressRow(
      problemId: id,
      attempts: (r['attempts'] as num?)?.toInt() ?? 0,
      successCount: (r['success_count'] as num?)?.toInt() ?? 0,
      mastered: (r['mastered'] as num?)?.toInt() ?? 0,
      lastPlayedAt: r['last_played_at'] as String?,
    );
  }
  return out;
}

/// Registra un intento. [solved] = jugada correcta en modo problema.
void goRecordProblemAttempt(
  Database db, {
  required String problemId,
  required bool solved,
}) {
  ensureLibrarySchema(db);
  final now = DateTime.now().toUtc().toIso8601String();
  final existing = db.select(
    'SELECT attempts, success_count, mastered FROM lb_go_problem_progress WHERE problem_id = ?',
    [problemId],
  );
  var attempts = 1;
  var successCount = solved ? 1 : 0;
  var mastered = 0;
  if (existing.isNotEmpty) {
    final e = existing.first;
    attempts = (e['attempts'] as num).toInt() + 1;
    successCount = (e['success_count'] as num).toInt() + (solved ? 1 : 0);
    mastered = (e['mastered'] as num).toInt();
  }
  if (successCount >= 3) {
    mastered = 1;
  }
  db.execute(
    '''
    INSERT INTO lb_go_problem_progress (problem_id, attempts, success_count, last_played_at, mastered)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(problem_id) DO UPDATE SET
      attempts = excluded.attempts,
      success_count = excluded.success_count,
      last_played_at = excluded.last_played_at,
      mastered = CASE
        WHEN excluded.success_count >= 3 THEN 1
        ELSE lb_go_problem_progress.mastered
      END
    ''',
    [problemId, attempts, successCount, now, mastered],
  );
}
