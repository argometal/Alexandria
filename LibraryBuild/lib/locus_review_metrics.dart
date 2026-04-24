import 'dart:math' as math;

import 'package:sqlite3/sqlite3.dart';

import 'fib_locale_text.dart';
import 'l10n/app_localizations.dart';
import 'parcour_review.dart'
    show currentParcourPassNormSync, kParcourFibDays;

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

  final pass = pct >= currentParcourPassNormSync();

  final rows = db.select(
    'SELECT fib_index FROM locus_review_state WHERE entry_key = ?',
    [locusKey],
  );
  final currentIndex = rows.isEmpty ? 0 : _asInt(rows.first['fib_index']);

  final newIndex = pass
      ? math.min(currentIndex + 1, kParcourFibDays.length - 1)
      : math.max(currentIndex - 1, 0);

  final intervalDays = kParcourFibDays[newIndex];
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

// --- Agregación Fibonacci / locus_review_state en subárbol (realm o parcour) ---

DateTime? _parseIsoField(Object? v) {
  final s = v?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// Resumen para barra de estado: última sesión estructurada (max `last_ok_at`) y
/// repaso más urgente (min `next_due_at`; sin fila en estado → 1970 = vencido).
class LocusScheduleSummary {
  const LocusScheduleSummary({
    this.latestLastOk,
    this.earliestNextDue,
    this.objectCount = 0,
  });

  final DateTime? latestLastOk;
  final DateTime? earliestNextDue;
  final int objectCount;
}

/// Todos los `cognitiveRole = object` bajo [rootKey] (CTE recursiva), no solo hijos directos.
LocusScheduleSummary summarizeLocusScheduleForSubtree(Database db, String rootKey) {
  final rows = db.select('''
    WITH RECURSIVE subtree(key) AS (
      SELECT ?1
      UNION ALL
      SELECT e.key FROM entries e INNER JOIN subtree s ON e.parentKey = s.key
    )
    SELECT l.last_ok_at AS last_ok_at,
           COALESCE(l.next_due_at, '1970-01-01') AS next_due_at
    FROM entries e
    INNER JOIN subtree st ON e.key = st.key
    LEFT JOIN locus_review_state l ON l.entry_key = e.key
    WHERE e.cognitiveRole = 'object'
  ''', [rootKey]);

  if (rows.isEmpty) {
    return const LocusScheduleSummary(objectCount: 0);
  }

  DateTime? maxLast;
  DateTime? minNext;
  for (final r in rows) {
    final lo = _parseIsoField(r['last_ok_at']);
    final nd = _parseIsoField(r['next_due_at']);
    if (lo != null) {
      if (maxLast == null || lo.isAfter(maxLast)) {
        maxLast = lo;
      }
    }
    if (nd != null) {
      if (minNext == null || nd.isBefore(minNext)) {
        minNext = nd;
      }
    }
  }

  return LocusScheduleSummary(
    latestLastOk: maxLast,
    earliestNextDue: minNext,
    objectCount: rows.length,
  );
}

/// Una línea para AppBar: recall separado; esto es solo **estudio estructurado** (Fibonacci).
String formatLocusScheduleSummaryLine(
  LocusScheduleSummary s,
  AppLocalizations l, [
  DateTime? now,
]) {
  final n = now ?? DateTime.now();
  if (s.objectCount == 0) {
    return l.fibScheduleEmpty;
  }
  final prev = s.latestLastOk == null
      ? '—'
      : fibFormatRelPast(s.latestLastOk!, n, l);
  final nxt = s.earliestNextDue == null
      ? '—'
      : (!s.earliestNextDue!.isAfter(n))
          ? l.fibOverdue
          : fibFormatRelFuture(s.earliestNextDue!, n, l);
  return l.fibScheduleLine(prev, nxt);
}
