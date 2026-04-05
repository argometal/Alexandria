// One-shot: DB ↔ snapshot (solo key + seq por frame; sin campo parent).
import 'dart:io';
import 'dart:convert';
import 'package:library_build/library_build.dart' as lb;
import 'package:sqlite3/sqlite3.dart';

const _dbPath = r'C:\Alexandria\data\alexandria.db';
const _openKeyPath = r'C:\Alexandria\data\bridge\open_key.txt';
const _snapshotPath = r'C:\Alexandria\snapshot\current.json';

void main() {
  final openKey = File(_openKeyPath).readAsStringSync().trim();
  // ignore: avoid_print
  print('[DIAG] open_key.txt = "$openKey"');
  if (openKey.isEmpty) {
    // ignore: avoid_print
    print('[DIAG] ABORT: open_key vacío');
    return;
  }

  final db = sqlite3.open(_dbPath);
  try {
    lb.ensureLibrarySchema(db);

    final self = db.select(
      'SELECT key, parentKey, seq, cognitiveRole, title FROM entries WHERE key = ?',
      [openKey],
    );
    // ignore: avoid_print
    print('[DIAG] fila open_key: $self');

    final children = db.select(
      'SELECT key, seq, cognitiveRole FROM entries WHERE parentKey = ? ORDER BY seq ASC',
      [openKey],
    );
    // ignore: avoid_print
    print('[DIAG] hijos en DB (count=${children.length}) parentKey=$openKey:');
    for (final r in children) {
      // ignore: avoid_print
      print('  seq=${r['seq']} key=${r['key']} role=${r['cognitiveRole']}');
    }
  } finally {
    db.dispose();
  }

  final snapFile = File(_snapshotPath);
  if (!snapFile.existsSync()) {
    // ignore: avoid_print
    print('[DIAG] snapshot missing');
    return;
  }
  final snap = jsonDecode(snapFile.readAsStringSync()) as Map<String, dynamic>;
  final frames = snap['frames'] as List<dynamic>?;
  // ignore: avoid_print
  print('[DIAG] snapshot frames count = ${frames?.length}');
  if (frames == null) return;

  var mismatches = 0;
  final bySeqDb = <int, String>{};
  final db2 = sqlite3.open(_dbPath);
  try {
    lb.ensureLibrarySchema(db2);
    final rows = db2.select(
      'SELECT key, seq FROM entries WHERE parentKey = ? ORDER BY seq ASC',
      [openKey],
    );
    for (final r in rows) {
      final s = r['seq'] as int;
      bySeqDb[s] = r['key'].toString();
    }
  } finally {
    db2.dispose();
  }

  for (final f in frames) {
    final m = f as Map<String, dynamic>;
    final seq = m['seq'] as int;
    final kRaw = (m['key'] ?? '').toString();
    final expectedDb = bySeqDb[seq] ?? '';
    if (kRaw != expectedDb) {
      mismatches++;
      // ignore: avoid_print
      print('[DIAG] MISMATCH seq=$seq snapshot="$kRaw" db="$expectedDb"');
    }
  }
  if (mismatches == 0) {
    // ignore: avoid_print
    print('[DIAG] OK: snapshot keys = hijos DB por seq (vacío = sin hijo).');
  } else {
    // ignore: avoid_print
    print('[DIAG] Total mismatches: $mismatches');
  }
}
