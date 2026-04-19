import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:sqlite3/sqlite3.dart';

import 'alexandria_paths.dart';
import 'app_locale_preferences.dart';
import 'fts_object_search.dart';
import 'parcour_review.dart';
import 'pao/pao_phonetic_store.dart';
import 'pao/pao_standard_store.dart';
import 'poker_memory/poker_memory_store.dart';

export 'locus_review_metrics.dart';
export 'study/study_utils.dart' show isRealmActiveLocus;
export 'parcour_review.dart'
    show
        applyParcourReviewSession,
        RealmCompletionResult,
        computeCanonicalParcourScores,
        computeRealmCompletionForParcour,
        ensureParcourReviewSchema,
        formatParcourDueSoft,
        formatParcourReviewOneLine,
        isLocusEligibleForParcourReview,
        kParcourFibDays,
        kParcourHubKey,
        currentParcourPassNormSync,
        kParcourPassNormAthlete,
        kParcourPassNormStandard,
        kParcourStrongFailNorm,
        latestParcourRatingByLocus,
        listHubParcourKeys,
        loadParcourReviewSummary,
        LocusRatingKind,
        locusRatingLabel,
        locusRatingValue,
        orderedParcourKeysForSelector,
        ParcourLocusEval,
        ParcourReviewUiSummary,
        writeParcourReviewBridgeSummary;
export 'fts_object_search.dart' show rebuildEntriesFts5, UsageBand;
export 'pao/pao_phonetic_store.dart'
    show
        PaoPhoneticRow,
        ensurePaoPhoneticSchema,
        loadPaoPhoneticMerged,
        upsertPaoPhonetic;
export 'pao/pao_standard_store.dart'
    show
        PaoCodeTier,
        PaoStandardRow,
        emptyPaoLibraryJsonMapV2,
        emptyPaoStandardJsonMap,
        ensurePaoStandardSchema,
        exportPaoLibraryJsonV2,
        exportPaoStandardCsv,
        exportPaoStandardJson,
        importPaoJsonAuto,
        importPaoLibraryFromJsonString,
        importPaoStandardFromJsonString,
        kPaoLibrarySchemaVersion,
        loadPaoDigitMerged,
        loadPaoStandardMerged,
        loadPaoTripleMerged,
        missingPaoJsonKeys,
        paoCodeIsValid,
        paoTierForCode,
        upsertPaoStandard;
export 'poker_memory/poker_memory_store.dart'
    show
        PokerCardRef,
        PokerNumberCardMapping,
        PokerSuitRange,
        buildPokerMappingTable,
        cardForNumber,
        ensurePokerMemorySchema,
        formatPokerCardShort,
        formatPokerNumberForDisplay,
        kPokerRanksPerSuit,
        kPokerSuitClubs,
        kPokerSuitDiamonds,
        kPokerSuitHearts,
        kPokerSuitSpades,
        loadPokerMemoryRanges,
        numberForCard,
        pokerRankChar,
        pokerSuitSymbol,
        savePokerMemoryRanges,
        validatePokerRanges;

/// [Cambio 341] Evita re-escritura de viewer si el foco (dual bridge) no cambió.
String? _lastViewerKey;

/// [Cambio 353] Último parent procesado en `runLibraryBuild` (detectar cambio de contexto).
String _lastBridgeParentKey = '';

const _realmKey = 'ROOT';
const _primaryParcourKey = 'PARCOUR_MAIN';

/// Valores de `textKind` válidos en bloques `p` (locus_editor / viewer GK).
const Set<String> kAllowedTextKinds = {
  'text',
  'hint',
  'place',
  'ridiculous_story',
};

/// Normaliza `textKind` al guardar o al parsear JSON de bloques.
String normalizeTextKind(String? raw) {
  final k = raw?.toLowerCase().trim() ?? '';
  if (k.isEmpty || !kAllowedTextKinds.contains(k)) return 'text';
  return k;
}

/// Contrato `data/navigation/by-parent/<stem>.json`: nombres de archivo seguros en Windows.
String navigationFileStem(String parentKey) {
  if (parentKey.isEmpty) return '_empty';
  return parentKey.replaceAll(r'\', '_').replaceAll('/', '_');
}

String _navExportLabel(String key, Object? titleRaw) {
  final t = titleRaw?.toString().trim();
  if (t != null && t.isNotEmpty) return t;
  if (key == _realmKey) return 'R1';
  if (key == _primaryParcourKey) return 'Parcours (R1)';
  return key;
}

/// Regenera `data/navigation/` desde SQLite por reemplazo atómico (tmp → rename).
void _exportNavigationBundleAtomically(Database db) {
  final navTmpRoot = AlexandriaPaths.navigationTmpRoot;
  final navFinalRoot = AlexandriaPaths.navigationRoot;
  final tmp = Directory(navTmpRoot);
  try {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
    tmp.createSync(recursive: true);
    final byParent = Directory('$navTmpRoot/by-parent');
    byParent.createSync(recursive: true);

    final rootRows = db.select(
      'SELECT key FROM entries WHERE parentKey IS NULL OR TRIM(COALESCE(parentKey, \'\')) = \'\' ORDER BY seq ASC, key ASC',
    );
    final rootKeys = rootRows.map((r) => r['key'] as String).toList();

    final parentRows = db.select(
      'SELECT DISTINCT parentKey FROM entries WHERE parentKey IS NOT NULL AND TRIM(parentKey) != \'\'',
    );
    final parentKeys = parentRows.map((r) => r['parentKey'] as String).toSet().toList()
      ..sort();

    final now = DateTime.now().toUtc().toIso8601String();
    final manifest = <String, dynamic>{
      'schemaVersion': 1,
      'generatedAt': now,
      'rootKeys': rootKeys,
    };
    File('$navTmpRoot/manifest.json').writeAsStringSync(
      jsonEncode(manifest),
    );

    for (final pk in parentKeys) {
      final kids = db.select(
        'SELECT key, seq, title, cognitiveRole FROM entries WHERE parentKey = ? ORDER BY seq ASC, key ASC',
        [pk],
      );
      if (kids.isEmpty) continue;
      final children = <Map<String, dynamic>>[];
      for (final row in kids) {
        final k = row['key'] as String;
        children.add({
          'key': k,
          'type': normalizeCognitiveRole(row['cognitiveRole']),
          'label': _navExportLabel(k, row['title']),
        });
      }
      final payload = <String, dynamic>{
        'parentKey': pk,
        'children': children,
      };
      final stem = navigationFileStem(pk);
      File('${byParent.path}${Platform.pathSeparator}$stem.json').writeAsStringSync(
        jsonEncode(payload),
      );
    }

    final finalDir = Directory(navFinalRoot);
    if (finalDir.existsSync()) {
      finalDir.deleteSync(recursive: true);
    }
    tmp.renameSync(navFinalRoot);
    print('[LB][NAVIGATION] $navFinalRoot (parents=${parentKeys.length})');
  } catch (e, st) {
    print('[LB][NAVIGATION_ERR] $e\n$st');
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
    rethrow;
  }
}

/// Fase 3 ORM-15V3: asegura `context_key.txt` y `focus_key.txt` sin leer `open_key.txt`.
/// Si falta context → `ROOT`; si falta focus → archivo vacío.
void ensureDualBridgeDefaults() {
  try {
    final ctx = File(AlexandriaPaths.contextKeyPath);
    ctx.parent.createSync(recursive: true);
    if (!ctx.existsSync()) {
      ctx.writeAsStringSync('ROOT');
      print('[LB][NO_CONTEXT_KEY] context_key.txt ausente → creado ROOT');
    } else {
      final t = ctx.readAsStringSync().trim();
      if (t.isEmpty) {
        ctx.writeAsStringSync('ROOT');
        print('[LB][NO_CONTEXT_KEY] context_key vacío → ROOT');
      }
    }
    final foc = File(AlexandriaPaths.focusKeyPath);
    if (!foc.existsSync()) {
      foc.writeAsStringSync('');
      print('[LB][BRIDGE_DEFAULT] focus_key.txt creado vacío');
    }
    final intent = File(AlexandriaPaths.navigationIntentPath);
    if (!intent.existsSync()) {
      intent.writeAsStringSync('explore');
      print('[LB][BRIDGE_DEFAULT] navigation_intent.txt → explore');
    }
    final placeRecall = File(AlexandriaPaths.placeRecallEnabledPath);
    if (!placeRecall.existsSync()) {
      placeRecall.writeAsStringSync('0');
      print('[LB][BRIDGE_DEFAULT] place_recall_enabled.txt → 0');
    }
    final memAth = File(AlexandriaPaths.memoryAthleteModePath);
    if (!memAth.existsSync()) {
      memAth.writeAsStringSync('1');
      print('[LB][BRIDGE_DEFAULT] memory_athlete_mode.txt → 1');
    }
    final gkLang = File(AlexandriaPaths.gkUiLangPath);
    if (!gkLang.existsSync()) {
      gkLang.writeAsStringSync('en\n');
      print('[LB][BRIDGE_DEFAULT] gk_ui_lang.txt → en');
    }
  } catch (e) {
    print('[LB][BRIDGE_DEFAULT_ERR] $e');
  }
}

/// Syncs GateKeeper UI language (`bridge/gk_ui_lang.txt`) with Library Build preference.
/// Values: `en`, `es`, `pt`. `null` or empty saved preference → `en` (default English for GK).
void writeGkUiLangBridge(String? languageCode) {
  try {
    final f = File(AlexandriaPaths.gkUiLangPath);
    f.parent.createSync(recursive: true);
    String normalized;
    if (languageCode == null || languageCode.isEmpty) {
      normalized = 'en';
    } else {
      final two = languageCode.length >= 2
          ? languageCode.toLowerCase().substring(0, 2)
          : 'en';
      normalized = (two == 'es' || two == 'pt') ? two : 'en';
    }
    f.writeAsStringSync('$normalized\n');
  } catch (e) {
    print('[LB][GK_UI_LANG_ERR] $e');
  }
}

/// Writes [gk_ui_lang.txt] from saved app locale (e.g. after realm switch or startup).
Future<void> syncGkUiLangBridgeFromPreference() async {
  final code = await AppLocalePreferences.loadSavedLanguageCode();
  writeGkUiLangBridge(code);
}

/// Solo `context_key.txt`. Sin `open_key`. Ausente o vacío → lógica `ROOT` (snapshot parent).
String readContextKeyWithFallback() {
  try {
    final c = File(AlexandriaPaths.contextKeyPath);
    if (c.existsSync()) {
      final t = c.readAsStringSync().trim();
      if (t.isNotEmpty) return t;
    }
    return 'ROOT';
  } catch (_) {
    return 'ROOT';
  }
}

/// Solo `focus_key.txt`. Sin `open_key`. Ausente → `""`.
String readFocusKeyWithFallback() {
  try {
    final f = File(AlexandriaPaths.focusKeyPath);
    if (f.existsSync()) return f.readAsStringSync().trim();
    return '';
  } catch (_) {
    return '';
  }
}

/// LB escribe contexto al navegar atrás en la UI (Fase 3 — no usa open_key).
void writeBridgeContextKey(String key) {
  try {
    final f = File(AlexandriaPaths.contextKeyPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(key);
  } catch (e) {
    print('[LB][CONTEXT_WRITE_ERR] $e');
  }
}

/// Paridad con GateKeeper warp/back al navegar en LB.
void writeBridgeFocusKey(String key) {
  try {
    final f = File(AlexandriaPaths.focusKeyPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(key);
  } catch (e) {
    print('[LB][FOCUS_WRITE_ERR] $e');
  }
}

/// True si [path] existe y el JSON tiene `frames` no vacío (Cambio 059).
bool snapshotFileHasNonEmptyFrames(String path) {
  try {
    final f = File(path);
    if (!f.existsSync()) return false;
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map) return false;
    final frames = decoded['frames'];
    if (frames is! List) return false;
    return frames.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Contrato A15: GateKeeper hace polling de este archivo para volver a cargar el snapshot.
/// Sin condiciones de estado LB — solo falla si el SO impide escribir.
void _writeRefreshNowTrigger() {
  try {
    final p = AlexandriaPaths.refreshNowPath;
    final refreshFlag = File(p);
    refreshFlag.parent.createSync(recursive: true);
    refreshFlag.writeAsStringSync('1');
    print('[LB][REFRESH_WRITE] $p');
  } catch (e) {
    print('[LB][REFRESH_ERR] ${AlexandriaPaths.refreshNowPath} $e');
  }
}

/// Valores permitidos para [cognitiveRole] (solo metadata LB / UX; sin lógica en snapshot ni GK).
const List<String> kCognitiveRoles = [
  'realm',
  'parcour',
  'object',
];

/// Juego de cartas (emparejar imagen ↔ texto) en Library Build.
///
/// [lb_match_pairs.caption_text]: lema en escritura nativa; [transliteration] / [gloss] opcionales (ORM-16-08).
///
/// [lb_match_pairs.route_key]: `NULL` = pool global del realm (UI actual).
/// Futuro: fila por “ruta” (p. ej. parcour) para repaso caminando el espacio — sin lógica aún.
///
/// [lb_match_pair_fsrs_state]: `fib_index` + `due_at` = repaso tipo Fibonacci (mismo eje que locus review); columnas FSRS legacy opcionales sin usar.
void _ensureMatchCardsSchema(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS lb_match_pairs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      image_basename TEXT NOT NULL,
      caption_text TEXT NOT NULL,
      route_key TEXT,
      created_at TEXT NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS lb_match_pair_fsrs_state (
      pair_id INTEGER PRIMARY KEY,
      stability REAL,
      difficulty REAL,
      elapsed_days REAL,
      due_at TEXT,
      last_review_at TEXT,
      reps INTEGER NOT NULL DEFAULT 0
    )
  ''');

  final pairCols = db
      .select('PRAGMA table_info(lb_match_pairs)')
      .map((r) => r['name'] as String)
      .toList();
  if (!pairCols.contains('transliteration')) {
    db.execute('ALTER TABLE lb_match_pairs ADD COLUMN transliteration TEXT');
  }
  if (!pairCols.contains('gloss')) {
    db.execute('ALTER TABLE lb_match_pairs ADD COLUMN gloss TEXT');
  }
  db.execute('''
    CREATE TABLE IF NOT EXISTS lb_match_decks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
  if (!pairCols.contains('deck_id')) {
    db.execute('ALTER TABLE lb_match_pairs ADD COLUMN deck_id INTEGER');
  }
  final deckRows = db.select('SELECT COUNT(*) AS c FROM lb_match_decks');
  final deckCount = deckRows.isEmpty
      ? 0
      : (deckRows.first['c'] as num).toInt();
  if (deckCount == 0) {
    db.execute(
      'INSERT INTO lb_match_decks (name, created_at) VALUES (?, ?)',
      [
        'Default',
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }
  final firstDeck = db.select('SELECT id FROM lb_match_decks ORDER BY id ASC LIMIT 1');
  if (firstDeck.isNotEmpty) {
    final defaultDeckId = firstDeck.first['id'] as int;
    db.execute(
      'UPDATE lb_match_pairs SET deck_id = ? WHERE deck_id IS NULL',
      [defaultDeckId],
    );
  }
  final fsrsCols = db
      .select('PRAGMA table_info(lb_match_pair_fsrs_state)')
      .map((r) => r['name'] as String)
      .toList();
  if (!fsrsCols.contains('fib_index')) {
    db.execute(
      'ALTER TABLE lb_match_pair_fsrs_state ADD COLUMN fib_index INTEGER NOT NULL DEFAULT 0',
    );
  }
  if (!fsrsCols.contains('fail_count')) {
    db.execute(
      'ALTER TABLE lb_match_pair_fsrs_state ADD COLUMN fail_count INTEGER NOT NULL DEFAULT 0',
    );
  }
  if (!fsrsCols.contains('pass_count')) {
    db.execute(
      'ALTER TABLE lb_match_pair_fsrs_state ADD COLUMN pass_count INTEGER NOT NULL DEFAULT 0',
    );
  }
}

/// Progreso de problemas Go 9×9 (catálogo integrado o futuros packs); tablas mínimas.
void _ensureGoStudySchema(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS lb_go_problem_progress (
      problem_id TEXT PRIMARY KEY,
      attempts INTEGER NOT NULL DEFAULT 0,
      success_count INTEGER NOT NULL DEFAULT 0,
      last_played_at TEXT,
      mastered INTEGER NOT NULL DEFAULT 0
    )
  ''');
}

void _ensureLocusReviewSchema(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS locus_review_state (
      entry_key TEXT PRIMARY KEY,
      fib_index INTEGER NOT NULL DEFAULT 0,
      last_ok_at TEXT,
      next_due_at TEXT NOT NULL DEFAULT '1970-01-01',
      last_session_pct REAL
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS locus_review_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      locus_key TEXT NOT NULL,
      rating TEXT NOT NULL,
      pct REAL,
      fib_index_before INTEGER,
      fib_index_after INTEGER,
      due_after TEXT,
      created_at TEXT NOT NULL
    )
  ''');
}

/// Asegura columnas necesarias para viewer (`body_text`) y metadata (`cognitiveRole`).
/// [Cambio 351] `cognitiveRole` no condiciona `runLibraryBuild`, snapshot ni viewer.
void ensureLibrarySchema(Database db) {
  final info = db.select('PRAGMA table_info(entries)');
  final names = info.map((r) => r['name'] as String).toList();
  if (!names.contains('title')) {
    db.execute('ALTER TABLE entries ADD COLUMN title TEXT');
  }
  if (!names.contains('body_text')) {
    db.execute('ALTER TABLE entries ADD COLUMN body_text TEXT');
  }
  if (!names.contains('cognitiveRole')) {
    db.execute('ALTER TABLE entries ADD COLUMN cognitiveRole TEXT');
  }
  if (!names.contains('last_reviewed_at')) {
    db.execute('ALTER TABLE entries ADD COLUMN last_reviewed_at TEXT');
  }
  if (!names.contains('review_count')) {
    db.execute('ALTER TABLE entries ADD COLUMN review_count INTEGER');
  }
  if (!names.contains('success_count')) {
    db.execute('ALTER TABLE entries ADD COLUMN success_count INTEGER');
  }
  if (!names.contains('failure_count')) {
    db.execute('ALTER TABLE entries ADD COLUMN failure_count INTEGER');
  }
  if (!names.contains('last_review_grade')) {
    db.execute('ALTER TABLE entries ADD COLUMN last_review_grade INTEGER');
  }
  if (!names.contains('memory_strength')) {
    db.execute('ALTER TABLE entries ADD COLUMN memory_strength REAL');
  }
  if (!names.contains('stability_days')) {
    db.execute('ALTER TABLE entries ADD COLUMN stability_days REAL');
  }
  if (!names.contains('next_review_at')) {
    db.execute('ALTER TABLE entries ADD COLUMN next_review_at TEXT');
  }
  if (!names.contains('recall_score')) {
    db.execute('ALTER TABLE entries ADD COLUMN recall_score REAL');
  }
  if (!names.contains('spatial_turn')) {
    db.execute(
      "ALTER TABLE entries ADD COLUMN spatial_turn TEXT",
    );
  }
  if (!names.contains('place_recall_active')) {
    db.execute('ALTER TABLE entries ADD COLUMN place_recall_active INTEGER');
  }

  db.execute('''
CREATE TABLE IF NOT EXISTS review_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entryKey TEXT NOT NULL,
  reviewed_at TEXT NOT NULL,
  grade INTEGER NOT NULL,
  previous_stability_days REAL,
  new_stability_days REAL,
  previous_memory_strength REAL,
  new_memory_strength REAL,
  success INTEGER NOT NULL
)
''');
  _ensureLocusReviewSchema(db);
  _ensureMatchCardsSchema(db);
  ensurePokerMemorySchema(db);
  _ensureGoStudySchema(db);
  ensureParcourReviewSchema(db);
  ensurePaoStandardSchema(db);
  ensurePaoPhoneticSchema(db);
  // Filas sin rol (legacy o INSERT sin columna): default `'object'`; no afecta snapshot/viewer.
  db.execute(
    "UPDATE entries SET cognitiveRole = 'object' WHERE cognitiveRole IS NULL OR TRIM(COALESCE(cognitiveRole, '')) = ''",
  );
  // ROOT lógico = realm (herencia hijo → parcour). Legacy `object` en ROOT bloqueaba crear hijos.
  db.execute(
    "UPDATE entries SET cognitiveRole = 'realm' WHERE key = '$_realmKey' AND cognitiveRole = 'object'",
  );
  db.execute(
    "UPDATE entries SET review_count = COALESCE(review_count, 0), success_count = COALESCE(success_count, 0), failure_count = COALESCE(failure_count, 0)",
  );
  db.execute(
    "UPDATE entries SET memory_strength = COALESCE(memory_strength, 0.3), stability_days = COALESCE(stability_days, 1.0), recall_score = COALESCE(recall_score, 0.0) WHERE cognitiveRole = 'object'",
  );

  /// ORM `LAYERS_REALM_PARCOUR_OBJECT.md`: realm canónico `R1`; hub legado `PARCOUR_MAIN` → etiqueta de parcours bajo R1.
  db.execute("UPDATE entries SET title = 'R1' WHERE key = '$_realmKey'");
  db.execute("UPDATE entries SET title = 'Parcours (R1)' WHERE key = '$_primaryParcourKey'");

  ensureEntriesFts5(db);
}

double _asDouble(Object? v, double fallback) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

int _asInt(Object? v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

DateTime? _parseIso(Object? v) {
  final s = v?.toString().trim() ?? '';
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

double _clamp(double x, double lo, double hi) {
  if (x < lo) return lo;
  if (x > hi) return hi;
  return x;
}

/// grade: 0=Again, 1=Hard, 2=Good, 3=Easy
void recordRecallReview(Database db, String entryKey, int grade) {
  final g = grade < 0 ? 0 : (grade > 3 ? 3 : grade);
  final now = DateTime.now().toUtc();
  final rows = db.select(
    'SELECT cognitiveRole, review_count, success_count, failure_count, memory_strength, stability_days, last_reviewed_at, next_review_at FROM entries WHERE key = ? LIMIT 1',
    [entryKey],
  );
  if (rows.isEmpty) return;
  final r = rows.first;
  if (normalizeCognitiveRole(r['cognitiveRole']) != 'object') return;

  final oldStrength = _asDouble(r['memory_strength'], 0.3);
  final oldStability = _asDouble(r['stability_days'], 1.0);
  final rc = _asInt(r['review_count'], 0);
  final sc = _asInt(r['success_count'], 0);
  final fc = _asInt(r['failure_count'], 0);
  final lastReviewed = _parseIso(r['last_reviewed_at']);

  final elapsedDays = lastReviewed == null
      ? oldStability
      : now.difference(lastReviewed.toUtc()).inMinutes / (60.0 * 24.0);
  final retrievability = math.exp(-(elapsedDays / oldStability.clamp(0.2, 365.0)));
  final success = g >= 1 ? 1 : 0;
  final quality = switch (g) {
    0 => 0.0,
    1 => 0.35,
    2 => 0.75,
    _ => 1.0,
  };

  double newStrength;
  double newStability;
  if (success == 0) {
    newStrength = _clamp(oldStrength * 0.62, 0.1, 1.8);
    newStability = _clamp(oldStability * 0.45, 0.2, 3.0);
  } else {
    final recoveryBoost = (1.0 - retrievability) * 0.4;
    newStrength = _clamp(oldStrength + 0.08 + quality * 0.2 + recoveryBoost, 0.1, 2.5);
    final growth = 1.0 + quality * 1.25 + newStrength * 0.18;
    final hardPenalty = g == 1 ? 0.78 : 1.0;
    final easyBonus = g == 3 ? 1.18 : 1.0;
    newStability = _clamp(oldStability * growth * hardPenalty * easyBonus, 0.3, 365.0);
  }

  final nextReview = now.add(Duration(minutes: (newStability * 24 * 60).round()));
  final recallScore = _clamp(
    (newStrength * 0.45) + (newStability / 30.0) * 0.35 + retrievability * 0.20,
    0.0,
    10.0,
  );

  db.execute(
    'UPDATE entries SET last_reviewed_at = ?, review_count = ?, success_count = ?, failure_count = ?, last_review_grade = ?, memory_strength = ?, stability_days = ?, next_review_at = ?, recall_score = ? WHERE key = ?',
    [
      now.toIso8601String(),
      rc + 1,
      sc + (success == 1 ? 1 : 0),
      fc + (success == 1 ? 0 : 1),
      g,
      newStrength,
      newStability,
      nextReview.toIso8601String(),
      recallScore,
      entryKey,
    ],
  );

  db.execute(
    'INSERT INTO review_events (entryKey, reviewed_at, grade, previous_stability_days, new_stability_days, previous_memory_strength, new_memory_strength, success) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [
      entryKey,
      now.toIso8601String(),
      g,
      oldStability,
      newStability,
      oldStrength,
      newStrength,
      success,
    ],
  );
}

Map<String, int> computeRecallStatsForParent(Database db, String parentKey) {
  final rows = db.select(
    "SELECT next_review_at FROM entries WHERE parentKey = ? AND cognitiveRole = 'object'",
    [parentKey],
  );
  final now = DateTime.now().toUtc();
  var total = 0;
  var due = 0;
  var newCards = 0;
  for (final r in rows) {
    total++;
    final nextAt = _parseIso(r['next_review_at']);
    if (nextAt == null) {
      newCards++;
      continue;
    }
    if (!nextAt.toUtc().isAfter(now)) due++;
  }
  return {'total': total, 'due': due, 'new': newCards};
}

/// Igual que [computeRecallStatsForParent] pero sobre **todos** los `object` bajo [rootKey] (CTE recursiva).
/// Alineado con [summarizeLocusScheduleForSubtree] para la barra de estadísticas.
Map<String, int> computeRecallStatsForSubtree(Database db, String rootKey) {
  final rows = db.select('''
    WITH RECURSIVE subtree(key) AS (
      SELECT ?1
      UNION ALL
      SELECT e.key FROM entries e INNER JOIN subtree s ON e.parentKey = s.key
    )
    SELECT e.next_review_at AS next_review_at
    FROM entries e
    INNER JOIN subtree st ON e.key = st.key
    WHERE e.cognitiveRole = 'object'
  ''', [rootKey]);
  final now = DateTime.now().toUtc();
  var total = 0;
  var due = 0;
  var newCards = 0;
  for (final r in rows) {
    total++;
    final nextAt = _parseIso(r['next_review_at']);
    if (nextAt == null) {
      newCards++;
      continue;
    }
    if (!nextAt.toUtc().isAfter(now)) due++;
  }
  return {'total': total, 'due': due, 'new': newCards};
}

String _slotTwoDigits(int seq) => (seq + 1).toString().padLeft(2, '0');

String _defaultObjectKeyForParcourChild(String parentKey, int seq) =>
    '${parentKey}_O${_slotTwoDigits(seq)}';

bool _tableExists(Database db, String tableName) {
  final rows = db.select(
    "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
    [tableName],
  );
  return rows.isNotEmpty;
}

void _replaceBridgeKeyIfEquals(String path, String oldKey, String newKey) {
  try {
    final f = File(path);
    if (!f.existsSync()) return;
    final current = f.readAsStringSync().trim();
    if (current == oldKey) f.writeAsStringSync(newKey);
  } catch (_) {}
}

void _moveDirIfExists(String fromPath, String toPath) {
  try {
    final from = Directory(fromPath);
    if (!from.existsSync()) return;
    final to = Directory(toPath);
    if (to.existsSync()) return;
    from.renameSync(toPath);
  } catch (_) {}
}

void _moveFileIfExists(String fromPath, String toPath) {
  try {
    final from = File(fromPath);
    if (!from.existsSync()) return;
    final to = File(toPath);
    if (to.existsSync()) return;
    from.renameSync(toPath);
  } catch (_) {}
}

void _renameEntryEverywhere(Database db, String oldKey, String newKey) {
  if (oldKey == newKey) return;

  final exists = db.select('SELECT 1 FROM entries WHERE key = ? LIMIT 1', [oldKey]);
  if (exists.isEmpty) return;
  final targetExists = db.select('SELECT 1 FROM entries WHERE key = ? LIMIT 1', [newKey]);
  if (targetExists.isNotEmpty) {
    print('[LB][KEY_RENAME_SKIP] target exists old=$oldKey new=$newKey');
    return;
  }

  db.execute('UPDATE entries SET key = ? WHERE key = ?', [newKey, oldKey]);
  db.execute('UPDATE entries SET parentKey = ? WHERE parentKey = ?', [newKey, oldKey]);

  if (_tableExists(db, 'assets')) {
    db.execute('UPDATE assets SET entryKey = ? WHERE entryKey = ?', [newKey, oldKey]);
  }

  _replaceBridgeKeyIfEquals(AlexandriaPaths.contextKeyPath, oldKey, newKey);
  _replaceBridgeKeyIfEquals(AlexandriaPaths.focusKeyPath, oldKey, newKey);
  _moveDirIfExists('${AlexandriaPaths.assetsRoot}/$oldKey', '${AlexandriaPaths.assetsRoot}/$newKey');
  _moveFileIfExists('${AlexandriaPaths.snapshotRoot}/$oldKey.json', '${AlexandriaPaths.snapshotRoot}/$newKey.json');
  _moveFileIfExists('${AlexandriaPaths.viewerRoot}/$oldKey.json', '${AlexandriaPaths.viewerRoot}/$newKey.json');
  _moveFileIfExists('${AlexandriaPaths.wallManifestRoot}/$oldKey.json', '${AlexandriaPaths.wallManifestRoot}/$newKey.json');

  print('[LB][KEY_RENAME] $oldKey -> $newKey');
}

/// Clave canónica `Parent_O01`…`Parent_O20` para [seq] en `0..19`.
String defaultObjectKeyForParcourChild(String parentKey, int seq) =>
    _defaultObjectKeyForParcourChild(parentKey, seq);

/// Resultado de [remapParcourSubtreeToParcourKey].
class ParcourRemapResult {
  const ParcourRemapResult._(this.ok, this.message);

  final bool ok;
  final String message;

  factory ParcourRemapResult.success() => const ParcourRemapResult._(true, '');
  factory ParcourRemapResult.fail(String message) =>
      ParcourRemapResult._(false, message);
}

bool _entryIsStrictDescendantOf(Database db, String ancestorKey, String key) {
  if (key == ancestorKey) return false;
  var k = key;
  for (var i = 0; i < 4096; i++) {
    final r = db.select('SELECT parentKey FROM entries WHERE key = ?', [k]);
    if (r.isEmpty) return false;
    final p = r.first['parentKey']?.toString().trim();
    if (p == null || p.isEmpty) return false;
    if (p == ancestorKey) return true;
    k = p;
  }
  return false;
}

List<String> _subtreeKeysDeepestFirst(Database db, String rootKey) {
  final rows = db.select('''
    WITH RECURSIVE st(key, depth) AS (
      SELECT key, 0 AS depth FROM entries WHERE key = ?
      UNION ALL
      SELECT e.key, st.depth + 1
      FROM entries e INNER JOIN st ON e.parentKey = st.key
    )
    SELECT key FROM st ORDER BY depth DESC
  ''', [rootKey]);
  return rows.map((r) => r['key'] as String).toList();
}

void _purgeDiskArtifactsForKey(String key) {
  try {
    final dir = Directory('${AlexandriaPaths.assetsRoot}/$key');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  } catch (e, st) {
    print('[LB][purge] assets/$key: $e\n$st');
  }
  for (final base in [
    AlexandriaPaths.snapshotRoot,
    AlexandriaPaths.viewerRoot,
    AlexandriaPaths.wallManifestRoot,
  ]) {
    try {
      final f = File('$base/$key.json');
      if (f.existsSync()) f.deleteSync();
    } catch (e, st) {
      print('[LB][purge] $base/$key.json: $e\n$st');
    }
  }
}

/// Filas de Parcour Review que referencian [key] como locus o como parcour de sesión.
void _deleteParcourReviewRowsForKey(Database db, String key) {
  if (!_tableExists(db, 'parcour_review_sessions')) return;
  ensureParcourReviewSchema(db);
  db.execute('DELETE FROM parcour_review_session_loci WHERE locus_key = ?', [key]);
  db.execute(
    'DELETE FROM parcour_review_session_loci WHERE session_id IN (SELECT id FROM parcour_review_sessions WHERE parcour_key = ?)',
    [key],
  );
  db.execute('DELETE FROM parcour_review_sessions WHERE parcour_key = ?', [key]);
  db.execute('DELETE FROM parcour_review_state WHERE parcour_key = ?', [key]);
}

void _deleteEntryRowAndRelated(Database db, String key) {
  _deleteParcourReviewRowsForKey(db, key);
  if (_tableExists(db, 'review_events')) {
    db.execute('DELETE FROM review_events WHERE entryKey = ?', [key]);
  }
  if (_tableExists(db, 'locus_review_state')) {
    db.execute('DELETE FROM locus_review_state WHERE entry_key = ?', [key]);
  }
  if (_tableExists(db, 'locus_review_events')) {
    db.execute('DELETE FROM locus_review_events WHERE locus_key = ?', [key]);
  }
  if (_tableExists(db, 'assets')) {
    db.execute('DELETE FROM assets WHERE entryKey = ?', [key]);
  }
  db.execute('DELETE FROM entries WHERE key = ?', [key]);
  _purgeDiskArtifactsForKey(key);
}

/// Borra [rootKey] y todo su subárbol en SQLite, limpia tablas satélite y disco bajo el realm,
/// ajusta bridge, FTS y regenera snapshot/navigation (vía [runLibraryBuild]).
///
/// No permitido: `ROOT`, `PARCOUR_MAIN` (estructura del realm).
void deleteEntrySubtreeAndSync(Database db, String rootKey) {
  final k = rootKey.trim();
  if (k.isEmpty) {
    throw ArgumentError('empty key');
  }
  if (k == 'ROOT' || k == 'PARCOUR_MAIN') {
    throw StateError('Cannot delete ROOT or PARCOUR_MAIN.');
  }
  ensureLibrarySchema(db);
  ensureParcourReviewSchema(db);
  final removed = _subtreeKeysDeepestFirst(db, k);
  if (removed.isEmpty) {
    return;
  }
  final removedSet = removed.toSet();
  try {
    db.execute('BEGIN IMMEDIATE');
    _deleteSubtreeForRemap(db, k);
    db.execute('COMMIT');
  } catch (e) {
    try {
      db.execute('ROLLBACK');
    } catch (_) {}
    rethrow;
  }
  _bridgeResetIfKeysRemoved(removedSet);
  rebuildEntriesFts5(db);
  runLibraryBuild();
}

/// Quita filas y artefactos del subárbol en [rootKey] (hojas → raíz). Sin tocar el bridge
/// (llamar a [_bridgeResetIfKeysRemoved] tras COMMIT si aplica).
void _deleteSubtreeForRemap(Database db, String rootKey) {
  final keys = _subtreeKeysDeepestFirst(db, rootKey);
  for (final k in keys) {
    _deleteEntryRowAndRelated(db, k);
  }
}

void _bridgeResetIfKeysRemoved(Set<String> removed) {
  if (removed.isEmpty) return;
  final ctx = readContextKeyWithFallback();
  if (removed.contains(ctx)) writeBridgeContextKey('ROOT');
  final foc = readFocusKeyWithFallback();
  if (foc.isNotEmpty && removed.contains(foc)) writeBridgeFocusKey('');
}

/// Mueve un parcour y sus hijos a las claves canónicas bajo [toParcourKey]:
/// borra el subárbol destino (reemplazo), renombra hijos `seq` → `to_Oxx`, luego el parcour.
/// Restaura el hueco del origen con el esqueleto ORM (`L1`…`L20` + objetos).
///
/// Requisitos: ambos existen como `parcour`; el origen no puede estar dentro del destino
/// ni al revés (evita borrar el subárbol que se va a conservar).
ParcourRemapResult remapParcourSubtreeToParcourKey(
  Database db,
  String fromParcourKey,
  String toParcourKey,
) {
  ensureLibrarySchema(db);
  final from = fromParcourKey.trim();
  final to = toParcourKey.trim();
  if (from.isEmpty || to.isEmpty) {
    return ParcourRemapResult.fail('Origen o destino vacío.');
  }
  if (from == to) {
    return ParcourRemapResult.success();
  }

  final fromRow = db.select(
    'SELECT cognitiveRole FROM entries WHERE key = ? LIMIT 1',
    [from],
  );
  if (fromRow.isEmpty) {
    return ParcourRemapResult.fail('Origen no existe.');
  }
  if (normalizeCognitiveRole(fromRow.first['cognitiveRole']) != 'parcour') {
    return ParcourRemapResult.fail('El origen debe ser un parcour.');
  }

  final toRow = db.select(
    'SELECT cognitiveRole FROM entries WHERE key = ? LIMIT 1',
    [to],
  );
  if (toRow.isEmpty) {
    return ParcourRemapResult.fail('Destino no existe.');
  }
  if (normalizeCognitiveRole(toRow.first['cognitiveRole']) != 'parcour') {
    return ParcourRemapResult.fail('El destino debe ser un parcour.');
  }

  if (_entryIsStrictDescendantOf(db, to, from)) {
    return ParcourRemapResult.fail(
      'El origen está bajo el destino; vaciar destino borraría el origen.',
    );
  }
  if (_entryIsStrictDescendantOf(db, from, to)) {
    return ParcourRemapResult.fail(
      'El destino está bajo el origen; elige un parcour fuera de ese subárbol.',
    );
  }

  try {
    db.execute('BEGIN IMMEDIATE');
    final destKeysRemoved = _subtreeKeysDeepestFirst(db, to).toSet();
    _deleteSubtreeForRemap(db, to);

    final children = db.select(
      'SELECT key, seq FROM entries WHERE parentKey = ? ORDER BY seq ASC, key ASC',
      [from],
    );

    for (final row in children) {
      final oldChild = row['key']?.toString().trim() ?? '';
      if (oldChild.isEmpty) continue;
      final rawSeq = row['seq'];
      final seq = rawSeq is int
          ? rawSeq
          : int.tryParse(rawSeq?.toString() ?? '');
      if (seq == null || seq < 0 || seq > 19) continue;
      final newChild = _defaultObjectKeyForParcourChild(to, seq);
      _renameEntryEverywhere(db, oldChild, newChild);
      final stillThere =
          db.select('SELECT 1 FROM entries WHERE key = ?', [oldChild]);
      if (stillThere.isNotEmpty) {
        db.execute('ROLLBACK');
        return ParcourRemapResult.fail(
          'No se pudo renombrar $oldChild → $newChild (¿clave bloqueada?).',
        );
      }
    }

    _renameEntryEverywhere(db, from, to);
    final fromStill =
        db.select('SELECT 1 FROM entries WHERE key = ?', [from]);
    if (fromStill.isNotEmpty) {
      db.execute('ROLLBACK');
      return ParcourRemapResult.fail(
        'No se pudo renombrar el parcour $from → $to.',
      );
    }

    _insertHomogeneousSkeletonIfNeeded(db);
    _normalizeRealmParcourLanguage(db);

    db.execute('COMMIT');

    _bridgeResetIfKeysRemoved(destKeysRemoved);
    print('[LB][PARCOUR_REMAP] $from → $to (hijos=${children.length})');
    return ParcourRemapResult.success();
  } catch (e, st) {
    try {
      db.execute('ROLLBACK');
    } catch (_) {}
    print('[LB][PARCOUR_REMAP_ERR] $e\n$st');
    return ParcourRemapResult.fail('Error: $e');
  }
}

/// Mueve un locus `object` al slot canónico `destParcour_Oxx` con [destSeq] en `0..19`.
/// Si el destino ya tiene fila, se elimina (reemplazo). Tras mover, se normaliza el esqueleto
/// (hueco en el parcour de origen).
ParcourRemapResult moveObjectLocusToParcourSlot(
  Database db,
  String objectKey,
  String destParcourKey,
  int destSeq,
) {
  ensureLibrarySchema(db);
  if (destSeq < 0 || destSeq > 19) {
    return ParcourRemapResult.fail('El slot debe estar entre 1 y 20 (seq 0..19).');
  }
  final from = objectKey.trim();
  final toParent = destParcourKey.trim();
  if (from.isEmpty || toParent.isEmpty) {
    return ParcourRemapResult.fail('Clave o parcour vacío.');
  }

  final newKey = _defaultObjectKeyForParcourChild(toParent, destSeq);

  final objRow = db.select(
    'SELECT cognitiveRole, parentKey FROM entries WHERE key = ? LIMIT 1',
    [from],
  );
  if (objRow.isEmpty) {
    return ParcourRemapResult.fail('Objeto no existe.');
  }
  if (normalizeCognitiveRole(objRow.first['cognitiveRole']) != 'object') {
    return ParcourRemapResult.fail('Solo se pueden mover loci de tipo object.');
  }

  final pRow = db.select(
    'SELECT cognitiveRole FROM entries WHERE key = ? LIMIT 1',
    [toParent],
  );
  if (pRow.isEmpty) {
    return ParcourRemapResult.fail('Parcour destino no existe.');
  }
  if (normalizeCognitiveRole(pRow.first['cognitiveRole']) != 'parcour') {
    return ParcourRemapResult.fail('El destino debe ser un parcour.');
  }

  if (from == newKey) {
    try {
      db.execute('BEGIN IMMEDIATE');
      db.execute(
        "UPDATE entries SET parentKey = ?, seq = ?, cognitiveRole = 'object' WHERE key = ?",
        [toParent, destSeq, newKey],
      );
      _insertHomogeneousSkeletonIfNeeded(db);
      _normalizeRealmParcourLanguage(db);
      db.execute('COMMIT');
      print('[LB][OBJECT_MOVE] $from (solo alinear parent/seq)');
      return ParcourRemapResult.success();
    } catch (e, st) {
      try {
        db.execute('ROLLBACK');
      } catch (_) {}
      print('[LB][OBJECT_MOVE_ERR] $e\n$st');
      return ParcourRemapResult.fail('Error: $e');
    }
  }

  try {
    db.execute('BEGIN IMMEDIATE');
    final removedForBridge = <String>{};
    final destRow = db.select('SELECT 1 FROM entries WHERE key = ?', [newKey]);
    if (destRow.isNotEmpty) {
      removedForBridge.add(newKey);
      _deleteEntryRowAndRelated(db, newKey);
    }

    _renameEntryEverywhere(db, from, newKey);
    final stillOld =
        db.select('SELECT 1 FROM entries WHERE key = ?', [from]);
    if (stillOld.isNotEmpty) {
      db.execute('ROLLBACK');
      return ParcourRemapResult.fail(
        'No se pudo renombrar $from → $newKey (¿destino bloqueado?).',
      );
    }

    db.execute(
      "UPDATE entries SET parentKey = ?, seq = ?, cognitiveRole = 'object' WHERE key = ?",
      [toParent, destSeq, newKey],
    );

    _insertHomogeneousSkeletonIfNeeded(db);
    _normalizeRealmParcourLanguage(db);

    db.execute('COMMIT');

    _bridgeResetIfKeysRemoved(removedForBridge);
    print('[LB][OBJECT_MOVE] $from → $newKey');
    return ParcourRemapResult.success();
  } catch (e, st) {
    try {
      db.execute('ROLLBACK');
    } catch (_) {}
    print('[LB][OBJECT_MOVE_ERR] $e\n$st');
    return ParcourRemapResult.fail('Error: $e');
  }
}

void _ensureObjectSlotsForParcourChildren(Database db) {
  final parcourRows = db.select(
    'SELECT key FROM entries WHERE parentKey = ? ORDER BY seq ASC',
    [_primaryParcourKey],
  );

  for (final row in parcourRows) {
    final parent = row['key']?.toString().trim() ?? '';
    if (parent.isEmpty) continue;

    // Cada hijo del parcour principal funciona como "sub-parcour" al entrar.
    db.execute(
      "UPDATE entries SET cognitiveRole = 'parcour' WHERE key = ?",
      [parent],
    );

    final children = db.select(
      'SELECT key, seq FROM entries WHERE parentKey = ? ORDER BY seq ASC',
      [parent],
    );

    for (final c in children) {
      final raw = c['seq'];
      final seq = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
      if (seq == null || seq < 0 || seq > 19) continue;
      final currentKey = c['key']?.toString().trim() ?? '';
      if (currentKey.isNotEmpty) {
        final canonical = _defaultObjectKeyForParcourChild(parent, seq);
        if (currentKey != canonical) {
          _renameEntryEverywhere(db, currentKey, canonical);
        }
      }
      db.execute(
        "UPDATE entries SET cognitiveRole = 'object' WHERE key = ?",
        [_defaultObjectKeyForParcourChild(parent, seq)],
      );
    }

    final refreshed = db.select(
      'SELECT key, seq FROM entries WHERE parentKey = ? ORDER BY seq ASC',
      [parent],
    );
    final refreshedSeq = <int>{};
    final refreshedKeys = <String>{};
    for (final c in refreshed) {
      final raw = c['seq'];
      final seq = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
      if (seq == null || seq < 0 || seq > 19) continue;
      refreshedSeq.add(seq);
      final k = c['key']?.toString().trim() ?? '';
      if (k.isNotEmpty) refreshedKeys.add(k);
    }

    for (var seq = 0; seq < 20; seq++) {
      if (refreshedSeq.contains(seq)) continue;

      var key = _defaultObjectKeyForParcourChild(parent, seq);
      if (refreshedKeys.contains(key)) {
        key = '${parent}_AUTO_O${_slotTwoDigits(seq)}';
      }

      db.execute(
        'INSERT INTO entries (key, parentKey, seq, cognitiveRole, title) VALUES (?, ?, ?, ?, ?)',
        [key, parent, seq, 'object', key],
      );
      refreshedKeys.add(key);
    }
  }
}

void _normalizeRealmParcourLanguage(Database db) {
  db.execute(
    "UPDATE entries SET cognitiveRole = 'realm' WHERE key = ?",
    [_realmKey],
  );
  db.execute(
    "UPDATE entries SET cognitiveRole = 'parcour' WHERE key = ?",
    [_primaryParcourKey],
  );

  _ensureObjectSlotsForParcourChildren(db);
}

/// Normaliza valor guardado a uno de [kCognitiveRoles]; por defecto `'object'`.
String normalizeCognitiveRole(Object? raw) {
  final s = raw?.toString().trim().toLowerCase() ?? '';
  if (s == 'room') return 'object'; // Legacy mapping: ROOM colapsa en OBJECT.
  if (kCognitiveRoles.contains(s)) return s;
  return 'object';
}

/// Rol por defecto del **hijo** según rol del **padre** (LB; GK no lee esto).
/// Si no hay fila de padre en DB, tratar como `realm` → hijo `parcour`.
/// Padre `object` no debe usarse aquí (bloqueo UI antes de INSERT).
String defaultChildCognitiveRoleForParent(Object? parentRoleRaw) {
  final p = parentRoleRaw == null
      ? 'realm'
      : normalizeCognitiveRole(parentRoleRaw);
  switch (p) {
    case 'realm':
      return 'parcour';
    case 'parcour':
    case 'object':
      return 'object';
    default:
      return 'parcour';
  }
}

/// Alineado con [locus_editor] para `hint` / `ridiculous_story` (viewer GK solo usa `text`).
String _inferParagraphTextKind(Map<String, dynamic> m, String tLower) {
  var textKind = (m['textKind'] ?? '').toString().toLowerCase().trim();
  if (textKind.isEmpty) {
    if (tLower == 'hint') textKind = 'hint';
    if (tLower == 'place') textKind = 'place';
    if (tLower == 'ridiculous_story' || tLower == 'story') {
      textKind = 'ridiculous_story';
    }
  }
  if (textKind.isEmpty) textKind = 'text';
  return textKind;
}

/// Parsea JSON de bloques (legacy `t`/`text`/`assetKey` o `type`/`text`/`src`).
/// Conserva `img`, `link`, `audio`, `warp`, `tag`; el resto → `p` con `textKind` normalizado.
/// Tipos `hint`/`place`/… como `type` se pliegan a `p` + `textKind`.
List<Map<String, dynamic>> parseBody(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final el in decoded) {
      if (el is! Map) continue;
      final m = Map<String, dynamic>.from(
        el.map((k, v) => MapEntry(k.toString(), v)),
      );
      final tLower =
          (m['t'] ?? m['type'] ?? 'p').toString().toLowerCase().trim();

      if (tLower == 'img') {
        final src = (m['src'] ?? m['assetKey'] ?? '').toString();
        final roleRaw =
            (m['role'] ?? m['imgRole'] ?? 'content').toString().toLowerCase().trim();
        final role = (roleRaw == 'hero' ||
                roleRaw == 'collage' ||
                roleRaw == 'recall_crop')
            ? roleRaw
            : 'content';
        out.add({'type': 'img', 'src': src, 'role': role});
        continue;
      }

      if (tLower == 'link') {
        final linkKey = (m['key'] ?? '').toString();
        final linkText = (m['text'] ?? '').toString();
        if (linkKey.isNotEmpty && linkText.isNotEmpty) {
          out.add({'type': 'link', 'key': linkKey, 'text': linkText});
        } else {
          out.add({
            'type': 'p',
            'text': linkText.isNotEmpty ? linkText : linkKey,
            'textKind': normalizeTextKind(_inferParagraphTextKind(m, tLower)),
          });
        }
        continue;
      }

      if (tLower == 'audio') {
        out.add({'type': 'audio', 'src': (m['src'] ?? '').toString()});
        continue;
      }
      if (tLower == 'warp') {
        out.add({
          'type': 'warp',
          'key': (m['key'] ?? '').toString(),
          'text': (m['text'] ?? '').toString(),
        });
        continue;
      }
      if (tLower == 'tag') {
        out.add({'type': 'tag', 'text': (m['text'] ?? '').toString()});
        continue;
      }

      if (tLower == 'card') {
        final word = (m['word'] ?? '').toString().trim();
        final image =
            (m['image'] ?? m['src'] ?? '').toString().trim();
        final phonetic = (m['phonetic'] ?? '').toString().trim();
        final audio = (m['audio'] ?? '').toString().trim();
        final related = <String>[];
        final rawRel = m['related_to'];
        if (rawRel is List) {
          for (final e in rawRel) {
            final s = e.toString().trim();
            if (s.isNotEmpty) related.add(s);
          }
        }
        if (word.isEmpty && image.isEmpty) {
          continue;
        }
        final row = <String, dynamic>{
          'type': 'card',
          'word': word,
        };
        if (image.isNotEmpty) row['image'] = image;
        if (phonetic.isNotEmpty) row['phonetic'] = phonetic;
        if (audio.isNotEmpty) row['audio'] = audio;
        if (related.isNotEmpty) row['related_to'] = related;
        out.add(row);
        continue;
      }

      out.add({
        'type': 'p',
        'text': (m['text'] ?? '').toString(),
        'textKind': normalizeTextKind(_inferParagraphTextKind(m, tLower)),
      });
    }
    return out;
  } catch (_) {
    return [];
  }
}

/// Imágenes `recall_crop`: solo para el quiz place recall en el visor 3D. Omitir en
/// lector de nodo, PDF y vistas de lectura; el editor y el estudio por parcour siguen
/// usando el cuerpo completo.
bool shouldOmitFromLocusReadingExport(Map<String, dynamic> b) {
  if ((b['type'] ?? 'p').toString() != 'img') return false;
  final role = (b['role'] ?? 'content').toString().toLowerCase().trim();
  return role == 'recall_crop';
}

/// Ruta de archivo para miniatura en listas / búsqueda de objetos: bloque `img` con
/// `role: hero`, luego `hero.*` en `assets/<key>/`, y como último recurso la primera
/// `img` cuyo rol **no** sea `collage` ni `recall_crop` (pared GK / quiz LB).
String? resolveListHeroThumbPath(String entryKey, String? bodyText) {
  final sep = Platform.pathSeparator;
  final baseDir = Directory('${AlexandriaPaths.assetsRoot}$sep$entryKey');

  String? resolveSrc(String src) {
    if (src.isEmpty) return null;
    final direct = File(src);
    if (direct.existsSync()) return src;
    final underKey = File('${baseDir.path}$sep$src');
    if (underKey.existsSync()) return underKey.path;
    final underRoot = File('${AlexandriaPaths.assetsRoot}$sep$src');
    if (underRoot.existsSync()) return underRoot.path;
    return null;
  }

  final blocks = parseBody(bodyText);

  for (final b in blocks) {
    if (b['type'] != 'img') continue;
    final role = (b['role'] ?? 'content').toString().toLowerCase().trim();
    if (role != 'hero') continue;
    final src = (b['src'] ?? '').toString().trim();
    final p = resolveSrc(src);
    if (p != null) return p;
  }

  for (final name in ['hero.png', 'hero.jpg', 'hero.jpeg', 'hero.webp']) {
    final f = File('${baseDir.path}$sep$name');
    if (f.existsSync()) return f.path;
  }

  for (final b in blocks) {
    if (b['type'] != 'img') continue;
    final role = (b['role'] ?? 'content').toString().toLowerCase().trim();
    if (role == 'collage' || role == 'recall_crop') continue;
    final src = (b['src'] ?? '').toString().trim();
    final p = resolveSrc(src);
    if (p != null) return p;
  }
  return null;
}

class _WallImageSelection {
  _WallImageSelection({required this.filename, required this.collageOrder, required this.index});
  final String filename;
  final int collageOrder;
  final int index;
}

List<_WallImageSelection> _extractWallImageFilenamesFromBodyText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const <_WallImageSelection>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <_WallImageSelection>[];
    final out = <_WallImageSelection>[];
    for (var i = 0; i < decoded.length; i++) {
      final el = decoded[i];
      if (el is! Map) continue;
      final m = Map<String, dynamic>.from(
        el.map((k, v) => MapEntry(k.toString(), v)),
      );
      final t = (m['type'] ?? m['t'] ?? '').toString();
      if (t != 'img') continue;
      final role = (m['role'] ?? m['imgRole'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      if (role != 'collage') continue;
      final src = (m['src'] ?? m['assetKey'] ?? '').toString().trim();
      if (src.isEmpty) continue;
      final orderRaw = m['collageOrder'];
      final order = orderRaw is int
          ? orderRaw
          : (orderRaw is num ? orderRaw.toInt() : i + 1);
      out.add(
        _WallImageSelection(
          filename: src.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), ''),
          collageOrder: order,
          index: i,
        ),
      );
    }
    out.sort((a, b) {
      final byOrder = a.collageOrder.compareTo(b.collageOrder);
      if (byOrder != 0) return byOrder;
      return a.index.compareTo(b.index);
    });
    return out;
  } catch (_) {
    return const <_WallImageSelection>[];
  }
}

String _wallImageContentHash(String fullPath) {
  try {
    final stat = File(fullPath).statSync();
    return '${stat.size}:${stat.modified.millisecondsSinceEpoch}';
  } catch (_) {
    return '0:0';
  }
}

void _writeWallManifestForKey(Database db, String key) {
  if (key.trim().isEmpty) return;

  final rows = db.select(
    'SELECT body_text FROM entries WHERE key = ? LIMIT 1',
    [key],
  );
  final raw = rows.isNotEmpty ? rows.first['body_text'] as String? : null;
  final imageNames = _extractWallImageFilenamesFromBodyText(raw);

  final images = <Map<String, dynamic>>[];
  final seen = <String>{};
  for (final sel in imageNames) {
    final filename = sel.filename;
    if (!seen.add(filename.toLowerCase())) continue;
    final full = '${AlexandriaPaths.assetsRoot}/$key/${filename.replaceAll('/', Platform.pathSeparator)}';
    if (!File(full).existsSync()) continue;
    images.add({
      'filename': filename,
      'hash': _wallImageContentHash(full),
    });
  }

  final payload = {
    'key': key,
    'version': DateTime.now().millisecondsSinceEpoch,
    'images': images,
    'groups': <dynamic>[],
  };
  final outPath = '${AlexandriaPaths.wallManifestRoot}/$key.json';
  final out = File(outPath);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(jsonEncode(payload));
}

void _rebuildAllWallManifests(Database db) {
  final dir = Directory(AlexandriaPaths.wallManifestRoot);
  dir.createSync(recursive: true);
  for (final e in dir.listSync()) {
    if (e is File && e.path.toLowerCase().endsWith('.json')) {
      try {
        e.deleteSync();
      } catch (_) {}
    }
  }

  final rows = db.select('SELECT key FROM entries');
  for (final r in rows) {
    final key = r['key']?.toString() ?? '';
    if (key.isEmpty) continue;
    _writeWallManifestForKey(db, key);
  }
  print('[LB][WALL_MANIFEST_REBUILD] keys=${rows.length}');
}

/// COUNT(*) puede venir como int, int64 u otros tipos según plataforma/driver.
int _sqliteCountToInt(Object? cVal) {
  if (cVal == null) return 0;
  if (cVal is int) return cVal;
  if (cVal is num) return cVal.toInt();
  return int.tryParse(cVal.toString()) ?? 0;
}

String? _normalizeSpatialTurnForSnapshot(Object? raw) {
  final s = raw?.toString().trim().toLowerCase() ?? '';
  if (s.isEmpty || s == 'straight' || s == 'recto' || s == 'none') {
    return null;
  }
  if (s == 'left' || s == 'l' || s == 'izquierda') return 'left';
  if (s == 'right' || s == 'r' || s == 'derecha') return 'right';
  return null;
}

List<Map<String, dynamic>> _buildFramesForContext(Database db, String contextKey) {
  final result = db.select(
    'SELECT key, seq, spatial_turn FROM entries WHERE parentKey = ? ORDER BY seq ASC',
    [contextKey],
  );
  final bySeq = <int, String>{};
  final turnBySeq = <int, String>{};
  for (final row in result) {
    final seq = row['seq'];
    final key = row['key'];
    if (seq == null || seq is! int) {
      throw StateError('seq inválido');
    }
    if (seq < 0 || seq > 19) {
      throw StateError('seq fuera de rango 0..19');
    }
    final k = key?.toString() ?? '';
    if (k.isEmpty) {
      throw StateError('key vacío en DB');
    }
    if (bySeq.containsKey(seq)) {
      throw StateError('seq duplicado');
    }
    bySeq[seq] = k;
    final st = _normalizeSpatialTurnForSnapshot(row['spatial_turn']);
    if (st != null) {
      turnBySeq[seq] = st;
    }
  }

  final frames = <Map<String, dynamic>>[];
  for (var s = 0; s < 20; s++) {
    final m = <String, dynamic>{
      'key': bySeq.containsKey(s) ? bySeq[s]! : '',
      'seq': s,
    };
    final t = turnBySeq[s];
    if (t != null) {
      m['spatialTurn'] = t;
    }
    frames.add(m);
  }
  return frames;
}

/// Incluye [contextKey] para que GateKeeper no aplique `current.json` de un nivel hijo
/// cuando el bridge ya apunta al padre (ORM: Back / Enter antes de LibraryBuild).
Map<String, dynamic> _snapshotEnvelope(String contextKey, List<Map<String, dynamic>> frames) {
  return {
    'version': DateTime.now().millisecondsSinceEpoch,
    'valid': true,
    'contextKey': contextKey,
    'frames': frames,
  };
}

String? _recallCropSrcFromParsedBody(List<Map<String, dynamic>> fullBody) {
  for (final b in fullBody) {
    if (b['type'] != 'img') continue;
    final r = (b['role'] ?? '').toString().toLowerCase().trim();
    if (r == 'recall_crop') {
      final s = (b['src'] ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
  }
  return null;
}

/// Cuatro opciones (1 correcta + 3 distractores del mismo parcour) para GateKeeper; vacío si faltan archivos.
List<Map<String, dynamic>> _buildRecallCropQuizOptions(
  Database db,
  String focusKey,
  String parentKey,
  String currentSrc,
) {
  if (focusKey.isEmpty || parentKey.isEmpty || currentSrc.isEmpty) return [];
  final sep = Platform.pathSeparator;
  final assetsRoot = AlexandriaPaths.assetsRoot;

  bool fileOk(String ek, String src) {
    if (ek.isEmpty || src.isEmpty) return false;
    final normalized = src.replaceAll('/', sep);
    final f = File('$assetsRoot$sep$ek$sep$normalized');
    return f.existsSync();
  }

  if (!fileOk(focusKey, currentSrc)) return [];

  final rows = db.select(
    'SELECT key, body_text FROM entries WHERE parentKey = ? AND key != ?',
    [parentKey, focusKey],
  );
  final distractors = <({String k, String s})>[];
  for (final r in rows) {
    final k = r['key']?.toString().trim() ?? '';
    if (k.isEmpty) continue;
    final parsed = parseBody(r['body_text']?.toString());
    final src = _recallCropSrcFromParsedBody(parsed);
    if (src == null || src.isEmpty) continue;
    if (!fileOk(k, src)) continue;
    distractors.add((k: k, s: src));
  }
  distractors.shuffle(math.Random());
  if (distractors.length < 3) return [];
  final picked = distractors.sublist(0, 3);
  final out = <Map<String, dynamic>>[
    {'entryKey': focusKey, 'src': currentSrc, 'correct': true},
    for (final d in picked)
      {'entryKey': d.k, 'src': d.s, 'correct': false},
  ];
  out.shuffle(math.Random());
  return out;
}

Map<String, dynamic> _buildViewerPayload(Database db, String focusKey) {
  if (focusKey.isEmpty) {
    return {
      'key': '',
      'parentKey': '',
      'body': <Map<String, dynamic>>[
        {
          'type': 'p',
          'text':
              'Sin KEY de foco (slot vacío). Índice espacial: revisa data/bridge/current_seq.txt.',
        },
      ],
      'assets': <Map<String, dynamic>>[],
      'hasChildren': false,
      'cognitiveRole': '',
      'nextReviewAt': '',
      'version': DateTime.now().millisecondsSinceEpoch,
    };
  }

  final rows = db.select(
    'SELECT body_text, next_review_at, memory_strength, stability_days, recall_score, review_count, success_count, failure_count, cognitiveRole, COALESCE(place_recall_active, 0) AS place_recall_active FROM entries WHERE key = ? LIMIT 1',
    [focusKey],
  );

  var body = <Map<String, dynamic>>[];
  var fullParsed = <Map<String, dynamic>>[];
  String nextReviewAt = '';
  String cognitiveRole = '';
  double memoryStrength = 0.0;
  double stabilityDays = 0.0;
  double recallScore = 0.0;
  int reviewCount = 0;
  int successCount = 0;
  int failureCount = 0;
  var placeRecallActive = false;
  if (rows.isNotEmpty) {
    final raw = rows.first['body_text'] as String?;
    fullParsed = parseBody(raw);
    body = fullParsed.where((b) {
      if (b['type'] != 'img') return true;
      final r = (b['role'] ?? 'content').toString().toLowerCase().trim();
      return r != 'collage' && r != 'recall_crop';
    }).toList();
    nextReviewAt = rows.first['next_review_at']?.toString() ?? '';
    cognitiveRole = rows.first['cognitiveRole']?.toString().trim() ?? '';
    memoryStrength = _asDouble(rows.first['memory_strength'], 0.0);
    stabilityDays = _asDouble(rows.first['stability_days'], 0.0);
    recallScore = _asDouble(rows.first['recall_score'], 0.0);
    reviewCount = _asInt(rows.first['review_count'], 0);
    successCount = _asInt(rows.first['success_count'], 0);
    failureCount = _asInt(rows.first['failure_count'], 0);
    placeRecallActive = _asInt(rows.first['place_recall_active'], 0) != 0;
  }

  final assetsList = <Map<String, dynamic>>[];
  try {
    final master = db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='assets'",
    );
    if (master.isNotEmpty) {
      final ar = db.select(
        'SELECT assetKey, fileName FROM assets WHERE entryKey = ?',
        [focusKey],
      );
      for (final r in ar) {
        assetsList.add({
          'assetKey': r['assetKey']?.toString() ?? '',
          'fileName': r['fileName']?.toString() ?? '',
        });
      }
    }
  } catch (_) {}

  final childCountRows = db.select(
    'SELECT COUNT(*) AS c FROM entries WHERE parentKey = ?',
    [focusKey],
  );
  final cVal = childCountRows.isNotEmpty ? childCountRows.first['c'] : 0;
  final childCount = _sqliteCountToInt(cVal);
  final hasChildren = childCount > 0;
  String parentKey = '';
  final parentRows = db.select(
    'SELECT parentKey FROM entries WHERE key = ? LIMIT 1',
    [focusKey],
  );
  if (parentRows.isNotEmpty && parentRows.first['parentKey'] != null) {
    parentKey = parentRows.first['parentKey'].toString();
  }

  var recallCropSrc = '';
  var recallCropQuiz = <Map<String, dynamic>>[];
  final extractedCrop = _recallCropSrcFromParsedBody(fullParsed);
  if (extractedCrop != null &&
      extractedCrop.isNotEmpty &&
      parentKey.isNotEmpty) {
    recallCropSrc = extractedCrop;
    final q = _buildRecallCropQuizOptions(db, focusKey, parentKey, extractedCrop);
    if (q.length >= 4) recallCropQuiz = q;
  }

  return {
    'key': focusKey,
    'parentKey': parentKey,
    'body': body,
    'assets': assetsList,
    'hasChildren': hasChildren,
    'cognitiveRole': cognitiveRole,
    'nextReviewAt': nextReviewAt,
    'memoryStrength': memoryStrength,
    'stabilityDays': stabilityDays,
    'recallScore': recallScore,
    'reviewCount': reviewCount,
    'successCount': successCount,
    'failureCount': failureCount,
    'placeRecallActive': placeRecallActive,
    'recallCropSrc': recallCropSrc,
    'recallCropQuiz': recallCropQuiz,
    'version': DateTime.now().millisecondsSinceEpoch,
  };
}

/// Escribe viewer JSON para [focusKey]. Si está vacío (EMPTY / sin fila), payload mínimo coherente con ACUERDO v3.
///
/// GateKeeper lee `data/viewer/{focusKey}.json` cuando hay foco ([ViewerService]); si solo existiera
/// `current.json`, el panel caería en fallback y mostraría **parentKey** de otra fila (p. ej. ROOT),
/// y ← Back saltaría a realm sin pasar por parcour (PARCOUR_MAIN / Lk). Por eso duplicamos el payload
/// en la ruta keyed siempre que [focusKey] no esté vacío.
void writeViewerForFocusKey(Database db, String focusKey) {
  final viewerPath = '${AlexandriaPaths.viewerRoot}/current.json';
  final payload = _buildViewerPayload(db, focusKey);

  final f = File(viewerPath);
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(jsonEncode(payload));
  print('[LB][VIEWER_WRITE] $viewerPath key=$focusKey');

  if (focusKey.isNotEmpty) {
    final keyedPath = '${AlexandriaPaths.viewerRoot}/$focusKey.json';
    final keyed = File(keyedPath);
    keyed.parent.createSync(recursive: true);
    keyed.writeAsStringSync(jsonEncode(payload));
    print('[LB][VIEWER_WRITE] $keyedPath key=$focusKey');
  }
}

void buildViewerForKey(String key) {
  final dbPath = AlexandriaPaths.dbPath;
  if (!File(dbPath).existsSync()) return;
  final db = sqlite3.open(dbPath);
  try {
    ensureLibrarySchema(db);
    final payload = _buildViewerPayload(db, key);
    final outPath = '${AlexandriaPaths.viewerRoot}/$key.json';
    final f = File(outPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(jsonEncode(payload));
    _writeWallManifestForKey(db, key);
  } finally {
    db.dispose();
  }
}

void buildSnapshotForContext(String contextKey) {
  final dbPath = AlexandriaPaths.dbPath;
  if (!File(dbPath).existsSync()) return;
  final db = sqlite3.open(dbPath);
  try {
    ensureLibrarySchema(db);
    final frames = _buildFramesForContext(db, contextKey);
    final outPath = '${AlexandriaPaths.snapshotRoot}/$contextKey.json';
    final f = File(outPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(jsonEncode(_snapshotEnvelope(contextKey, frames)));
  } finally {
    db.dispose();
  }
}

void buildAll() {
  final dbPath = AlexandriaPaths.dbPath;
  final db = sqlite3.open(dbPath);
  try {
    ensureLibrarySchema(db);
    final keys = <String>{'ROOT'};
    final rows = db.select('SELECT key FROM entries');
    for (final row in rows) {
      final key = row['key']?.toString() ?? '';
      if (key.isNotEmpty) keys.add(key);
    }
    for (final key in keys) {
      try {
        final frames = _buildFramesForContext(db, key);
        final snapshotFile = File('${AlexandriaPaths.snapshotRoot}/$key.json');
        snapshotFile.parent.createSync(recursive: true);
        snapshotFile.writeAsStringSync(jsonEncode(_snapshotEnvelope(key, frames)));
      } catch (_) {}

      final viewerFile = File('${AlexandriaPaths.viewerRoot}/$key.json');
      viewerFile.parent.createSync(recursive: true);
      viewerFile.writeAsStringSync(jsonEncode(_buildViewerPayload(db, key)));
      _writeWallManifestForKey(db, key);
    }
    print('[LB][BUILD_ALL] Completado. keys=${keys.length}');
  } finally {
    db.dispose();
  }
}

/// Compat: LocusEditor y scripts; delega en [writeViewerForFocusKey].
void writeViewerCurrentJson(Database db, String key) {
  writeViewerForFocusKey(db, key);
}

/// Polling liviano: solo `focus_key.txt` (Fase 3 — sin open_key).
void syncViewerFromFocusKey() {
  final dbPath = AlexandriaPaths.dbPath;

  if (!File(dbPath).existsSync()) return;

  ensureDualBridgeDefaults();

  final focusKey = readFocusKeyWithFallback();
  final dedupe = focusKey.isEmpty ? '\u0000EMPTY' : focusKey;
  if (_lastViewerKey == dedupe) return;
  _lastViewerKey = dedupe;

  final db = sqlite3.open(dbPath);
  try {
    ensureLibrarySchema(db);
    writeViewerForFocusKey(db, focusKey);
  } finally {
    db.dispose();
  }
}

int _readBridgeCurrentSeq() {
  try {
    final f = File(AlexandriaPaths.bridgeCurrentSeqPath);
    if (!f.existsSync()) return 0;
    return int.tryParse(f.readAsStringSync().trim()) ?? 0;
  } catch (_) {
    return 0;
  }
}

/// Guarda seq para la key del contexto que se abandona (mapa por KEY; no pisa otras keys).
void _mergeLastPositionByKey(String previousKey, int seq) {
  if (previousKey.isEmpty) return;
  try {
    Directory(File(AlexandriaPaths.bridgeLastPositionPath).parent.path).createSync(recursive: true);
    final byKey = <String, int>{};
    final f = File(AlexandriaPaths.bridgeLastPositionPath);
    if (f.existsSync()) {
      final decoded = jsonDecode(f.readAsStringSync());
      if (decoded is Map && decoded['byKey'] is Map) {
        for (final e in (decoded['byKey'] as Map).entries) {
          final k = e.key.toString();
          final v = e.value;
          if (v is int) byKey[k] = v;
          if (v is num) byKey[k] = v.toInt();
        }
      }
    }
    byKey[previousKey] = seq;
    f.writeAsStringSync(jsonEncode({'byKey': byKey}));
    print('[LB][LAST_POS] byKey[$previousKey]=$seq');
  } catch (e) {
    print('[LB][LAST_POS_ERR] $e');
  }
}

/// Número de filas en `entries` del esqueleto ORM homogéneo:
/// ROOT + PARCOUR_MAIN + L1…L20 + 400 objetos (Lk_O01…Lk_O20).
const int kAlexandriaHomogeneousEntryCount = 422;

/// Devuelve `true` si detectó el bootstrap erróneo histórico (A/B/C bajo ROOT) y lo reemplazó.
bool _repairLegacyAbcBootstrapIfNeeded(Database db) {
  final hadAbc = db.select(
    "SELECT 1 FROM entries WHERE key IN ('A','B','C') LIMIT 1",
  ).isNotEmpty;
  final hadHub = db.select(
    "SELECT 1 FROM entries WHERE key = ? LIMIT 1",
    [_primaryParcourKey],
  ).isNotEmpty;
  if (!hadAbc || hadHub) return false;
  print('[LB][SEED] reparando bootstrap legacy (A,B,C) → esqueleto ORM');
  db.execute('DELETE FROM entries');
  _insertHomogeneousSkeletonIfNeeded(db);
  _normalizeRealmParcourLanguage(db);
  ensureLibrarySchema(db);
  _stripUserFacingData(db);
  return true;
}

/// Si `entries` está vacía (o acaba de repararse el legacy), inserta el árbol ORM completo.
void ensureAlexandriaRealmSeededIfEmpty(Database db) {
  ensureLibrarySchema(db);
  if (_repairLegacyAbcBootstrapIfNeeded(db)) return;
  final c = _sqliteCountToInt(
    db.select('SELECT COUNT(*) AS c FROM entries').first['c'],
  );
  if (c != 0) return;
  print('[LB][SEED] esqueleto ORM homogéneo ($kAlexandriaHomogeneousEntryCount nodos)');
  _insertHomogeneousSkeletonIfNeeded(db);
  _normalizeRealmParcourLanguage(db);
  ensureLibrarySchema(db);
}

void runLibraryBuild() {

  final dbPath = AlexandriaPaths.dbPath;
  final snapshotPath = AlexandriaPaths.snapshotCurrentJsonPath;

  final db = sqlite3.open(dbPath);

  try {

  ensureLibrarySchema(db);
  ensureAlexandriaRealmSeededIfEmpty(db);
  writeParcourReviewBridgeSummary(db);
  _normalizeRealmParcourLanguage(db);
  _rebuildAllWallManifests(db);
  _exportNavigationBundleAtomically(db);

  ensureDualBridgeDefaults();

  final contextKey = readContextKeyWithFallback();
  final focusKey = readFocusKeyWithFallback();

  print('[LB][SNAPSHOT_PARENT] context_key=$contextKey (solo context_key.txt)');
  print('[LB][VIEWER_FOCUS] focus_key=${focusKey.isEmpty ? "(empty)" : focusKey}');

  final frames = _buildFramesForContext(db, contextKey);
  print('[LB][ROWS] ${frames.where((e) => (e['key'] as String).isNotEmpty).length}');

  final snapFile = File(snapshotPath);
  snapFile.parent.createSync(recursive: true);

  final snapshot = _snapshotEnvelope(contextKey, frames);
  snapFile.writeAsStringSync(jsonEncode(snapshot));
  print('[LB][FRAMES_COUNT] ${frames.length} (fijo #357)');
  print('[LB][SNAPSHOT_FRAMES] count=${frames.length}');
  print('[LB][SNAPSHOT_WRITE] $snapshotPath');
  final keyedSnapshotPath = '${AlexandriaPaths.snapshotRoot}/$contextKey.json';
  final keyedSnapshotFile = File(keyedSnapshotPath);
  keyedSnapshotFile.parent.createSync(recursive: true);
  keyedSnapshotFile.writeAsStringSync(jsonEncode(snapshot));
  print('[LB][SNAPSHOT_WRITE] $keyedSnapshotPath');

  try {
    writeViewerForFocusKey(db, focusKey);
    _writeWallManifestForKey(db, focusKey);
    _lastViewerKey = focusKey.isEmpty ? '\u0000EMPTY' : focusKey;
  } finally {
    // A15: trigger GK reload; no depende de éxito del viewer (snapshot ya está en disco)
    _writeRefreshNowTrigger();
  }

  // [Cambio 353] Tras snapshot/viewer OK: seq del contexto abandonado (GK → current_seq.txt).
  if (_lastBridgeParentKey.isNotEmpty &&
      contextKey.isNotEmpty &&
      contextKey != _lastBridgeParentKey) {
    final seq = _readBridgeCurrentSeq();
    _mergeLastPositionByKey(_lastBridgeParentKey, seq);
  }
  _lastBridgeParentKey = contextKey;

  } finally {
    db.dispose();
  }

}

/// GateKeeper (`Spawner`) lee `snapshot/current.json` bajo el realm activo; sin ese archivo no aplica
/// el snapshot aunque `alexandria.db` exista. Ver ORM-16-05-LB-GK-DataRecovery.
void ensureGatekeeperSnapshotArtifactsSync() {
  final f = File(AlexandriaPaths.snapshotCurrentJsonPath);
  if (f.existsSync()) return;
  try {
    print('[LB][GK] snapshot/current.json ausente → runLibraryBuild()');
    runLibraryBuild();
  } catch (e, st) {
    print('[LB][GK_SYNC_ERR] $e\n$st');
  }
}

/// Árbol fijo ORM: `ROOT` → `PARCOUR_MAIN` → `L1`…`L20` → `Lk_O01`…`Lk_O20` ([kAlexandriaHomogeneousEntryCount] filas; ver `_normalizeRealmParcourLanguage`).
void _insertHomogeneousSkeletonIfNeeded(Database db) {
  if (db.select('SELECT 1 FROM entries WHERE key = ? LIMIT 1', [_realmKey]).isEmpty) {
    db.execute(
      "INSERT INTO entries (key, parentKey, seq, cognitiveRole, title) VALUES ('ROOT', NULL, 0, 'realm', 'R1')",
    );
  }
  if (db.select('SELECT 1 FROM entries WHERE key = ? LIMIT 1', [_primaryParcourKey]).isEmpty) {
    db.execute(
      "INSERT INTO entries (key, parentKey, seq, cognitiveRole, title) VALUES ('PARCOUR_MAIN', 'ROOT', 0, 'parcour', 'Parcours (R1)')",
    );
  }
  for (var i = 0; i < 20; i++) {
    final lk = 'L${i + 1}';
    if (db.select('SELECT 1 FROM entries WHERE key = ? LIMIT 1', [lk]).isEmpty) {
      db.execute(
        'INSERT INTO entries (key, parentKey, seq, cognitiveRole, title) VALUES (?, ?, ?, ?, ?)',
        [lk, _primaryParcourKey, i, 'parcour', lk],
      );
    }
  }
}

/// Misma base SQLite que [createEmptyRealm]: esquema + árbol homogéneo + sin datos de usuario.
void bootstrapEmptyRealmDatabase(Database db) {
  db.execute('''
CREATE TABLE IF NOT EXISTS entries (
  key TEXT PRIMARY KEY,
  parentKey TEXT,
  seq INTEGER
)
''');
  ensureLibrarySchema(db);
  _insertHomogeneousSkeletonIfNeeded(db);
  _normalizeRealmParcourLanguage(db);
  ensureLibrarySchema(db);
  _stripUserFacingData(db);
}

/// Quita **datos** (texto/imágenes en `body_text`, recall/review); la forma del árbol no cambia.
void _stripUserFacingData(Database db) {
  db.execute('UPDATE entries SET body_text = NULL');
  db.execute('''
    UPDATE entries SET
      last_reviewed_at = NULL,
      next_review_at = NULL,
      last_review_grade = NULL,
      review_count = 0,
      success_count = 0,
      failure_count = 0,
      memory_strength = NULL,
      stability_days = NULL,
      recall_score = NULL
  ''');
  if (_tableExists(db, 'locus_review_state')) {
    db.execute('DELETE FROM locus_review_state');
  }
  if (_tableExists(db, 'locus_review_events')) {
    db.execute('DELETE FROM locus_review_events');
  }
  if (_tableExists(db, 'review_events')) {
    db.execute('DELETE FROM review_events');
  }
  if (_tableExists(db, 'assets')) {
    db.execute('DELETE FROM assets');
  }
}

/// Carpetas bajo [AlexandriaPaths.assetsRoot] que no son `key` en `entries` ni whitelist (p. ej. PAO).
const Set<String> kRealmSeedAssetDirWhitelist = {'pao'};

/// Limpia textos (`body_text`), métricas en columnas de `entries`, tablas de eventos, Parcour Review,
/// filas `assets` y PAO estándar; reconstruye FTS. **No** elimina filas de `entries` (árbol ORM intacto).
void applyRealmSeedSanitization(Database db) {
  ensureLibrarySchema(db);
  ensureParcourReviewSchema(db);
  ensurePaoStandardSchema(db);
  ensurePaoPhoneticSchema(db);
  _stripUserFacingData(db);
  if (_tableExists(db, 'parcour_review_session_loci')) {
    db.execute('DELETE FROM parcour_review_session_loci');
  }
  if (_tableExists(db, 'parcour_review_sessions')) {
    db.execute('DELETE FROM parcour_review_sessions');
  }
  if (_tableExists(db, 'parcour_review_state')) {
    db.execute('DELETE FROM parcour_review_state');
  }
  if (_tableExists(db, 'pao_standard')) {
    db.execute('DELETE FROM pao_standard');
  }
  if (_tableExists(db, 'pao_phonetic')) {
    db.execute('DELETE FROM pao_phonetic');
  }
  if (_tableExists(db, 'lb_poker_memory_ranges')) {
    db.execute('DELETE FROM lb_poker_memory_ranges');
  }
  ensurePokerMemorySchema(db);
  rebuildEntriesFts5(db);
}

/// Borra directorios en `assets/` cuyo nombre no es un `entries.key` ni está en [kRealmSeedAssetDirWhitelist].
void pruneRealmAssetFoldersNotInEntries(Database db) {
  final keyRows = db.select('SELECT key FROM entries');
  final keys = keyRows.map((r) => r['key'] as String).toSet();
  final root = Directory(AlexandriaPaths.assetsRoot);
  if (!root.existsSync()) return;
  for (final e in root.listSync()) {
    if (e is! Directory) continue;
    final name = e.path.split(Platform.pathSeparator).last;
    if (kRealmSeedAssetDirWhitelist.contains(name)) continue;
    if (keys.contains(name)) continue;
    try {
      e.deleteSync(recursive: true);
      print('[RealmSeed] removed orphan asset dir: $name');
    } catch (_) {}
  }
}

/// Copia `alexandria.db` del **realm activo** a [AlexandriaPaths.realmSeedDbPath] (clon repetible versionable).
void copyActiveRealmDbToRealmSeedSnapshotSync() {
  final src = File(AlexandriaPaths.dbPath);
  if (!src.existsSync()) {
    print('[RealmSeed] skip copy: no DB at ${AlexandriaPaths.dbPath}');
    return;
  }
  final outDir = Directory(AlexandriaPaths.realmSeedDir);
  outDir.createSync(recursive: true);
  final dst = File(AlexandriaPaths.realmSeedDbPath);
  src.copySync(dst.path);
  print('[RealmSeed] snapshot → ${dst.path}');
}

/// Limpia textos/métricas del realm activo, poda carpetas `assets/` huérfanas, [runLibraryBuild] y copia la DB a `data/realm_seed/`.
void regenerateRealmSeedFromActiveRealmSync() {
  final dbPath = AlexandriaPaths.dbPath;
  if (!File(dbPath).existsSync()) {
    throw StateError('No alexandria.db at $dbPath');
  }
  final db = sqlite3.open(dbPath);
  try {
    applyRealmSeedSanitization(db);
    pruneRealmAssetFoldersNotInEntries(db);
  } finally {
    db.dispose();
  }
  runLibraryBuild();
  copyActiveRealmDbToRealmSeedSnapshotSync();
}

/// Realm **nuevo** sin copiar otro: mismo **esqueleto** que un mundo completo (20 parcours + 400 objetos bajo el hub),
/// pero **sin datos** (sin texto en `body_text`, sin recall/review; `assets/` vacío al crear).
bool createEmptyRealm(String rawId) {
  final id = AlexandriaPaths.sanitizeRealmPath(rawId);
  final root = Directory(AlexandriaPaths.realmDataRoot(id));
  if (root.existsSync()) return false;

  try {
    root.createSync(recursive: true);
    Directory('${root.path}/bridge').createSync(recursive: true);
    Directory('${root.path}/snapshot').createSync(recursive: true);
    Directory('${root.path}/viewer').createSync(recursive: true);
    Directory('${root.path}/assets').createSync(recursive: true);
    Directory('${root.path}/manifests/wall').createSync(recursive: true);

    final dbPath = '${AlexandriaPaths.realmDataRoot(id)}/alexandria.db';
    final db = sqlite3.open(dbPath);
    try {
      bootstrapEmptyRealmDatabase(db);
    } finally {
      db.dispose();
    }

    File('${root.path}/bridge/context_key.txt').writeAsStringSync('ROOT');
    File('${root.path}/bridge/focus_key.txt').writeAsStringSync('');
    print('[LB][REALM_EMPTY] $id (árbol homogéneo, sin datos de usuario)');
    return true;
  } catch (e, st) {
    print('[LB][REALM_EMPTY_ERR] $e\n$st');
    try {
      if (root.existsSync()) root.deleteSync(recursive: true);
    } catch (_) {}
    return false;
  }
}

/// Frase exacta que el usuario debe escribir para confirmar borrado total (mayúsculas/minúsculas).
const String kAlexandriaNuclearDeletePhrase = 'Alexandria delete';

void _deleteDirectoryRecursiveSync(Directory dir) {
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(followLinks: false)) {
    if (e is Directory) {
      _deleteDirectoryRecursiveSync(Directory(e.path));
    } else {
      try {
        e.deleteSync();
      } catch (_) {}
    }
  }
  try {
    dir.deleteSync();
  } catch (_) {}
}

/// Copia tablas PAO + Match cards desde [backupDbPath] hacia [targetDbPath] (realm nuevo).
void _mergePreservedLibraryTrainingDataSync(String targetDbPath, String backupDbPath) {
  if (!File(backupDbPath).existsSync()) return;
  final db = sqlite3.open(targetDbPath);
  try {
    db.execute('PRAGMA foreign_keys = OFF');
    final esc = backupDbPath.replaceAll('\\', '/').replaceAll("'", "''");
    db.execute("ATTACH '$esc' AS _pres");
    bool hasPres(String t) {
      final r = db.select(
        "SELECT 1 FROM _pres.sqlite_master WHERE type='table' AND name=? LIMIT 1",
        [t],
      );
      return r.isNotEmpty;
    }
    if (hasPres('lb_match_pair_fsrs_state')) {
      db.execute('DELETE FROM lb_match_pair_fsrs_state');
    }
    if (hasPres('lb_match_pairs')) {
      db.execute('DELETE FROM lb_match_pairs');
    }
    if (hasPres('lb_match_decks')) {
      db.execute('DELETE FROM lb_match_decks');
    }
    if (hasPres('pao_standard')) {
      db.execute('DELETE FROM pao_standard');
    }
    if (hasPres('pao_phonetic')) {
      db.execute('DELETE FROM pao_phonetic');
    }
    if (hasPres('lb_match_decks')) {
      db.execute('INSERT INTO lb_match_decks SELECT * FROM _pres.lb_match_decks');
    }
    if (hasPres('lb_match_pairs')) {
      db.execute('INSERT INTO lb_match_pairs SELECT * FROM _pres.lb_match_pairs');
    }
    if (hasPres('lb_match_pair_fsrs_state')) {
      db.execute(
        'INSERT INTO lb_match_pair_fsrs_state SELECT * FROM _pres.lb_match_pair_fsrs_state',
      );
    }
    if (hasPres('pao_standard')) {
      db.execute('INSERT INTO pao_standard SELECT * FROM _pres.pao_standard');
    }
    if (hasPres('pao_phonetic')) {
      db.execute('INSERT INTO pao_phonetic SELECT * FROM _pres.pao_phonetic');
    }
    db.execute('DETACH DATABASE _pres');
    db.execute('PRAGMA foreign_keys = ON');
  } catch (e, st) {
    print('[LB][NUCLEAR_MERGE] $e\n$st');
    try {
      db.execute('DETACH DATABASE _pres');
    } catch (_) {}
  } finally {
    db.dispose();
  }
}

void _nuclearRestorePreservedTrainingData(Directory staging) {
  final sep = Platform.pathSeparator;
  final backupDb = File('${staging.path}${sep}preserved.sqlite');
  final matchStaging = Directory('${staging.path}${sep}lb_match_cards');
  if (backupDb.existsSync()) {
    _mergePreservedLibraryTrainingDataSync(AlexandriaPaths.dbPath, backupDb.path);
  }
  if (matchStaging.existsSync()) {
    final dst = Directory('${AlexandriaPaths.assetsRoot}${sep}lb_match_cards');
    if (dst.existsSync()) {
      _deleteDirectoryRecursiveSync(dst);
    }
    AlexandriaPaths.copyDirectoryTreeContents(matchStaging, dst);
  }
  try {
    _deleteDirectoryRecursiveSync(staging);
  } catch (_) {}
}

/// Quita JSON de usuario en `data/pao/` (conserva `*.template.json` y nombres con `.template.`).
void _pruneNonTemplatePaoDatasetJsonFilesSync() {
  final dir = Directory(AlexandriaPaths.paoDatasetDir);
  if (!dir.existsSync()) return;
  for (final e in dir.listSync()) {
    if (e is! File) continue;
    final name = e.path.split(Platform.pathSeparator).last;
    final lower = name.toLowerCase();
    if (lower.endsWith('.template.json')) continue;
    if (lower.contains('.template.')) continue;
    if (!lower.endsWith('.json')) continue;
    try {
      e.deleteSync();
    } catch (_) {}
  }
}

/// Limpia tablas PAO en la DB del realm activo y JSON opcional en `data/pao/`.
void performPaoLibraryDataCleanupSync() {
  final p = AlexandriaPaths.dbPath;
  if (!File(p).existsSync()) return;
  final db = sqlite3.open(p);
  try {
    ensureLibrarySchema(db);
    if (_tableExists(db, 'pao_standard')) {
      db.execute('DELETE FROM pao_standard');
    }
    if (_tableExists(db, 'pao_phonetic')) {
      db.execute('DELETE FROM pao_phonetic');
    }
  } finally {
    db.dispose();
  }
  _pruneNonTemplatePaoDatasetJsonFilesSync();
}

/// Limpia Match cards en la DB del realm activo y `assets/lb_match_cards/`.
void performMatchCardsLibraryDataCleanupSync() {
  final p = AlexandriaPaths.dbPath;
  if (!File(p).existsSync()) return;
  final db = sqlite3.open(p);
  try {
    ensureLibrarySchema(db);
    if (_tableExists(db, 'lb_match_pair_fsrs_state')) {
      db.execute('DELETE FROM lb_match_pair_fsrs_state');
    }
    if (_tableExists(db, 'lb_match_pairs')) {
      db.execute('DELETE FROM lb_match_pairs');
    }
    if (_tableExists(db, 'lb_match_decks')) {
      db.execute('DELETE FROM lb_match_decks');
    }
    ensureLibrarySchema(db);
  } finally {
    db.dispose();
  }
  final sep = Platform.pathSeparator;
  final d = Directory('${AlexandriaPaths.assetsRoot}${sep}lb_match_cards');
  if (d.existsSync()) {
    _deleteDirectoryRecursiveSync(d);
  }
}

/// Borra **toda** la data bajo `data/`: `realms/`, `realm_shelf.json`.
/// **No** borra `data/pao/` en disco; las tablas PAO y Match cards del realm activo se **preservan**
/// en la nueva `data/realms/default/alexandria.db` (y las imágenes en `assets/lb_match_cards/`).
/// Deja `active_realm.txt` → `default` y `data/realms/default/alexandria.db` con esqueleto ORM ([kAlexandriaHomogeneousEntryCount] nodos, sin datos de usuario).
/// Cierra cualquier conexión SQLite a ese archivo en el proceso **antes** de llamar.
/// Si aún no existe `data/realms/default/alexandria.db` y hay plantilla en [AlexandriaPaths.bundledDefaultRealmRoot], copia todo el árbol (imágenes, snapshot, etc.).
void ensureDefaultRealmOnDiskFromBundledTemplateSync() {
  final sep = Platform.pathSeparator;
  final dbPath = AlexandriaPaths.dbPath;
  if (File(dbPath).existsSync()) return;
  final bundledRoot = Directory(AlexandriaPaths.bundledDefaultRealmRoot);
  final bundledDb = File('${bundledRoot.path}${sep}alexandria.db');
  if (!bundledDb.existsSync()) return;
  final destRoot = Directory(AlexandriaPaths.realmDataRoot('default'));
  destRoot.createSync(recursive: true);
  AlexandriaPaths.copyDirectoryTreeContents(bundledRoot, destRoot);
  print(
    '[LB][BUNDLED_DEFAULT] data/realms/default ← ${AlexandriaPaths.bundledDefaultRealmRoot}',
  );
}

void performAlexandriaNuclearDataResetSync() {
  final sep = Platform.pathSeparator;
  final repo = AlexandriaPaths.repoRoot;
  final staging = Directory('$repo${sep}data${sep}.lb_nuclear_preserve');
  if (staging.existsSync()) {
    _deleteDirectoryRecursiveSync(staging);
  }
  staging.createSync(recursive: true);
  final backupDb = File('${staging.path}${sep}preserved.sqlite');
  final currentDbPath = AlexandriaPaths.dbPath;
  if (File(currentDbPath).existsSync()) {
    try {
      File(currentDbPath).copySync(backupDb.path);
    } catch (e) {
      print('[LB][NUCLEAR_BACKUP_DB] $e');
    }
  }
  final activeBefore = AlexandriaPaths.readActiveRealmId();
  final matchSrc = Directory(
    '${AlexandriaPaths.realmDataRoot(activeBefore)}${sep}assets${sep}lb_match_cards',
  );
  final matchStaging = Directory('${staging.path}${sep}lb_match_cards');
  if (matchSrc.existsSync()) {
    AlexandriaPaths.copyDirectoryTreeContents(matchSrc, matchStaging);
  }

  final dataDir = Directory('$repo${sep}data');
  final realmsDir = Directory('$repo${sep}data${sep}realms');
  if (realmsDir.existsSync()) {
    _deleteDirectoryRecursiveSync(realmsDir);
  }
  final shelf = File('$repo${sep}data${sep}realm_shelf.json');
  if (shelf.existsSync()) {
    try {
      shelf.deleteSync();
    } catch (_) {}
  }
  dataDir.createSync(recursive: true);
  File('$repo${sep}data${sep}active_realm.txt').writeAsStringSync('default');
  final realmRoot = Directory(AlexandriaPaths.realmDataRoot('default'));
  realmRoot.createSync(recursive: true);
  final bundledRoot = Directory(AlexandriaPaths.bundledDefaultRealmRoot);
  final bundledDb = File('${bundledRoot.path}${sep}alexandria.db');
  if (bundledRoot.existsSync() && bundledDb.existsSync()) {
    AlexandriaPaths.copyDirectoryTreeContents(bundledRoot, realmRoot);
    _nuclearRestorePreservedTrainingData(staging);
    copyActiveRealmDbToRealmSeedSnapshotSync();
    print(
      '[LB][NUCLEAR] default from bundled_default_realm + realm_seed; active_realm=default (PAO/Match preserved)',
    );
    return;
  }
  final dbPath = '${realmRoot.path}/alexandria.db';
  final existingDb = File(dbPath);
  if (existingDb.existsSync()) {
    try {
      existingDb.deleteSync();
    } catch (_) {}
  }
  final db = sqlite3.open(dbPath);
  try {
    bootstrapEmptyRealmDatabase(db);
  } finally {
    db.dispose();
  }
  _nuclearRestorePreservedTrainingData(staging);
  copyActiveRealmDbToRealmSeedSnapshotSync();
  print(
    '[LB][NUCLEAR] reset: default/alexandria.db + data/realm_seed/alexandria.db + active_realm=default (PAO/Match preserved)',
  );
}

