// Diagnóstico A15 (Cambio 067): bridge → DB (hijos + body_text) → snapshot → viewer JSON.
// Solo lectura; no modifica GK/LB.
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

const _viewerPath = r'C:\Alexandria\data\viewer\current.json';

void main() {
  const dbPath = r'C:\Alexandria\data\alexandria.db';
  const openPath = r'C:\Alexandria\data\bridge\open_key.txt';
  const snapPath = r'C:\Alexandria\snapshot\current.json';

  final openKey = File(openPath).existsSync()
      ? File(openPath).readAsStringSync().trim()
      : '(archivo ausente)';

  print('[DIAGNOSTICO_A15]');
  print('open_key_activo: $openKey');

  if (!File(dbPath).existsSync()) {
    print('ERROR: no existe $dbPath');
    return;
  }

  final db = sqlite3.open(dbPath);
  try {
    if (openKey.isEmpty || openKey == '(archivo ausente)') {
      print('hijos_en_db: N/A (sin key)');
      print('body_text_entrada_activa: N/A (sin key)');
    } else {
      final rows = db.select(
        'SELECT key, seq FROM entries WHERE parentKey = ? ORDER BY seq ASC',
        [openKey],
      );
      print('hijos_en_db: ${rows.length}');
      for (final r in rows) {
        print('  key=${r['key']} seq=${r['seq']}');
      }

      final bodyRows = db.select(
        'SELECT body_text FROM entries WHERE key = ? LIMIT 1',
        [openKey],
      );
      if (bodyRows.isEmpty) {
        print('body_text_entrada_activa: (sin fila para esta key en entries)');
      } else {
        final raw = bodyRows.first['body_text'];
        if (raw == null) {
          print('body_text_entrada_activa: NULL');
        } else {
          final s = raw.toString();
          if (s.trim().isEmpty) {
            print('body_text_entrada_activa: vacío (cadena vacía)');
          } else {
            final preview = s.length > 120 ? '${s.substring(0, 120)}…' : s;
            print('body_text_entrada_activa: len=${s.length}');
            print('  preview: $preview');
          }
        }
      }
    }
  } finally {
    db.dispose();
  }

  var snapshotTieneFrames = false;
  if (File(snapPath).existsSync()) {
    try {
      final j = jsonDecode(File(snapPath).readAsStringSync()) as Map<String, dynamic>;
      final frames = j['frames'];
      if (frames is List) {
        snapshotTieneFrames = frames.isNotEmpty;
        print('snapshot_tiene_frames: ${snapshotTieneFrames ? "si" : "no"} (count=${frames.length})');
      } else {
        print('snapshot_tiene_frames: no (frames no es lista)');
      }
    } catch (e) {
      print('snapshot_tiene_frames: error parse $e');
    }
  } else {
    print('snapshot_tiene_frames: no (no existe archivo)');
  }

  _printViewerBodyDiag();

  print('');
  print(
    'Paso 067: si body_text está vacío → poblar en LB antes de tocar parseBody/writeViewerCurrentJson.',
  );
  print(
    'Si viewer body sigue vacío con body_text OK → revisar parseBody/writeViewerCurrentJson con logs.',
  );
}

void _printViewerBodyDiag() {
  final f = File(_viewerPath);
  if (!f.existsSync()) {
    print('viewer_json: (no existe $_viewerPath)');
    return;
  }
  try {
    final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final key = j['key']?.toString() ?? '';
    final body = j['body'];
    var n = 0;
    if (body is List) {
      n = body.length;
    }
    print('viewer_json_key: $key');
    print('viewer_json_body_blocks: $n ${n == 0 ? "(vacío → nada que renderizar)" : ""}');
  } catch (e) {
    print('viewer_json: error parse $e');
  }
}
