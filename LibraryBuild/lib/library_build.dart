import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

/// [Cambio 341] Evita re-escritura de viewer JSON si `open_key` no cambió.
String? _lastViewerKey;

/// Asegura columnas necesarias para viewer (body_text).
void ensureLibrarySchema(Database db) {
  final info = db.select('PRAGMA table_info(entries)');
  final names = info.map((r) => r['name'] as String).toList();
  if (!names.contains('body_text')) {
    db.execute('ALTER TABLE entries ADD COLUMN body_text TEXT');
  }
}

/// Parsea JSON de bloques (legacy `t`/`text`/`assetKey` o `type`/`text`/`src`).
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
      final type = t == 'img' ? 'img' : 'p';
      if (type == 'img') {
        final src = (m['src'] ?? m['assetKey'] ?? '').toString();
        out.add({'type': 'img', 'src': src});
      } else {
        out.add({'type': 'p', 'text': (m['text'] ?? '').toString()});
      }
    }
    return out;
  } catch (_) {
    return [];
  }
}

/// Escribe [C:\Alexandria\data\viewer\current.json] para la KEY (contenido desde DB).
void writeViewerCurrentJson(Database db, String key) {
  const viewerPath = r'C:\Alexandria\data\viewer\current.json';
  if (key.isEmpty) return;

  final rows = db.select(
    'SELECT body_text FROM entries WHERE key = ? LIMIT 1',
    [key],
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
        [key],
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
    'key': key,
    'body': body,
    'assets': assetsList,
    'version': DateTime.now().millisecondsSinceEpoch,
  };

  final f = File(viewerPath);
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(jsonEncode(payload));
  print('[LB][VIEWER_WRITE] $viewerPath key=$key');
}

/// Solo actualiza viewer JSON desde `open_key.txt` (polling liviano).
void syncViewerFromOpenKey() {
  const dbPath = r'C:\Alexandria\data\alexandria.db';
  const openKeyPath = r'C:\Alexandria\data\bridge\open_key.txt';

  if (!File(dbPath).existsSync()) return;

  String key;
  try {
    final f = File(openKeyPath);
    if (!f.existsSync()) return;
    key = f.readAsStringSync().trim();
  } catch (_) {
    return;
  }
  if (key.isEmpty) return;

  if (_lastViewerKey == key) return;
  _lastViewerKey = key;

  final db = sqlite3.open(dbPath);
  try {
    ensureLibrarySchema(db);
    writeViewerCurrentJson(db, key);
  } finally {
    db.dispose();
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

  var parent = File(r'C:\Alexandria\data\bridge\open_key.txt').readAsStringSync().trim();

  if (parent.isEmpty) {
    print('[LB][SNAPSHOT_ABORT] parent vacío sin KEY válido');
    return;
  }


  print('[LB][PARENT] $parent');

  final result = db.select(
    'SELECT key, seq FROM entries WHERE parentKey = ? ORDER BY seq ASC',
    [parent],
  );

  print('[LB][ROWS] ${result.length}');

  final raw = result.map((row) {
    return {
      "key": row['key'],
      "seq": row['seq'],
    };
  }).toList();

  // [A15][VALIDATION]
  final seenSeq = <int>{};

  for (var f in raw) {
    final key = f["key"];
    final seq = f["seq"];

    if (key == null || key.toString().isEmpty) {
      print('[LB][SNAPSHOT_INVALID] key vacío');
      return;
    }

    if (seq == null || seq is! int) {
      print('[LB][SNAPSHOT_INVALID] seq inválido');
      return;
    }

    if (seq < 0) {
      print('[LB][SNAPSHOT_INVALID] seq negativo');
      return;
    }

    if (seenSeq.contains(seq)) {
      print('[LB][SNAPSHOT_INVALID] seq duplicado');
      return;
    }

    seenSeq.add(seq);
  }

  raw.sort((a, b) => (a["seq"] as int).compareTo(b["seq"] as int));

  final frames = raw;

  final snapshot = {
    "version": DateTime.now().millisecondsSinceEpoch,
    "valid": true,
    "frames": frames
  };

  final file = File(snapshotPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(snapshot));

  print('[LB][FRAMES_COUNT] ${frames.length}');
  print('[LB][SNAPSHOT_WRITE] ' + snapshotPath);

  writeViewerCurrentJson(db, parent);
  _lastViewerKey = parent;

  // [A15][REFRESH_TRIGGER]
  final refreshFlag =
      File(r'C:\Alexandria\data\bridge\refresh_now.txt');
  refreshFlag.parent.createSync(recursive: true);
  refreshFlag.writeAsStringSync('1');

  } finally {
    db.dispose();
  }

}
