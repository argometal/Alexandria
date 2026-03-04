import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

void runLibraryBuild() {

  final dbPath = r'C:\Alexandria\data\alexandria.db';
  final snapshotPath = r'C:\Alexandria\snapshot\current.json';

  final db = sqlite3.open(dbPath);

  // [BOOTSTRAP][DEV_ONLY]
  final count = db.select('SELECT COUNT(*) as c FROM entries').first['c'] as int;

  if (count == 0) {
    print('[LB][BOOTSTRAP] creando datos mínimos');

  db.execute("""
    INSERT INTO entries (key, parentKey, seq)
    VALUES ('K1', 'P1', 0)
  """);

  db.execute("""
    INSERT INTO entries (key, parentKey, seq)
    VALUES ('K2', 'K1', 0)
  """);

  }

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


  db.dispose();

  if (frames.isEmpty && raw.isNotEmpty) {
    print('[LB][SNAPSHOT_INVALID] validación fallida');
    return;
  }

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


  // [A15][REFRESH_TRIGGER]
  File(r'C:\Alexandria\data\bridge\refresh_now.txt').writeAsStringSync('1');


}