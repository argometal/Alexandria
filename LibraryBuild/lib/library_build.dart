import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:sqlite3/sqlite3.dart';

import 'alexandria_paths.dart';

export 'locus_review_metrics.dart';

/// [Cambio 341] Evita re-escritura de viewer si el foco (dual bridge) no cambió.
String? _lastViewerKey;

/// [Cambio 353] Último parent procesado en `runLibraryBuild` (detectar cambio de contexto).
String _lastBridgeParentKey = '';

const _realmKey = 'ROOT';
const _primaryParcourKey = 'PARCOUR_MAIN';

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
  } catch (e) {
    print('[LB][BRIDGE_DEFAULT_ERR] $e');
  }
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
  } catch (_) {}
  for (final base in [
    AlexandriaPaths.snapshotRoot,
    AlexandriaPaths.viewerRoot,
    AlexandriaPaths.wallManifestRoot,
  ]) {
    try {
      final f = File('$base/$key.json');
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}

void _deleteEntryRowAndRelated(Database db, String key) {
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
/// Conserva `img` y `link` (A15 / viewer GK); el resto → `p`.
/// Incluye `textKind` en párrafos (LB / estudio; GK ignora campos extra).
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
        out.add({'type': 'img', 'src': src});
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
            'textKind': _inferParagraphTextKind(m, tLower),
          });
        }
        continue;
      }

      out.add({
        'type': 'p',
        'text': (m['text'] ?? '').toString(),
        'textKind': _inferParagraphTextKind(m, tLower),
      });
    }
    return out;
  } catch (_) {
    return [];
  }
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
      final role = (m['role'] ?? '').toString().toLowerCase().trim();
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

List<Map<String, dynamic>> _buildFramesForContext(Database db, String contextKey) {
  final result = db.select(
    'SELECT key, seq FROM entries WHERE parentKey = ? ORDER BY seq ASC',
    [contextKey],
  );
  final bySeq = <int, String>{};
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
  }

  final frames = <Map<String, dynamic>>[];
  for (var s = 0; s < 20; s++) {
    frames.add({
      'key': bySeq.containsKey(s) ? bySeq[s]! : '',
      'seq': s,
    });
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
      'version': DateTime.now().millisecondsSinceEpoch,
    };
  }

  final rows = db.select(
    'SELECT body_text, next_review_at, memory_strength, stability_days, recall_score, review_count, success_count, failure_count FROM entries WHERE key = ? LIMIT 1',
    [focusKey],
  );

  var body = <Map<String, dynamic>>[];
  String nextReviewAt = '';
  double memoryStrength = 0.0;
  double stabilityDays = 0.0;
  double recallScore = 0.0;
  int reviewCount = 0;
  int successCount = 0;
  int failureCount = 0;
  if (rows.isNotEmpty) {
    final raw = rows.first['body_text'] as String?;
    body = parseBody(raw);
    nextReviewAt = rows.first['next_review_at']?.toString() ?? '';
    memoryStrength = _asDouble(rows.first['memory_strength'], 0.0);
    stabilityDays = _asDouble(rows.first['stability_days'], 0.0);
    recallScore = _asDouble(rows.first['recall_score'], 0.0);
    reviewCount = _asInt(rows.first['review_count'], 0);
    successCount = _asInt(rows.first['success_count'], 0);
    failureCount = _asInt(rows.first['failure_count'], 0);
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

  return {
    'key': focusKey,
    'parentKey': parentKey,
    'body': body,
    'assets': assetsList,
    'hasChildren': hasChildren,
    'nextReviewAt': nextReviewAt,
    'memoryStrength': memoryStrength,
    'stabilityDays': stabilityDays,
    'recallScore': recallScore,
    'reviewCount': reviewCount,
    'successCount': successCount,
    'failureCount': failureCount,
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

void runLibraryBuild() {

  final dbPath = AlexandriaPaths.dbPath;
  final snapshotPath = AlexandriaPaths.snapshotCurrentJsonPath;

  final db = sqlite3.open(dbPath);

  try {

  // [BOOTSTRAP][DEV_ONLY]
  final count = db.select('SELECT COUNT(*) as c FROM entries').first['c'] as int;

  if (count == 0) {
    print('[LB][BOOTSTRAP] creando datos mínimos');

    db.execute("INSERT INTO entries (key, parentKey, seq) VALUES ('ROOT', NULL, 0)");
    db.execute("INSERT INTO entries (key, parentKey, seq) VALUES ('A', 'ROOT', 0)");
    db.execute("INSERT INTO entries (key, parentKey, seq) VALUES ('B', 'ROOT', 1)");
    db.execute("INSERT INTO entries (key, parentKey, seq) VALUES ('C', 'ROOT', 2)");
  }

  ensureLibrarySchema(db);
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

/// Árbol fijo ORM: `ROOT` → `PARCOUR_MAIN` → `L1`…`L20` → `Lk_O01`…`Lk_O20` (421 filas de contenido + hub; ver `_normalizeRealmParcourLanguage`).
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
}

/// Realm **nuevo** sin copiar otro: mismo **esqueleto** que un mundo completo (20 parcours + 400 objetos bajo el hub),
/// pero **sin datos** (sin texto en `body_text`, sin recall/review; `assets/` vacío al crear).
bool createEmptyRealm(String rawId) {
  final id = AlexandriaPaths.sanitizeRealmId(rawId);
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

