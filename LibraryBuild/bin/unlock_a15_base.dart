// Plan 067: poblar body_text si falta → runLibraryBuild → validar PUNTO_1/2/3.
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:library_build/library_build.dart';

const _openPath = r'C:\Alexandria\data\bridge\open_key.txt';
const _dbPath = r'C:\Alexandria\data\alexandria.db';
const _snapPath = r'C:\Alexandria\snapshot\current.json';
const _viewerPath = r'C:\Alexandria\data\viewer\current.json';

void main() {
  if (!File(_openPath).existsSync()) {
    print('[unlock] ERROR: falta $_openPath');
    exitCode = 1;
    return;
  }

  final key = File(_openPath).readAsStringSync().trim();
  if (key.isEmpty) {
    print('[unlock] ERROR: open_key vacío');
    exitCode = 1;
    return;
  }

  final db = sqlite3.open(_dbPath);
  try {
    ensureLibrarySchema(db);

    final rows = db.select(
      'SELECT body_text FROM entries WHERE key = ? LIMIT 1',
      [key],
    );
    var needFill = true;
    if (rows.isNotEmpty) {
      final raw = rows.first['body_text'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        needFill = false;
      }
    }

    if (needFill) {
      final payload = jsonEncode([
        {'type': 'p', 'text': 'Contenido base A15 (desbloqueo automático)'},
      ]);
      db.execute(
        'UPDATE entries SET body_text = ? WHERE key = ?',
        [payload, key],
      );
      print('[unlock] body_text escrito para key=$key');
    } else {
      print('[unlock] body_text ya existía; DB sin cambio de contenido');
    }
  } finally {
    db.dispose();
  }

  runLibraryBuild();
  print('[unlock] runLibraryBuild() OK');

  _reportPuntos(key);
}

void _reportPuntos(String activeKey) {
  var punto1 = false;
  var punto2 = 0;
  var punto3 = false;

  final db = sqlite3.open(_dbPath);
  try {
    final rows = db.select(
      'SELECT body_text FROM entries WHERE key = ? LIMIT 1',
      [activeKey],
    );
    if (rows.isNotEmpty) {
      final raw = rows.first['body_text'];
      punto1 = raw != null && raw.toString().trim().isNotEmpty;
    }
  } finally {
    db.dispose();
  }

  if (File(_viewerPath).existsSync()) {
    try {
      final j = jsonDecode(File(_viewerPath).readAsStringSync()) as Map<String, dynamic>;
      final body = j['body'];
      if (body is List) {
        punto2 = body.length;
      }
    } catch (_) {}
  }

  if (File(_snapPath).existsSync()) {
    try {
      final j = jsonDecode(File(_snapPath).readAsStringSync()) as Map<String, dynamic>;
      final frames = j['frames'];
      if (frames is List) {
        punto3 = frames.isNotEmpty;
      }
    } catch (_) {}
  }

  print('');
  print('[PUNTO_1]=${punto1 ? "sí" : "no"}  (body_text no vacío para key activa)');
  print('[PUNTO_2]=$punto2  (bloques en viewer/current.json → body)');
  print('[PUNTO_3]=${punto3 ? "sí" : "no"}  (snapshot con al menos un frame)');
  final ok = punto1 && punto2 >= 1 && punto3;
  print('');
  print(
    ok
        ? 'Sistema base desbloqueado: [PUNTO_1]=sí, [PUNTO_2]≥1, [PUNTO_3]=sí'
        : 'Revisar: algún criterio no cumplido (ejecutar diag_a15_pipeline.dart)',
  );
}
