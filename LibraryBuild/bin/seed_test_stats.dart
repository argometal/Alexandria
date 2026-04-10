// Dev: rellena números de prueba en entries (recall) y locus_review_state (Fib)
// para ver la franja de estadísticas en LB. Requiere filas object ya existentes.
import 'dart:io';

import 'package:library_build/library_build.dart';
import 'package:sqlite3/sqlite3.dart';

const _dbPath = r'C:\Alexandria\data\alexandria.db';

void main() {
  if (!File(_dbPath).existsSync()) {
    stderr.writeln('[seed_test_stats] No existe $_dbPath');
    exitCode = 1;
    return;
  }

  final db = sqlite3.open(_dbPath);
  try {
    ensureLibrarySchema(db);

    final objs = db.select(
      "SELECT key FROM entries WHERE cognitiveRole = 'object' ORDER BY key LIMIT 16",
    );
    if (objs.isEmpty) {
      stdout.writeln('[seed_test_stats] No hay entries con cognitiveRole=object. Ejecuta seed u otro seed antes.');
      return;
    }

    final now = DateTime.now().toUtc();
    for (var i = 0; i < objs.length; i++) {
      final k = objs[i]['key'] as String;

      // Recall: mezcla due / no due / sin fecha (new)
      final String? nextIso = switch (i % 4) {
        0 => now.subtract(const Duration(days: 2)).toIso8601String(),
        1 => now.add(const Duration(days: 4)).toIso8601String(),
        2 => null,
        _ => now.subtract(const Duration(hours: 1)).toIso8601String(),
      };

      db.execute(
        '''
        UPDATE entries SET
          review_count = ?,
          success_count = ?,
          failure_count = ?,
          memory_strength = ?,
          stability_days = ?,
          recall_score = ?,
          next_review_at = ?
        WHERE key = ?
        ''',
        [
          10 + i,
          7 + i,
          2,
          0.35 + (i % 5) * 0.1,
          1.5 + (i % 4) * 0.8,
          0.4 + (i % 6) * 0.05,
          nextIso,
          k,
        ],
      );

      // Locus Fib: primeros objetos con distintos next_due
      if (i < 8) {
        final fib = i % 6;
        final lastOk = now.subtract(Duration(days: i + 1));
        final nextFib = switch (i % 3) {
          0 => now.subtract(const Duration(days: 1)),
          1 => now.add(const Duration(days: 8)),
          _ => now.add(const Duration(days: 1)),
        };
        db.execute(
          '''
          INSERT INTO locus_review_state (entry_key, fib_index, last_ok_at, next_due_at, last_session_pct)
          VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(entry_key) DO UPDATE SET
            fib_index = excluded.fib_index,
            last_ok_at = excluded.last_ok_at,
            next_due_at = excluded.next_due_at,
            last_session_pct = excluded.last_session_pct
          ''',
          [
            k,
            fib,
            lastOk.toIso8601String(),
            nextFib.toIso8601String(),
            0.82 + (i % 3) * 0.03,
          ],
        );
      }
    }

    stdout.writeln(
      '[seed_test_stats] OK: recall + locus en ${objs.length} objects (locus en ${objs.length < 8 ? objs.length : 8}). Reinicia Realm Library.',
    );
  } finally {
    db.dispose();
  }
}
