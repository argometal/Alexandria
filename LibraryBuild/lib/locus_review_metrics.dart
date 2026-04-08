import 'dart:math' as math;

import 'package:sqlite3/sqlite3.dart';

const List<int> _fibonacci = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233];

int _asInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

/// Aplica el resultado de una sesión de estudio sobre un locus.
///
/// [pct] debe ser un valor entre 0.0 y 1.0, solo válido si [totalEvaluableBlocks] >= 3.
/// Si [totalEvaluableBlocks] < 3, la sesión se registra como INSUFFICIENT_DATA
/// y no se modifica el estado de scheduling.
void applyLocusReviewOutcome({
  required Database db,
  required String locusKey,
  required double pct,
  required int totalEvaluableBlocks,
  required DateTime now,
}) {
  if (totalEvaluableBlocks < 3) {
    db.execute('''
      INSERT INTO locus_review_events (
        locus_key, rating, pct, fib_index_before, fib_index_after, due_after, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      locusKey,
      'INSUFFICIENT_DATA',
      null,
      null,
      null,
      null,
      now.toIso8601String(),
    ]);
    return;
  }

  final pass = pct >= 0.8;

  final rows = db.select(
    'SELECT fib_index FROM locus_review_state WHERE entry_key = ?',
    [locusKey],
  );
  final currentIndex = rows.isEmpty ? 0 : _asInt(rows.first['fib_index']);

  final newIndex = pass
      ? math.min(currentIndex + 1, _fibonacci.length - 1)
      : math.max(currentIndex - 1, 0);

  final intervalDays = _fibonacci[newIndex];
  final nextDue = now.add(Duration(days: intervalDays));

  db.execute('''
    INSERT INTO locus_review_state (
      entry_key, fib_index, last_ok_at, next_due_at, last_session_pct
    ) VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(entry_key) DO UPDATE SET
      fib_index = excluded.fib_index,
      last_ok_at = excluded.last_ok_at,
      next_due_at = excluded.next_due_at,
      last_session_pct = excluded.last_session_pct
  ''', [
    locusKey,
    newIndex,
    pass ? now.toIso8601String() : null,
    nextDue.toIso8601String(),
    pct,
  ]);

  db.execute('''
    INSERT INTO locus_review_events (
      locus_key, rating, pct, fib_index_before, fib_index_after, due_after, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
  ''', [
    locusKey,
    pass ? 'PASS' : 'FAIL',
    pct,
    currentIndex,
    newIndex,
    nextDue.toIso8601String(),
    now.toIso8601String(),
  ]);
}

class LocusStats {
  final int due;
  final int newCount;
  final int total;

  LocusStats({required this.due, required this.newCount, required this.total});
}

/// Due / new (`fib_index == 0`) / total de objetos bajo [parentKey].
LocusStats getLocusStatsForParent(Database db, String parentKey) {
  final rows = db.select('''
    SELECT
      e.key,
      COALESCE(s.fib_index, 0) as fib_index,
      COALESCE(s.next_due_at, '1970-01-01') as next_due_at
    FROM entries e
    LEFT JOIN locus_review_state s ON s.entry_key = e.key
    WHERE e.parentKey = ? AND e.cognitiveRole = 'object'
  ''', [parentKey]);

  final now = DateTime.now();
  var due = 0;
  var newCount = 0;

  for (final row in rows) {
    final fib = _asInt(row['fib_index']);
    final nextDue = DateTime.parse(row['next_due_at'] as String);

    if (fib == 0) newCount++;
    if (nextDue.isBefore(now) || nextDue.isAtSameMomentAs(now)) due++;
  }

  return LocusStats(
    due: due,
    newCount: newCount,
    total: rows.length,
  );
}
