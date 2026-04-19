import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:sqlite3/sqlite3.dart';

import 'alexandria_paths.dart';
import 'l10n/app_localizations.dart';
import 'fts_object_search.dart';
import 'study/study_utils.dart' show countEvaluableBlocks, isRealmActiveLocus;

// --- Fibonacci (días), mismo eje que locus_review_metrics ---------------------------------

const List<int> kParcourFibDays = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233];

int _fibDaysAtIndex(int i) {
  if (i < 0) return kParcourFibDays[0];
  if (i >= kParcourFibDays.length) return kParcourFibDays.last;
  return kParcourFibDays[i];
}

int _maxFibIndex() => kParcourFibDays.length - 1;

int _asInt(Object? v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _parseIso(Object? v) {
  final s = v?.toString().trim() ?? '';
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

// --- Público: rating canónico -------------------------------------------------------------

enum LocusRatingKind { good, medium, fail }

String locusRatingLabel(LocusRatingKind k) => switch (k) {
      LocusRatingKind.good => 'good',
      LocusRatingKind.medium => 'medium',
      LocusRatingKind.fail => 'fail',
    };

double locusRatingValue(LocusRatingKind k) => switch (k) {
      LocusRatingKind.good => 1.0,
      LocusRatingKind.medium => 0.5,
      LocusRatingKind.fail => 0.0,
    };

LocusRatingKind? parseLocusRatingLabel(String? raw) {
  final t = raw?.toLowerCase().trim() ?? '';
  return switch (t) {
    'good' => LocusRatingKind.good,
    'medium' => LocusRatingKind.medium,
    'fail' => LocusRatingKind.fail,
    _ => null,
  };
}

/// `n = 0` → sin evaluación (no modificar estado).
({double raw, double norm, bool pass}) computeCanonicalParcourScores(
  List<LocusRatingKind> ratings,
) {
  if (ratings.isEmpty) {
    return (raw: 0, norm: 0, pass: false);
  }
  var raw = 0.0;
  for (final r in ratings) {
    raw += locusRatingValue(r);
  }
  final n = ratings.length;
  final norm = raw / n;
  return (raw: raw, norm: norm, pass: norm >= currentParcourPassNormSync());
}

// --- Schema -----------------------------------------------------------------------------

void ensureParcourReviewSchema(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS parcour_review_state (
      parcour_key TEXT PRIMARY KEY,
      fib_index INTEGER NOT NULL DEFAULT 0,
      last_ok_at TEXT,
      next_due_at TEXT NOT NULL DEFAULT '1970-01-01',
      last_score_raw REAL,
      last_score_norm REAL,
      evaluated_count INTEGER,
      last_approved_fib INTEGER,
      last_session_at TEXT,
      stable_at TEXT
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS parcour_review_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parcour_key TEXT NOT NULL,
      session_at TEXT NOT NULL,
      score_raw REAL NOT NULL,
      score_norm REAL NOT NULL,
      evaluated_count INTEGER NOT NULL,
      passed INTEGER NOT NULL,
      fib_before INTEGER NOT NULL,
      fib_after INTEGER NOT NULL,
      due_after TEXT NOT NULL
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS parcour_review_session_loci (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      locus_key TEXT NOT NULL,
      result TEXT NOT NULL,
      value REAL NOT NULL,
      was_reviewed INTEGER NOT NULL DEFAULT 1
    )
  ''');

  db.execute(
    'CREATE INDEX IF NOT EXISTS idx_parcour_sessions_key_time ON parcour_review_sessions(parcour_key, session_at)',
  );
  db.execute(
    'CREATE INDEX IF NOT EXISTS idx_parcour_session_loci_session ON parcour_review_session_loci(session_id)',
  );
}

// --- Aplicar sesión ---------------------------------------------------------------------

class ParcourLocusEval {
  ParcourLocusEval({
    required this.locusKey,
    required this.rating,
    this.wasReviewed = true,
  });

  final String locusKey;
  final LocusRatingKind rating;
  final bool wasReviewed;
}

/// Umbral atleta: sesión aprobada solo con norma plena (100%).
const double kParcourPassNormAthlete = 1.0;

/// Umbral estándar (histórico ~80%).
const double kParcourPassNormStandard = 0.8;

/// Fail fuerte (solo rama estable) ≤ 0.3.
const double kParcourStrongFailNorm = 0.3;

/// Lee `bridge/memory_athlete_mode.txt` del realm activo (`1` = atleta 100%, `0` = estándar 80%).
double currentParcourPassNormSync() {
  try {
    final f = File(AlexandriaPaths.memoryAthleteModePath);
    if (!f.existsSync()) return kParcourPassNormAthlete;
    final t = f.readAsStringSync().trim().toLowerCase();
    if (t == '0' ||
        t == 'false' ||
        t == 'no' ||
        t == 'off' ||
        t == 'normal' ||
        t == 'standard') {
      return kParcourPassNormStandard;
    }
    return kParcourPassNormAthlete;
  } catch (_) {
    return kParcourPassNormAthlete;
  }
}

int _bootstrapTargetFib(double scoreNorm) {
  final t = (scoreNorm * 10.0).floor();
  return math.min(math.max(t, 0), 8);
}

/// Registra sesión de parcour, actualiza estado y traza oficial. Si [evals] queda vacío tras
/// filtrar no evaluables, no hace nada (n = 0).
void applyParcourReviewSession({
  required Database db,
  required String parcourKey,
  required List<ParcourLocusEval> evals,
  required DateTime now,
}) {
  ensureParcourReviewSchema(db);

  final ratings = <LocusRatingKind>[];
  final filtered = <ParcourLocusEval>[];
  for (final e in evals) {
    ratings.add(e.rating);
    filtered.add(e);
  }

  if (ratings.isEmpty) {
    return;
  }

  final canon = computeCanonicalParcourScores(ratings);
  final raw = canon.raw;
  final norm = canon.norm;
  final pass = canon.pass;
  final n = ratings.length;
  final strongFail = norm <= kParcourStrongFailNorm;

  final stateRows = db.select(
    'SELECT fib_index, last_approved_fib, stable_at FROM parcour_review_state WHERE parcour_key = ?',
    [parcourKey],
  );

  final fibBefore = stateRows.isEmpty ? 0 : _asInt(stateRows.first['fib_index']);
  final lastApprovedRaw = stateRows.isEmpty
      ? null
      : stateRows.first['last_approved_fib'];
  final lastApprovedExisting = lastApprovedRaw == null
      ? null
      : _asInt(lastApprovedRaw, -1);
  final lastApproved =
      (lastApprovedExisting != null && lastApprovedExisting >= 0)
          ? lastApprovedExisting
          : null;

  final stableAtExisting = stateRows.isEmpty
      ? null
      : stateRows.first['stable_at']?.toString();

  var newFib = fibBefore;
  String? stableAtOut = stableAtExisting;
  int? lastApprovedOut;

  if (fibBefore < 8) {
    newFib = _bootstrapTargetFib(norm);
    final hadStable =
        stableAtOut != null && stableAtOut.trim().isNotEmpty;
    if (newFib >= 8 && !hadStable) {
      stableAtOut = now.toIso8601String();
      lastApprovedOut = 8;
    }
  } else {
    if (pass) {
      newFib = math.min(fibBefore + 1, _maxFibIndex());
      lastApprovedOut = newFib;
    } else if (strongFail) {
      final revert = lastApproved ?? 8;
      newFib = math.min(math.max(revert, 0), _maxFibIndex());
    } else {
      newFib = math.max(fibBefore - 1, 0);
    }
  }

  final lastOkAtOut = pass ? now.toIso8601String() : null;

  final lastApprovedForDb = lastApprovedOut ?? lastApproved;

  final intervalDays = _fibDaysAtIndex(newFib);
  final nextDue = now.add(Duration(days: intervalDays));

  db.execute('BEGIN');
  try {
    db.execute('''
      INSERT INTO parcour_review_state (
        parcour_key, fib_index, last_ok_at, next_due_at,
        last_score_raw, last_score_norm, evaluated_count, last_approved_fib, last_session_at, stable_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(parcour_key) DO UPDATE SET
        fib_index = excluded.fib_index,
        last_ok_at = excluded.last_ok_at,
        next_due_at = excluded.next_due_at,
        last_score_raw = excluded.last_score_raw,
        last_score_norm = excluded.last_score_norm,
        evaluated_count = excluded.evaluated_count,
        last_approved_fib = COALESCE(excluded.last_approved_fib, parcour_review_state.last_approved_fib),
        last_session_at = excluded.last_session_at,
        stable_at = COALESCE(parcour_review_state.stable_at, excluded.stable_at)
    ''', [
      parcourKey,
      newFib,
      lastOkAtOut,
      nextDue.toIso8601String(),
      raw,
      norm,
      n,
      lastApprovedForDb,
      now.toIso8601String(),
      stableAtOut,
    ]);

    db.execute('''
      INSERT INTO parcour_review_sessions (
        parcour_key, session_at, score_raw, score_norm, evaluated_count,
        passed, fib_before, fib_after, due_after
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      parcourKey,
      now.toIso8601String(),
      raw,
      norm,
      n,
      pass ? 1 : 0,
      fibBefore,
      newFib,
      nextDue.toIso8601String(),
    ]);

    final idRow = db.select('SELECT last_insert_rowid() AS id');
    final sessionId = _asInt(idRow.first['id']);

    for (final e in filtered) {
      final lbl = locusRatingLabel(e.rating);
      final val = locusRatingValue(e.rating);
      db.execute('''
        INSERT INTO parcour_review_session_loci (
          session_id, locus_key, result, value, was_reviewed
        ) VALUES (?, ?, ?, ?, ?)
      ''', [
        sessionId,
        e.locusKey,
        lbl,
        val,
        e.wasReviewed ? 1 : 0,
      ]);
    }

    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK');
    rethrow;
  }
}

// --- Eligibilidad -----------------------------------------------------------------------

/// Locus no vacío y con al menos un bloque evaluable (hint / place / ridiculous_story).
bool isLocusEligibleForParcourReview(String? bodyText) {
  return countEvaluableBlocks(bodyText) > 0;
}

// --- Resumen UI / GK --------------------------------------------------------------------

class ParcourReviewUiSummary {
  ParcourReviewUiSummary({
    required this.parcourKey,
    this.fibIndex = 0,
    this.nextDueAt,
    this.lastOkAt,
    this.stableAt,
    this.lastScoreNorm,
    this.lastScoreRaw,
    this.evaluatedCount = 0,
    this.lastSessionAt,
    this.lastPass,
    this.goodCount = 0,
    this.mediumCount = 0,
    this.failCount = 0,
    this.goodLoci = const [],
    this.mediumLoci = const [],
    this.failedLoci = const [],
    this.sessionPct,
  });

  final String parcourKey;
  final int fibIndex;
  final DateTime? nextDueAt;
  final DateTime? lastOkAt;
  final DateTime? stableAt;
  final double? lastScoreNorm;
  final double? lastScoreRaw;
  final int evaluatedCount;
  final DateTime? lastSessionAt;
  final bool? lastPass;
  final int goodCount;
  final int mediumCount;
  final int failCount;
  final List<String> goodLoci;
  final List<String> mediumLoci;
  final List<String> failedLoci;
  final double? sessionPct;

  double? get sessionPercent {
    if (sessionPct != null) return sessionPct;
    if (lastScoreNorm != null) return lastScoreNorm! * 100.0;
    return null;
  }
}

/// Última sesión registrada + estado actual (por KEY).
ParcourReviewUiSummary loadParcourReviewSummary(
  Database db,
  String parcourKey,
) {
  ensureParcourReviewSchema(db);

  final st = db.select(
    '''
    SELECT fib_index, last_ok_at, next_due_at, last_score_raw, last_score_norm,
           evaluated_count, last_session_at, stable_at
    FROM parcour_review_state WHERE parcour_key = ?
    ''',
    [parcourKey],
  );

  int fib = 0;
  DateTime? nextDue;
  DateTime? lastOk;
  DateTime? stableAt;
  double? lsn;
  double? lsr;
  int evc = 0;
  DateTime? lastSess;

  if (st.isNotEmpty) {
    final r = st.first;
    fib = _asInt(r['fib_index']);
    lastOk = _parseIso(r['last_ok_at']);
    nextDue = _parseIso(r['next_due_at']);
    stableAt = _parseIso(r['stable_at']);
    lsn = _asDouble(r['last_score_norm']);
    lsr = _asDouble(r['last_score_raw']);
    evc = _asInt(r['evaluated_count']);
    lastSess = _parseIso(r['last_session_at']);
  }

  final sess = db.select('''
    SELECT id, passed, score_norm FROM parcour_review_sessions
    WHERE parcour_key = ? ORDER BY id DESC LIMIT 1
  ''', [parcourKey]);

  bool? lastPass;
  var goodC = 0;
  var medC = 0;
  var failC = 0;
  final goodL = <String>[];
  final medL = <String>[];
  final failL = <String>[];

  if (sess.isNotEmpty) {
    lastPass = (_asInt(sess.first['passed'])) != 0;
    final sid = _asInt(sess.first['id']);
    final loci = db.select('''
      SELECT locus_key, result FROM parcour_review_session_loci
      WHERE session_id = ? ORDER BY locus_key ASC
    ''', [sid]);
    for (final row in loci) {
      final lk = row['locus_key'] as String;
      final res = row['result']?.toString().toLowerCase() ?? '';
      if (res == 'good') {
        goodC++;
        goodL.add(lk);
      } else if (res == 'medium') {
        medC++;
        medL.add(lk);
      } else if (res == 'fail') {
        failC++;
        failL.add(lk);
      }
    }
  }

  return ParcourReviewUiSummary(
    parcourKey: parcourKey,
    fibIndex: fib,
    nextDueAt: nextDue,
    lastOkAt: lastOk,
    stableAt: stableAt,
    lastScoreNorm: lsn,
    lastScoreRaw: lsr,
    evaluatedCount: evc,
    lastSessionAt: lastSess,
    lastPass: lastPass,
    goodCount: goodC,
    mediumCount: medC,
    failCount: failC,
    goodLoci: goodL,
    mediumLoci: medL,
    failedLoci: failL,
    sessionPct: lsn != null ? lsn * 100.0 : null,
  );
}

/// Parcour due copy: no calendar dates, no hour pressure — only **due** vs **in N days**
/// (whole calendar days). Same calendar day as today counts as due. Next interval still
/// comes from the last session result in [applyParcourReviewSession].
String formatParcourDueSoft(
  DateTime? nextDue,
  AppLocalizations l, [
  DateTime? now,
]) {
  final n = now ?? DateTime.now();
  if (nextDue == null) return l.parcourFibDueDash;
  if (!nextDue.isAfter(n)) return l.parcourFibDueReady;
  final startToday = DateTime(n.year, n.month, n.day);
  final startDue = DateTime(nextDue.year, nextDue.month, nextDue.day);
  final calendarDays = startDue.difference(startToday).inDays;
  if (calendarDays <= 0) return l.parcourFibDueReady;
  return l.parcourFibDueInDaysCount(calendarDays);
}

String formatParcourReviewOneLine(
  ParcourReviewUiSummary s,
  AppLocalizations l, [
  DateTime? now,
]) {
  final n = now ?? DateTime.now();
  final dueStr = formatParcourDueSoft(s.nextDueAt, l, n);
  final scoreStr = s.lastScoreNorm == null
      ? l.parcourFibScoreDash
      : l.parcourFibScoreValue(s.lastScoreNorm!.toStringAsFixed(2));
  return l.parcourFibFullLine(s.fibIndex, dueStr, scoreStr);
}

// --- Realm completitud (ORM-16-04): hijos directos, ridiculous_story, último good por sesión ---

/// Resultado de [computeRealmCompletionForParcour]. Si [isNA] es true, [percent] es null (mostrar N/A, no 0%).
class RealmCompletionResult {
  const RealmCompletionResult({
    required this.isNA,
    required this.realmActiveCount,
    required this.goodCount,
    this.percent,
  });

  final bool isNA;
  final int realmActiveCount;
  final int goodCount;
  final double? percent;
}

/// Último resultado Parcour Review por `locus_key` (sesiones de [parcourKey], orden reciente).
Map<String, String> latestParcourRatingByLocus(
  Database db,
  String parcourKey,
) {
  ensureParcourReviewSchema(db);
  final rows = db.select('''
    SELECT sl.locus_key AS lk, sl.result AS r, s.id AS sid
    FROM parcour_review_session_loci sl
    INNER JOIN parcour_review_sessions s ON s.id = sl.session_id
    WHERE s.parcour_key = ?
    ORDER BY s.id DESC
  ''', [parcourKey]);
  final latestResultByLocus = <String, String>{};
  for (final row in rows) {
    final lk = row['lk'] as String;
    if (latestResultByLocus.containsKey(lk)) continue;
    latestResultByLocus[lk] = row['r']?.toString().toLowerCase().trim() ?? '';
  }
  return latestResultByLocus;
}

/// Completitud realm: solo **hijos directos** del parcour. Activo = [isRealmActiveLocus].
/// **Good** = último resultado Parcour Review por locus en sesiones de este parcour (`good`).
/// Sin sesiones en este parcour, o sin ningún locus activo realm → [RealmCompletionResult.isNA].
RealmCompletionResult computeRealmCompletionForParcour(
  Database db,
  String parcourKey,
) {
  ensureParcourReviewSchema(db);

  final nSessRows = db.select(
    'SELECT COUNT(*) AS c FROM parcour_review_sessions WHERE parcour_key = ?',
    [parcourKey],
  );
  final sessionCount =
      nSessRows.isEmpty ? 0 : _asInt(nSessRows.first['c'], 0);

  final latestResultByLocus = sessionCount > 0
      ? latestParcourRatingByLocus(db, parcourKey)
      : <String, String>{};

  final objects = db.select(
    "SELECT key, body_text FROM entries WHERE parentKey = ? AND cognitiveRole = 'object' ORDER BY seq ASC",
    [parcourKey],
  );

  var active = 0;
  var good = 0;
  for (final row in objects) {
    final key = row['key'] as String;
    final body = row['body_text'] as String?;
    if (!isRealmActiveLocus(body)) continue;
    active++;
    final res = latestResultByLocus[key];
    if (res == 'good') good++;
  }

  if (sessionCount == 0 || active == 0) {
    return RealmCompletionResult(
      isNA: true,
      realmActiveCount: active,
      goodCount: good,
      percent: null,
    );
  }

  return RealmCompletionResult(
    isNA: false,
    realmActiveCount: active,
    goodCount: good,
    percent: active > 0 ? good / active : null,
  );
}

// --- Selector due → active → seek → core ------------------------------------------------

const String kParcourHubKey = 'PARCOUR_MAIN';

/// Hijos directos `parcour` bajo el hub ORM (p. ej. L1…L20).
List<String> listHubParcourKeys(Database db) {
  final rows = db.select(
    'SELECT key FROM entries WHERE parentKey = ? AND cognitiveRole = ? ORDER BY seq ASC, key ASC',
    [kParcourHubKey, 'parcour'],
  );
  return rows.map((r) => r['key'] as String).toList();
}

double _subtreeObjectUsageSum(Database db, String rootKey) {
  final rows = db.select('''
    WITH RECURSIVE subtree(key) AS (
      SELECT ?1
      UNION ALL
      SELECT e.key FROM entries e INNER JOIN subtree s ON e.parentKey = s.key
    )
    SELECT e.key, e.review_count, e.success_count, e.failure_count, e.recall_score,
           e.memory_strength, e.stability_days, e.last_reviewed_at
    FROM entries e
    INNER JOIN subtree st ON e.key = st.key
    WHERE e.cognitiveRole = 'object'
  ''', [rootKey]);
  var sum = 0.0;
  for (final r in rows) {
    sum += usageScoreForRow(r);
  }
  return sum;
}

enum _ParcourTier { due, active, seek, core }

class _ParcourSort {
  _ParcourSort({
    required this.key,
    required this.tier,
    required this.nextDue,
    required this.fibIndex,
    required this.lastSession,
    required this.usageSum,
  });

  final String key;
  final _ParcourTier tier;
  final DateTime? nextDue;
  final int fibIndex;
  final DateTime? lastSession;
  final double usageSum;
}

/// Orden único: due → active → seek → core (solo LB).
List<String> orderedParcourKeysForSelector(Database db) {
  ensureParcourReviewSchema(db);
  final keys = listHubParcourKeys(db);
  if (keys.isEmpty) return [];

  final now = DateTime.now();
  final usageByKey = <String, double>{};
  for (final k in keys) {
    usageByKey[k] = _subtreeObjectUsageSum(db, k);
  }
  final usages = keys.map((k) => usageByKey[k] ?? 0.0).toList()..sort();
  double? medianSeekCore;
  if (usages.isNotEmpty) {
    medianSeekCore = usages[usages.length ~/ 2];
  }

  final items = <_ParcourSort>[];

  for (final k in keys) {
    final st = db.select(
      'SELECT fib_index, next_due_at, last_session_at FROM parcour_review_state WHERE parcour_key = ?',
      [k],
    );
    final fib = st.isEmpty ? 0 : _asInt(st.first['fib_index']);
    final nd = st.isEmpty ? null : _parseIso(st.first['next_due_at']);
    final ls = st.isEmpty ? null : _parseIso(st.first['last_session_at']);
    final usage = usageByKey[k] ?? 0.0;

    final isDue = nd == null || !nd.isAfter(now);
    final recent = ls != null && now.difference(ls).inDays < 8;
    final isActive = !isDue && (fib < 8 || recent);

    _ParcourTier tier;
    if (isDue) {
      tier = _ParcourTier.due;
    } else if (isActive) {
      tier = _ParcourTier.active;
    } else {
      tier = (medianSeekCore != null && usage <= medianSeekCore)
          ? _ParcourTier.seek
          : _ParcourTier.core;
    }

    items.add(
      _ParcourSort(
        key: k,
        tier: tier,
        nextDue: nd,
        fibIndex: fib,
        lastSession: ls,
        usageSum: usage,
      ),
    );
  }

  int tierOrder(_ParcourTier t) => switch (t) {
        _ParcourTier.due => 0,
        _ParcourTier.active => 1,
        _ParcourTier.seek => 2,
        _ParcourTier.core => 3,
      };

  items.sort((a, b) {
    final c = tierOrder(a.tier).compareTo(tierOrder(b.tier));
    if (c != 0) return c;
    if (a.tier == _ParcourTier.due) {
      final ad = a.nextDue ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.nextDue ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ad.compareTo(bd);
    }
    if (a.tier == _ParcourTier.active) {
      final cf = a.fibIndex.compareTo(b.fibIndex);
      if (cf != 0) return cf;
      final at = a.lastSession ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.lastSession ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    }
    if (a.tier == _ParcourTier.seek) {
      return a.usageSum.compareTo(b.usageSum);
    }
    return b.usageSum.compareTo(a.usageSum);
  });

  return items.map((e) => e.key).toList();
}

// --- Bridge JSON (GK solo lectura) ------------------------------------------------------

/// `data/realms/<realm>/bridge/parcour_review_summary.json`
void writeParcourReviewBridgeSummary(Database db) {
  ensureParcourReviewSchema(db);
  final keys = listHubParcourKeys(db);
  final parcours = <String, dynamic>{};

  for (final k in keys) {
    final s = loadParcourReviewSummary(db, k);
    parcours[k] = {
      'parcourKey': k,
      'fibIndex': s.fibIndex,
      'nextDueAt': s.nextDueAt?.toIso8601String(),
      'lastOkAt': s.lastOkAt?.toIso8601String(),
      'stableAt': s.stableAt?.toIso8601String(),
      'lastScoreNorm': s.lastScoreNorm,
      'lastScoreRaw': s.lastScoreRaw,
      'evaluatedCount': s.evaluatedCount,
      'lastSessionAt': s.lastSessionAt?.toIso8601String(),
      'lastSessionPass': s.lastPass,
      'failedLoci': s.failedLoci,
      'mediumLoci': s.mediumLoci,
      'goodLoci': s.goodLoci,
      'counts': {
        'good': s.goodCount,
        'medium': s.mediumCount,
        'fail': s.failCount,
      },
      'sessionPct': s.sessionPct,
    };
  }

  final payload = <String, dynamic>{
    'schemaVersion': 1,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'parcours': parcours,
  };

  final dir = Directory(AlexandriaPaths.bridgeDir);
  dir.createSync(recursive: true);
  final f = File(AlexandriaPaths.parcourReviewSummaryPath);
  f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(payload));
}
