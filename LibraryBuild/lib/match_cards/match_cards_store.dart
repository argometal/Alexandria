import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_paths.dart';
import '../library_build.dart';

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

/// Stats for one pair (deck list / session “weakest” sheet).
class LbMatchPairStatView {
  const LbMatchPairStatView({
    required this.pair,
    required this.fibIndex,
    required this.failCount,
    required this.passCount,
  });

  final LbMatchPairRow pair;
  final int fibIndex;
  final int failCount;
  final int passCount;
}

/// Vista agregada del mazo: KPIs + conteo por paso Fib (índice alineado a [kParcourFibDays]).
class LbMatchDeckOverview {
  const LbMatchDeckOverview({
    required this.pairCount,
    required this.dueCount,
    required this.sumPass,
    required this.sumFail,
    required this.countByFibIndex,
  });

  final int pairCount;
  final int dueCount;
  final int sumPass;
  final int sumFail;
  final List<int> countByFibIndex;

  String matchRatePercentOrDash() {
    final t = sumPass + sumFail;
    if (t <= 0) return '—';
    return '${(100 * sumPass / t).round()}%';
  }
}

/// KPIs + histograma Fib para el mazo [deckId] (solo `route_key IS NULL`).
LbMatchDeckOverview lbLoadMatchDeckOverview(
  Database db, {
  required int deckId,
}) {
  ensureLibrarySchema(db);
  final now = DateTime.now().toUtc();
  final maxFib = kParcourFibDays.length;

  final totals = db.select('''
    SELECT COUNT(*) AS c,
           IFNULL(SUM(COALESCE(s.pass_count, 0)), 0) AS sp,
           IFNULL(SUM(COALESCE(s.fail_count, 0)), 0) AS sf
    FROM lb_match_pairs p
    LEFT JOIN lb_match_pair_fsrs_state s ON s.pair_id = p.id
    WHERE p.deck_id = ? AND p.route_key IS NULL
  ''', [deckId]);

  final pairCount = totals.isEmpty ? 0 : _asInt(totals.first['c']);
  final sumPass = totals.isEmpty ? 0 : _asInt(totals.first['sp']);
  final sumFail = totals.isEmpty ? 0 : _asInt(totals.first['sf']);

  final fibRows = db.select('''
    SELECT fi, COUNT(*) AS cnt FROM (
      SELECT COALESCE(s.fib_index, 0) AS fi
      FROM lb_match_pairs p
      LEFT JOIN lb_match_pair_fsrs_state s ON s.pair_id = p.id
      WHERE p.deck_id = ? AND p.route_key IS NULL
    )
    GROUP BY fi
  ''', [deckId]);

  final countByFib = List<int>.filled(maxFib, 0);
  for (final r in fibRows) {
    var fi = _asInt(r['fi']);
    if (fi < 0) fi = 0;
    if (fi >= maxFib) fi = maxFib - 1;
    countByFib[fi] += _asInt(r['cnt']);
  }

  final dueRows = db.select('''
    SELECT s.due_at
    FROM lb_match_pairs p
    INNER JOIN lb_match_pair_fsrs_state s ON s.pair_id = p.id
    WHERE p.deck_id = ? AND p.route_key IS NULL AND s.due_at IS NOT NULL
  ''', [deckId]);

  var dueCount = 0;
  for (final r in dueRows) {
    final raw = r['due_at']?.toString();
    if (raw == null || raw.trim().isEmpty) continue;
    final t = DateTime.tryParse(raw.trim())?.toUtc();
    if (t == null) continue;
    if (!t.isAfter(now)) dueCount++;
  }

  return LbMatchDeckOverview(
    pairCount: pairCount,
    dueCount: dueCount,
    sumPass: sumPass,
    sumFail: sumFail,
    countByFibIndex: countByFib,
  );
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

/// Scheduling **Fibonacci** (mismo eje que locus/parcour): acierto sube
/// `fib_index`; fallo baja. `due_at` = ahora + días del nuevo índice (UTC ISO).
/// Tabla `lb_match_pair_fsrs_state`: nombre histórico; columnas FSRS sin usar.
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
      ? math.min(current + 1, kParcourFibDays.length - 1)
      : math.max(current - 1, 0);
  final intervalDays = kParcourFibDays[newIdx];
  final nextDue = t.add(Duration(days: intervalDays));
  final passDelta = pass ? 1 : 0;
  final failDelta = pass ? 0 : 1;
  db.execute(
    '''
    INSERT INTO lb_match_pair_fsrs_state (
      pair_id, fib_index, due_at, last_review_at, reps, pass_count, fail_count
    ) VALUES (?, ?, ?, ?, 1, ?, ?)
    ON CONFLICT(pair_id) DO UPDATE SET
      fib_index = excluded.fib_index,
      due_at = excluded.due_at,
      last_review_at = excluded.last_review_at,
      reps = lb_match_pair_fsrs_state.reps + 1,
      pass_count = lb_match_pair_fsrs_state.pass_count + excluded.pass_count,
      fail_count = lb_match_pair_fsrs_state.fail_count + excluded.fail_count
    ''',
    [
      pairId,
      newIdx,
      nextDue.toIso8601String(),
      t.toIso8601String(),
      passDelta,
      failDelta,
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

/// Pares del mazo con estado Fib + contadores de sesión (para UI: más fallos primero).
List<LbMatchPairStatView> lbListMatchPairStats(
  Database db, {
  required int deckId,
  int limit = 48,
}) {
  ensureLibrarySchema(db);
  final rows = db.select(
    '''
    SELECT p.id, p.image_basename, p.caption_text, p.transliteration, p.gloss, p.route_key, p.deck_id, p.created_at,
           COALESCE(s.fib_index, 0) AS fib_index,
           COALESCE(s.fail_count, 0) AS fail_count,
           COALESCE(s.pass_count, 0) AS pass_count
    FROM lb_match_pairs p
    LEFT JOIN lb_match_pair_fsrs_state s ON s.pair_id = p.id
    WHERE p.deck_id = ? AND p.route_key IS NULL
    ORDER BY fail_count DESC, fib_index ASC, p.id ASC
    LIMIT ?
    ''',
    [deckId, limit],
  );
  return rows
      .map(
        (r) => LbMatchPairStatView(
          pair: LbMatchPairRow(
            id: r['id']! as int,
            imageBasename: r['image_basename']! as String,
            captionText: r['caption_text']! as String,
            transliteration: r['transliteration'] as String?,
            gloss: r['gloss'] as String?,
            routeKey: r['route_key'] as String?,
            deckId: r['deck_id'] as int?,
            createdAt: r['created_at']! as String,
          ),
          fibIndex: _asInt(r['fib_index']),
          failCount: _asInt(r['fail_count']),
          passCount: _asInt(r['pass_count']),
        ),
      )
      .toList();
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
  final failById = <int, int>{};
  if (ids.isNotEmpty) {
    final placeholders = List.filled(ids.length, '?').join(',');
    final st = db.select(
      'SELECT pair_id, fib_index, due_at, fail_count FROM lb_match_pair_fsrs_state WHERE pair_id IN ($placeholders)',
      ids,
    );
    for (final r in st) {
      final pid = r['pair_id']! as int;
      fibById[pid] = _asInt(r['fib_index']);
      dueById[pid] = _parseDueAt(r['due_at'] as String?);
      failById[pid] = _asInt(r['fail_count']);
    }
  }

  int fibOf(LbMatchPairRow p) => fibById[p.id] ?? 0;
  int failOf(LbMatchPairRow p) => failById[p.id] ?? 0;
  DateTime dueOf(LbMatchPairRow p) => dueById[p.id] ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// Prioriza intervalo corto (fib bajo), luego más fallos acumulados, luego due más antiguo.
  final sorted = List<LbMatchPairRow>.from(all)
    ..sort((a, b) {
      final c = fibOf(a).compareTo(fibOf(b));
      if (c != 0) return c;
      final f = failOf(b).compareTo(failOf(a));
      if (f != 0) return f;
      return dueOf(a).compareTo(dueOf(b));
    });
  final n = math.min(maxPairs, sorted.length);
  final picked = sorted.sublist(0, n);
  picked.shuffle(math.Random());
  return picked;
}
