import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_paths.dart';
import '../library_build.dart';

/// Días hasta siguiente repaso (misma secuencia que [applyLocusReviewOutcome] / locus_review_metrics).
const List<int> kMatchCardsFibonacciDays = [
  1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233,
];

/// Carpeta por realm: `assets/lb_match_cards/` (imágenes de pares).
String lbMatchCardsAssetsDir() =>
    '${AlexandriaPaths.assetsRoot}${Platform.pathSeparator}lb_match_cards';

void ensureLbMatchCardsDirExists() {
  Directory(lbMatchCardsAssetsDir()).createSync(recursive: true);
}

class LbMatchDeckRow {
  const LbMatchDeckRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String createdAt;
}

class LbMatchPairRow {
  const LbMatchPairRow({
    required this.id,
    required this.imageBasename,
    required this.captionText,
    this.transliteration,
    this.gloss,
    this.routeKey,
    this.deckId,
    required this.createdAt,
  });

  final int id;
  final String imageBasename;
  /// Lemma / word in native script (e.g. Cyrillic).
  final String captionText;
  /// Optional romanization (e.g. koshka).
  final String? transliteration;
  /// Optional meaning in a target language (e.g. English “cat”).
  final String? gloss;
  final String? routeKey;
  final int? deckId;
  final String createdAt;

  String get imageAbsolutePath =>
      '${lbMatchCardsAssetsDir()}${Platform.pathSeparator}$imageBasename';
}

String _fileBasename(String p) {
  final n = p.replaceAll(r'\', '/');
  final i = n.lastIndexOf('/');
  return i < 0 ? n : n.substring(i + 1);
}

String _fileExtension(String p) {
  final b = _fileBasename(p);
  final i = b.lastIndexOf('.');
  return i < 0 ? '' : b.substring(i);
}

String? _trimOrNull(String? s) {
  final t = s?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}

int _asInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

/// Tras acierto sube `fib_index` (intervalo más largo); tras fallo baja. `due_at` = próximo repaso (UTC ISO).
void lbRecordMatchPairOutcome(
  Database db, {
  required int pairId,
  required bool pass,
  DateTime? now,
}) {
  ensureLibrarySchema(db);
  final t = (now ?? DateTime.now()).toUtc();
  final rows = db.select(
    'SELECT fib_index FROM lb_match_pair_fsrs_state WHERE pair_id = ?',
    [pairId],
  );
  final current = rows.isEmpty ? 0 : _asInt(rows.first['fib_index']);
  final newIdx = pass
      ? math.min(current + 1, kMatchCardsFibonacciDays.length - 1)
      : math.max(current - 1, 0);
  final intervalDays = kMatchCardsFibonacciDays[newIdx];
  final nextDue = t.add(Duration(days: intervalDays));
  db.execute(
    '''
    INSERT INTO lb_match_pair_fsrs_state (
      pair_id, fib_index, due_at, last_review_at, reps
    ) VALUES (?, ?, ?, ?, 1)
    ON CONFLICT(pair_id) DO UPDATE SET
      fib_index = excluded.fib_index,
      due_at = excluded.due_at,
      last_review_at = excluded.last_review_at,
      reps = lb_match_pair_fsrs_state.reps + 1
    ''',
    [
      pairId,
      newIdx,
      nextDue.toIso8601String(),
      t.toIso8601String(),
    ],
  );
}

DateTime _parseDueAt(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.tryParse(raw.trim())?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

/// Primer mazo (p. ej. «Default» tras migración).
int? lbFirstDeckId(Database db) {
  ensureLibrarySchema(db);
  final rows = db.select('SELECT id FROM lb_match_decks ORDER BY id ASC LIMIT 1');
  if (rows.isEmpty) return null;
  return rows.first['id'] as int;
}

List<LbMatchDeckRow> lbListDecks(Database db) {
  ensureLibrarySchema(db);
  final rows = db.select(
    'SELECT id, name, created_at FROM lb_match_decks ORDER BY name COLLATE NOCASE ASC',
  );
  return rows
      .map(
        (r) => LbMatchDeckRow(
          id: r['id']! as int,
          name: r['name']! as String,
          createdAt: r['created_at']! as String,
        ),
      )
      .toList();
}

int lbInsertDeck(Database db, String name) {
  ensureLibrarySchema(db);
  final n = name.trim();
  if (n.isEmpty) throw ArgumentError('deck name empty');
  db.execute(
    'INSERT INTO lb_match_decks (name, created_at) VALUES (?, ?)',
    [n, DateTime.now().toUtc().toIso8601String()],
  );
  return db.lastInsertRowId;
}

void lbRenameDeck(Database db, int id, String name) {
  ensureLibrarySchema(db);
  final n = name.trim();
  if (n.isEmpty) throw ArgumentError('deck name empty');
  db.execute('UPDATE lb_match_decks SET name = ? WHERE id = ?', [n, id]);
}

/// Reasigna pares a otro mazo y borra el indicado.
void lbDeleteDeck(Database db, int id) {
  ensureLibrarySchema(db);
  final rows = db.select(
    'SELECT id FROM lb_match_decks WHERE id != ? ORDER BY id ASC LIMIT 1',
    [id],
  );
  if (rows.isEmpty) return;
  final targetId = rows.first['id'] as int;
  db.execute('UPDATE lb_match_pairs SET deck_id = ? WHERE deck_id = ?', [
    targetId,
    id,
  ]);
  db.execute('DELETE FROM lb_match_decks WHERE id = ?', [id]);
}

/// Solo pares del pool LB (`route_key` vacío). Filtra por [deckId] si se indica.
List<LbMatchPairRow> lbListMatchPairs(
  Database db, {
  bool poolOnly = true,
  int? deckId,
}) {
  ensureLibrarySchema(db);
  final buf = StringBuffer(
    'SELECT id, image_basename, caption_text, transliteration, gloss, route_key, deck_id, created_at FROM lb_match_pairs WHERE 1=1',
  );
  final args = <Object?>[];
  if (poolOnly) {
    buf.write(' AND route_key IS NULL');
  }
  if (deckId != null) {
    buf.write(' AND deck_id = ?');
    args.add(deckId);
  }
  buf.write(' ORDER BY id DESC');
  final rows = args.isEmpty ? db.select(buf.toString()) : db.select(buf.toString(), args);
  return rows
      .map(
        (r) => LbMatchPairRow(
          id: r['id']! as int,
          imageBasename: r['image_basename']! as String,
          captionText: r['caption_text']! as String,
          transliteration: r['transliteration'] as String?,
          gloss: r['gloss'] as String?,
          routeKey: r['route_key'] as String?,
          deckId: r['deck_id'] as int?,
          createdAt: r['created_at']! as String,
        ),
      )
      .toList();
}

/// True si ya hay un par en el mazo con el mismo lema (misma normalización: trim + minúsculas).
bool lbDeckContainsLemmaNormalized(
  Database db, {
  required int deckId,
  required String lemma,
}) {
  ensureLibrarySchema(db);
  final n = lemma.toLowerCase().trim();
  if (n.isEmpty) return false;
  final rows = lbListMatchPairs(db, poolOnly: true, deckId: deckId);
  return rows.any((r) => r.captionText.toLowerCase().trim() == n);
}

/// Copia [sourceFile] al directorio de cartas y crea la fila (`route_key` = NULL).
void lbInsertMatchPairFromFile(
  Database db, {
  required String sourceFile,
  required String captionText,
  String? transliteration,
  String? gloss,
  required int deckId,
}) {
  ensureLibrarySchema(db);
  ensureLbMatchCardsDirExists();
  final cap = captionText.trim();
  if (cap.isEmpty) throw ArgumentError('captionText empty');
  final ext = _fileExtension(sourceFile);
  final base =
      'mc_${DateTime.now().toUtc().microsecondsSinceEpoch}${ext.isEmpty ? '.png' : ext}';
  final dest = File(
    '${lbMatchCardsAssetsDir()}${Platform.pathSeparator}$base',
  );
  File(sourceFile).copySync(dest.path);
  _lbInsertPairRow(
    db,
    base,
    cap,
    deckId: deckId,
    transliteration: _trimOrNull(transliteration),
    gloss: _trimOrNull(gloss),
  );
}

void _lbInsertPairRow(
  Database db,
  String imageBasename,
  String captionText, {
  required int deckId,
  String? transliteration,
  String? gloss,
}) {
  db.execute(
    '''
    INSERT INTO lb_match_pairs (image_basename, caption_text, transliteration, gloss, route_key, deck_id, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      imageBasename,
      captionText,
      transliteration,
      gloss,
      null,
      deckId,
      DateTime.now().toUtc().toIso8601String(),
    ],
  );
}

/// Escribe [bytes] en `assets/lb_match_cards/` (UTF-8 en textos).
void lbInsertMatchPairFromBytes(
  Database db, {
  required Uint8List bytes,
  required String extensionNoDot,
  required String captionText,
  String? transliteration,
  String? gloss,
  required int deckId,
}) {
  ensureLibrarySchema(db);
  ensureLbMatchCardsDirExists();
  final cap = captionText.trim();
  if (cap.isEmpty) throw ArgumentError('captionText empty');
  if (bytes.isEmpty) throw ArgumentError('bytes empty');
  var ext = extensionNoDot.trim().toLowerCase();
  if (ext.startsWith('.')) ext = ext.substring(1);
  if (ext.isEmpty) ext = 'png';
  const ok = {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'tif', 'tiff'};
  if (!ok.contains(ext)) ext = 'png';
  final dotExt = '.$ext';
  final base =
      'mc_${DateTime.now().toUtc().microsecondsSinceEpoch}$dotExt';
  final dest = File(
    '${lbMatchCardsAssetsDir()}${Platform.pathSeparator}$base',
  );
  dest.writeAsBytesSync(bytes);
  _lbInsertPairRow(
    db,
    base,
    cap,
    deckId: deckId,
    transliteration: _trimOrNull(transliteration),
    gloss: _trimOrNull(gloss),
  );
}

void lbDeleteMatchPair(Database db, int id) {
  ensureLibrarySchema(db);
  final rows = db.select(
    'SELECT image_basename FROM lb_match_pairs WHERE id = ?',
    [id],
  );
  if (rows.isEmpty) return;
  final base = rows.first['image_basename']! as String;
  db.execute('DELETE FROM lb_match_pair_fsrs_state WHERE pair_id = ?', [id]);
  db.execute('DELETE FROM lb_match_pairs WHERE id = ?', [id]);
  final f = File(
    '${lbMatchCardsAssetsDir()}${Platform.pathSeparator}$base',
  );
  try {
    if (f.existsSync()) f.deleteSync();
  } catch (_) {}
}

/// Elige hasta [maxPairs] pares: **prioriza `fib_index` más bajo** y, a empate, `due_at` más antiguo; luego baraja ese subconjunto para el tablero.
List<LbMatchPairRow> lbPickRandomPairsForSession(
  Database db, {
  required int deckId,
  int maxPairs = 4,
}) {
  ensureLibrarySchema(db);
  final all = lbListMatchPairs(db, poolOnly: true, deckId: deckId);
  if (all.length < 2) return [];
  if (all.length <= maxPairs) {
    final shuffled = List<LbMatchPairRow>.from(all)..shuffle(math.Random());
    return shuffled;
  }

  final ids = all.map((p) => p.id).toList();
  final fibById = <int, int>{};
  final dueById = <int, DateTime>{};
  if (ids.isNotEmpty) {
    final placeholders = List.filled(ids.length, '?').join(',');
    final st = db.select(
      'SELECT pair_id, fib_index, due_at FROM lb_match_pair_fsrs_state WHERE pair_id IN ($placeholders)',
      ids,
    );
    for (final r in st) {
      final pid = r['pair_id']! as int;
      fibById[pid] = _asInt(r['fib_index']);
      dueById[pid] = _parseDueAt(r['due_at'] as String?);
    }
  }

  int fibOf(LbMatchPairRow p) => fibById[p.id] ?? 0;
  DateTime dueOf(LbMatchPairRow p) => dueById[p.id] ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  final sorted = List<LbMatchPairRow>.from(all)
    ..sort((a, b) {
      final c = fibOf(a).compareTo(fibOf(b));
      if (c != 0) return c;
      return dueOf(a).compareTo(dueOf(b));
    });
  final n = math.min(maxPairs, sorted.length);
  final picked = sorted.sublist(0, n);
  picked.shuffle(math.Random());
  return picked;
}
