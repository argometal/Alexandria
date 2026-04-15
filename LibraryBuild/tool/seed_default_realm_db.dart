// Regenera `data/realms/default/alexandria.db` con el esqueleto ORM homogéneo.
// Uso (desde el repo): `dart run tool/seed_default_realm_db.dart`
// Requiere ejecutarse con cwd bajo el repo que contiene `data/realms/`, o `ALEXANDRIA_ROOT`.

import 'dart:io';

import 'package:library_build/alexandria_paths.dart';
import 'package:library_build/library_build.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

void main() {
  final env = Platform.environment['ALEXANDRIA_ROOT']?.trim();
  if (env != null && env.isNotEmpty) {
    // ignore: avoid_print
    print('[seed] ALEXANDRIA_ROOT=$env');
  }
  final root = AlexandriaPaths.realmDataRoot('default');
  Directory(root).createSync(recursive: true);
  final dbPath = AlexandriaPaths.dbPath;
  final f = File(dbPath);
  if (f.existsSync()) {
    f.deleteSync();
  }
  final db = sqlite3.open(dbPath);
  try {
    bootstrapEmptyRealmDatabase(db);
  } finally {
    db.dispose();
  }
  final n = sqlite3.open(dbPath);
  try {
    final c = n.select('SELECT COUNT(*) AS c FROM entries').first['c'];
    // ignore: avoid_print
    print('[seed] OK $dbPath (entries=$c, expected $kAlexandriaHomogeneousEntryCount)');
  } finally {
    n.dispose();
  }
}
