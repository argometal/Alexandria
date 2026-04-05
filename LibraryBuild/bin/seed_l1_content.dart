// Cambio 353 — Solo pobla datos en SQLite (body_text, ROOT/L1 si faltan).
// No escribe open_key.txt, no llama writeViewerCurrentJson ni runLibraryBuild.
// El contexto activo lo define GK (bridge); el viewer se regenera cuando LB
// detecta cambio de open_key (polling) o al guardar body con la misma key abierta.
//
// Verificación global LB: buscar `open_key.txt` y `writeViewerCurrentJson(` —
// main.dart escribe open_key solo en navegación explícita del usuario en LB;
// library_build reacciona a open_key en sync/runLibraryBuild (no “navegación fantasma”).
import 'dart:convert';
import 'dart:io';

import 'package:library_build/library_build.dart';
import 'package:sqlite3/sqlite3.dart';

const _dbPath = r'C:\Alexandria\data\alexandria.db';

void main() {
  if (!File(_dbPath).existsSync()) {
    stderr.writeln('[seed_l1] ERROR: no existe $_dbPath');
    exitCode = 1;
    return;
  }

  final db = sqlite3.open(_dbPath);
  try {
    ensureLibrarySchema(db);

    var rows = db.select("SELECT key FROM entries WHERE key = 'L1' LIMIT 1");
    if (rows.isEmpty) {
      final root = db.select("SELECT key FROM entries WHERE key = 'ROOT' LIMIT 1");
      if (root.isEmpty) {
        db.execute(
          "INSERT INTO entries (key, parentKey, seq, title, cognitiveRole) VALUES ('ROOT', NULL, 0, 'ROOT', 'realm')",
        );
      }
      final maxRow = db.select(
        'SELECT COALESCE(MAX(seq), -1) AS m FROM entries WHERE parentKey = ?',
        ['ROOT'],
      ).first;
      final next = (maxRow['m'] as int) + 1;
      db.execute(
        'INSERT INTO entries (key, parentKey, seq, title, cognitiveRole) VALUES (?, ?, ?, ?, ?)',
        ['L1', 'ROOT', next, 'L1', 'parcour'],
      );
      print('[seed_l1] INSERT L1 bajo ROOT seq=$next');
    }

    final l1Body = jsonEncode([
      {
        'type': 'p',
        'text':
            'Bienvenido a L1. Este es el primer párrafo de demostración.',
      },
      {
        'type': 'p',
        'text': 'Aquí hay información importante para el recorrido.',
      },
      {
        'type': 'p',
        'text':
            'Tercer bloque: contenido por KEY; GateKeeper solo mapea snapshot a loci.',
      },
    ]);
    db.execute('UPDATE entries SET body_text = ? WHERE key = ?', [l1Body, 'L1']);
    print('[seed_l1] L1 body: 3 párrafos');

    final kids = db.select(
      'SELECT key, seq FROM entries WHERE parentKey = ? ORDER BY seq ASC',
      ['L1'],
    );

    final childParagraphs = <List<String>>[
      [
        'Marco hijo A: texto de validación para el viewer.',
        'Segundo párrafo del hijo A.',
      ],
      [
        'Marco hijo B: contenido distinto para comprobar open_key.',
      ],
      [
        'Marco hijo C: párrafo único.',
        'Y un segundo bloque en C.',
      ],
      [
        'Marco hijo D: último hijo del snapshot bajo L1.',
      ],
    ];

    for (var i = 0; i < kids.length; i++) {
      final key = kids[i]['key'] as String;
      final paras = i < childParagraphs.length
          ? childParagraphs[i]
          : ['Contenido de respaldo para hijo $i'];
      final blocks = paras
          .map((t) => <String, dynamic>{'type': 'p', 'text': t})
          .toList();
      db.execute(
        'UPDATE entries SET body_text = ? WHERE key = ?',
        [jsonEncode(blocks), key],
      );
      print('[seed_l1] hijo key=$key seq=${kids[i]['seq']} párrafos=${paras.length}');
    }

    if (kids.isEmpty) {
      print('[seed_l1] AVISO: L1 no tiene hijos en DB; solo L1 poblado.');
    }

    print('[seed_l1] OK — solo DB. Siguiente: clic en frame en GK → open_key → LB regenera viewer.');
  } finally {
    db.dispose();
  }
}
