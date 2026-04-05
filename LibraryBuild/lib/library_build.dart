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
const _openKeyPath = r'C:\Alexandria\data\bridge\open_key.txt';
const _contextKeyPath = r'C:\Alexandria\data\bridge\context_key.txt';
const _focusKeyPath = r'C:\Alexandria\data\bridge\focus_key.txt';

/// Fase 1 ORM-15V3: si solo existe `open_key.txt`, copia a `context_key` y `focus_key` (convivencia).
void ensureDualBridgeBootstrapFromOpenKey() {
  try {
    final open = File(_openKeyPath);
    if (!open.existsSync()) return;
    final v = open.readAsStringSync();
    final ctx = File(_contextKeyPath);
    final foc = File(_focusKeyPath);
    if (!ctx.existsSync() && !foc.existsSync()) {
      ctx.parent.createSync(recursive: true);
      ctx.writeAsStringSync(v);
      foc.writeAsStringSync(v);
      print('[LB][BRIDGE_BOOT] context_key + focus_key ← open_key (migración inicial)');
    }
  } catch (e) {
    print('[LB][BRIDGE_BOOT_ERR] $e');
  }
}

/// Precedencia: `context_key.txt` → `open_key.txt`
String readContextKeyWithFallback() {
  try {
    final c = File(_contextKeyPath);
    if (c.existsSync()) {
      final t = c.readAsStringSync().trim();
      if (t.isNotEmpty) return t;
    }
    final o = File(_openKeyPath);
    if (!o.existsSync()) return '';
    return o.readAsStringSync().trim();
  } catch (_) {
    return '';
  }
}

/// Precedencia: `focus_key.txt` → `open_key.txt` (puede ser `""` si el archivo existe vacío).
String readFocusKeyWithFallback() {
  try {
    final f = File(_focusKeyPath);
    if (f.existsSync()) return f.readAsStringSync().trim();
    final o = File(_openKeyPath);
    if (!o.existsSync()) return '';
    return o.readAsStringSync().trim();
  } catch (_) {
    return '';
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

/// Escribe viewer JSON para [focusKey]. Si está vacío (EMPTY / sin fila), payload mínimo coherente con ACUERDO v3.
void writeViewerForFocusKey(Database db, String focusKey) {
  const viewerPath = r'C:\Alexandria\data\viewer\current.json';
  if (focusKey.isEmpty) {
    final payload = {
      'key': '',
      'body': <Map<String, dynamic>>[
        {
          'type': 'p',
          'text':
              'Sin KEY de foco (slot vacío). Índice espacial: revisa data/bridge/current_seq.txt.',
        },
      ],
      'assets': <Map<String, dynamic>>[],
      'version': DateTime.now().millisecondsSinceEpoch,
    };
    final f = File(viewerPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(jsonEncode(payload));
    print('[LB][VIEWER_WRITE] $viewerPath key=(empty) [BRIDGE_DUAL]');
    return;
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

  final payload = {
    'key': focusKey,
    'body': body,
    'assets': assetsList,
    'version': DateTime.now().millisecondsSinceEpoch,
  };

  final f = File(viewerPath);
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(jsonEncode(payload));
  print('[LB][VIEWER_WRITE] $viewerPath key=$focusKey');
}

/// Compat: LocusEditor y scripts; delega en [writeViewerForFocusKey].
void writeViewerCurrentJson(Database db, String key) {
  writeViewerForFocusKey(db, key);
}

/// Polling liviano: precedencia `focus_key.txt` → `open_key.txt` (ACUERDO v3).
void syncViewerFromOpenKey() {
  const dbPath = r'C:\Alexandria\data\alexandria.db';

  if (!File(dbPath).existsSync()) return;

  ensureDualBridgeBootstrapFromOpenKey();

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

  ensureDualBridgeBootstrapFromOpenKey();

  final contextKey = readContextKeyWithFallback();
  final focusKey = readFocusKeyWithFallback();

  if (contextKey.isEmpty) {
    print('[LB][SNAPSHOT_ABORT] context_key vacío (sin fallback)');
    return;
  }

  print('[LB][SNAPSHOT_PARENT] context_key=$contextKey (dual bridge)');
  print('[LB][VIEWER_FOCUS] focus_key=${focusKey.isEmpty ? "(empty)" : focusKey}');

  final result = db.select(
    'SELECT key, seq FROM entries WHERE parentKey = ? ORDER BY seq ASC',
    [contextKey],
  );

  print('[LB][ROWS] ${result.length}');

  // [#357] DB = solo filas reales; snapshot = siempre 20 slots (0..19), huecos con key "").
  final bySeq = <int, String>{};
  for (final row in result) {
    final seq = row['seq'];
    final key = row['key'];
    if (seq == null || seq is! int) {
      print('[LB][SNAPSHOT_INVALID] seq inválido');
      return;
    }
    final s = seq;
    if (s < 0 || s > 19) {
      print('[LB][SNAPSHOT_INVALID] seq fuera de rango 0..19');
      return;
    }
    final k = key?.toString() ?? '';
    if (k.isEmpty) {
      print('[LB][SNAPSHOT_INVALID] key vacío en DB');
      return;
    }
    if (bySeq.containsKey(s)) {
      print('[LB][SNAPSHOT_INVALID] seq duplicado');
      return;
    }
    bySeq[s] = k;
  }

  final frames = <Map<String, dynamic>>[];
  for (var s = 0; s < 20; s++) {
    frames.add({
      'key': bySeq.containsKey(s) ? bySeq[s]! : '',
      'seq': s,
    });
  }

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

  try {
    writeViewerForFocusKey(db, focusKey);
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
