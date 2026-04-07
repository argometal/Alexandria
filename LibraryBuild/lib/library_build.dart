import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

/// [Cambio 341] Evita re-escritura de viewer si el foco (dual bridge) no cambió.
String? _lastViewerKey;

/// [Cambio 353] Último parent procesado en `runLibraryBuild` (detectar cambio de contexto).
String _lastBridgeParentKey = '';

const _refreshNowPath = r'C:\Alexandria\data\bridge\refresh_now.txt';
const _bridgeCurrentSeqPath = r'C:\Alexandria\data\bridge\current_seq.txt';
const _bridgeLastPositionPath = r'C:\Alexandria\data\bridge\last_position.json';
const _contextKeyPath = r'C:\Alexandria\data\bridge\context_key.txt';
const _focusKeyPath = r'C:\Alexandria\data\bridge\focus_key.txt';
const _snapshotRoot = r'C:\Alexandria\data\snapshot';
const _viewerRoot = r'C:\Alexandria\data\viewer';

/// Fase 3 ORM-15V3: asegura `context_key.txt` y `focus_key.txt` sin leer `open_key.txt`.
/// Si falta context → `ROOT`; si falta focus → archivo vacío.
void ensureDualBridgeDefaults() {
  try {
    final ctx = File(_contextKeyPath);
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
    final foc = File(_focusKeyPath);
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
    final c = File(_contextKeyPath);
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
    final f = File(_focusKeyPath);
    if (f.existsSync()) return f.readAsStringSync().trim();
    return '';
  } catch (_) {
    return '';
  }
}

/// LB escribe contexto al navegar atrás en la UI (Fase 3 — no usa open_key).
void writeBridgeContextKey(String key) {
  try {
    final f = File(_contextKeyPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(key);
  } catch (e) {
    print('[LB][CONTEXT_WRITE_ERR] $e');
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
    final refreshFlag = File(_refreshNowPath);
    refreshFlag.parent.createSync(recursive: true);
    refreshFlag.writeAsStringSync('1');
    print('[LB][REFRESH_WRITE] $_refreshNowPath');
  } catch (e) {
    print('[LB][REFRESH_ERR] $_refreshNowPath $e');
  }
}

/// Valores permitidos para [cognitiveRole] (solo metadata LB / UX; sin lógica en snapshot ni GK).
const List<String> kCognitiveRoles = [
  'realm',
  'parcour',
  'room',
  'object',
];

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
  // Filas sin rol (legacy o INSERT sin columna): default `'object'`; no afecta snapshot/viewer.
  db.execute(
    "UPDATE entries SET cognitiveRole = 'object' WHERE cognitiveRole IS NULL OR TRIM(COALESCE(cognitiveRole, '')) = ''",
  );
  // ROOT lógico = realm (herencia hijo → parcour). Legacy `object` en ROOT bloqueaba crear hijos.
  db.execute(
    "UPDATE entries SET cognitiveRole = 'realm' WHERE key = 'ROOT' AND cognitiveRole = 'object'",
  );
}

/// Normaliza valor guardado a uno de [kCognitiveRoles]; por defecto `'object'`.
String normalizeCognitiveRole(Object? raw) {
  final s = raw?.toString().trim().toLowerCase() ?? '';
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
      return 'room';
    case 'room':
    case 'object':
      return 'object';
    default:
      return 'parcour';
  }
}

/// Parsea JSON de bloques (legacy `t`/`text`/`assetKey` o `type`/`text`/`src`).
/// Conserva `img` y `link` (A15 / viewer GK); el resto → `p`.
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
      final t = (m['t'] ?? m['type'] ?? 'p').toString();

      if (t == 'img') {
        final src = (m['src'] ?? m['assetKey'] ?? '').toString();
        out.add({'type': 'img', 'src': src});
        continue;
      }

      if (t == 'link') {
        final linkKey = (m['key'] ?? '').toString();
        final linkText = (m['text'] ?? '').toString();
        if (linkKey.isNotEmpty && linkText.isNotEmpty) {
          out.add({'type': 'link', 'key': linkKey, 'text': linkText});
        } else {
          out.add({
            'type': 'p',
            'text': linkText.isNotEmpty ? linkText : linkKey,
          });
        }
        continue;
      }

      out.add({'type': 'p', 'text': (m['text'] ?? '').toString()});
    }
    return out;
  } catch (_) {
    return [];
  }
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
    'SELECT body_text FROM entries WHERE key = ? LIMIT 1',
    [focusKey],
  );

  var body = <Map<String, dynamic>>[];
  if (rows.isNotEmpty) {
    final raw = rows.first['body_text'] as String?;
    body = parseBody(raw);
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
    'version': DateTime.now().millisecondsSinceEpoch,
  };
}

/// Escribe viewer JSON para [focusKey]. Si está vacío (EMPTY / sin fila), payload mínimo coherente con ACUERDO v3.
void writeViewerForFocusKey(Database db, String focusKey) {
  const viewerPath = r'C:\Alexandria\data\viewer\current.json';
  final payload = _buildViewerPayload(db, focusKey);

  final f = File(viewerPath);
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(jsonEncode(payload));
  print('[LB][VIEWER_WRITE] $viewerPath key=$focusKey');
}

void buildViewerForKey(String key) {
  const dbPath = r'C:\Alexandria\data\alexandria.db';
  if (!File(dbPath).existsSync()) return;
  final db = sqlite3.open(dbPath);
  try {
    ensureLibrarySchema(db);
    final payload = _buildViewerPayload(db, key);
    final outPath = '$_viewerRoot\\$key.json';
    final f = File(outPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(jsonEncode(payload));
  } finally {
    db.dispose();
  }
}

void buildSnapshotForContext(String contextKey) {
  const dbPath = r'C:\Alexandria\data\alexandria.db';
  if (!File(dbPath).existsSync()) return;
  final db = sqlite3.open(dbPath);
  try {
    ensureLibrarySchema(db);
    final frames = _buildFramesForContext(db, contextKey);
    final outPath = '$_snapshotRoot\\$contextKey.json';
    final f = File(outPath);
    f.parent.createSync(recursive: true);
    final snapshot = {
      'version': DateTime.now().millisecondsSinceEpoch,
      'valid': true,
      'frames': frames,
    };
    f.writeAsStringSync(jsonEncode(snapshot));
  } finally {
    db.dispose();
  }
}

void buildAll() {
  const dbPath = r'C:\Alexandria\data\alexandria.db';
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
        final snapshotFile = File('$_snapshotRoot\\$key.json');
        snapshotFile.parent.createSync(recursive: true);
        snapshotFile.writeAsStringSync(jsonEncode({
          'version': DateTime.now().millisecondsSinceEpoch,
          'valid': true,
          'frames': frames,
        }));
      } catch (_) {}

      final viewerFile = File('$_viewerRoot\\$key.json');
      viewerFile.parent.createSync(recursive: true);
      viewerFile.writeAsStringSync(jsonEncode(_buildViewerPayload(db, key)));
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
  const dbPath = r'C:\Alexandria\data\alexandria.db';

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
    final f = File(_bridgeCurrentSeqPath);
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
    Directory(File(_bridgeLastPositionPath).parent.path).createSync(recursive: true);
    final byKey = <String, int>{};
    final f = File(_bridgeLastPositionPath);
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

  final dbPath = r'C:\Alexandria\data\alexandria.db';
  final snapshotPath = r'C:\Alexandria\snapshot\current.json';

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

  ensureDualBridgeDefaults();

  final contextKey = readContextKeyWithFallback();
  final focusKey = readFocusKeyWithFallback();

  print('[LB][SNAPSHOT_PARENT] context_key=$contextKey (solo context_key.txt)');
  print('[LB][VIEWER_FOCUS] focus_key=${focusKey.isEmpty ? "(empty)" : focusKey}');

  final frames = _buildFramesForContext(db, contextKey);
  print('[LB][ROWS] ${frames.where((e) => (e['key'] as String).isNotEmpty).length}');

  final snapFile = File(snapshotPath);
  snapFile.parent.createSync(recursive: true);

  final snapshot = {
    'version': DateTime.now().millisecondsSinceEpoch,
    'valid': true,
    'frames': frames,
  };
  snapFile.writeAsStringSync(jsonEncode(snapshot));
  print('[LB][FRAMES_COUNT] ${frames.length} (fijo #357)');
  print('[LB][SNAPSHOT_FRAMES] count=${frames.length}');
  print('[LB][SNAPSHOT_WRITE] $snapshotPath');
  final keyedSnapshotPath = '$_snapshotRoot\\$contextKey.json';
  final keyedSnapshotFile = File(keyedSnapshotPath);
  keyedSnapshotFile.parent.createSync(recursive: true);
  keyedSnapshotFile.writeAsStringSync(jsonEncode(snapshot));
  print('[LB][SNAPSHOT_WRITE] $keyedSnapshotPath');

  try {
    writeViewerForFocusKey(db, focusKey);
    if (focusKey.isNotEmpty) {
      final keyedViewerPath = '$_viewerRoot\\$focusKey.json';
      final keyedViewer = File(keyedViewerPath);
      keyedViewer.parent.createSync(recursive: true);
      keyedViewer.writeAsStringSync(jsonEncode(_buildViewerPayload(db, focusKey)));
      print('[LB][VIEWER_WRITE] $keyedViewerPath');
    }
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
