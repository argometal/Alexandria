import 'package:sqlite3/sqlite3.dart';

/// Vistas de uso sobre los mismos loci (solo LB; no afecta snapshot ni GK).
/// [core] = núcleo de mayor engagement; [active] = uso recurrente; [seek] = cola larga / exploración.
enum UsageBand {
  core,
  active,
  seek,
}

extension UsageBandLabel on UsageBand {
  String get label => switch (this) {
        UsageBand.core => 'Core',
        UsageBand.active => 'Active',
        UsageBand.seek => 'Seek',
      };
}

/// Puntuación estable para ordenar objetos por “uso” (métricas ya en `entries`).
double usageScoreForRow(Row row) {
  final rc = _asInt(row['review_count'], 0);
  final sc = _asInt(row['success_count'], 0);
  final fc = _asInt(row['failure_count'], 0);
  final recall = _asDouble(row['recall_score'], 0);
  final mem = _asDouble(row['memory_strength'], 0);
  final stab = _asDouble(row['stability_days'], 0);
  final last = _parseIso(row['last_reviewed_at']);
  double recency = 0;
  if (last != null) {
    final days = DateTime.now().toUtc().difference(last.toUtc()).inHours / 24.0;
    recency = (30.0 - days.clamp(0, 30)) / 30.0;
  }
  return rc * 1000.0 +
      sc * 40.0 -
      fc * 8.0 +
      recall * 25.0 +
      mem * 15.0 +
      stab * 0.5 +
      recency * 80.0;
}

int _asInt(Object? v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double _asDouble(Object? v, double fallback) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

DateTime? _parseIso(Object? v) {
  final s = v?.toString().trim() ?? '';
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// Asigna cada `object` a una banda por percentiles sobre [usageScoreForRow] (tercios).
Map<String, UsageBand> computeObjectUsageBands(Database db) {
  final rows = db.select('''
    SELECT key, review_count, success_count, failure_count, recall_score,
           memory_strength, stability_days, last_reviewed_at
    FROM entries
    WHERE cognitiveRole = 'object'
    ORDER BY key ASC
  ''');
  final scored = <({String key, double score})>[];
  for (final r in rows) {
    final k = r['key'] as String;
    scored.add((key: k, score: usageScoreForRow(r)));
  }
  scored.sort((a, b) {
    final c = b.score.compareTo(a.score);
    if (c != 0) return c;
    return a.key.compareTo(b.key);
  });
  final n = scored.length;
  final out = <String, UsageBand>{};
  if (n == 0) return out;
  final nCore = (n / 3.0).ceil();
  final nActive = (n / 3.0).ceil();
  var i = 0;
  for (; i < nCore && i < n; i++) {
    out[scored[i].key] = UsageBand.core;
  }
  for (var j = 0; j < nActive && i < n; j++, i++) {
    out[scored[i].key] = UsageBand.active;
  }
  for (; i < n; i++) {
    out[scored[i].key] = UsageBand.seek;
  }
  return out;
}

/// FTS5: términos con prefijo, unidos por AND (todo debe aparecer en título o cuerpo).
String buildFts5MatchQuery(String raw) {
  final parts = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  final buf = StringBuffer();
  for (var i = 0; i < parts.length; i++) {
    if (i > 0) buf.write(' AND ');
    final p = parts[i].replaceAll('"', '""');
    buf.write('"');
    buf.write(p);
    buf.write('"');
    buf.write('*');
  }
  return buf.toString();
}

class ObjectSearchHit {
  ObjectSearchHit({
    required this.key,
    required this.parentKey,
    required this.title,
    required this.bodyText,
    required this.band,
    required this.bm25,
  });

  final String key;
  final String parentKey;
  final String title;
  final String? bodyText;
  final UsageBand band;
  final double bm25;
}

/// Crea FTS5, triggers y rellenado inicial. Solo LibraryBuild.
void ensureEntriesFts5(Database db) {
  db.execute('''
CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
  entry_key UNINDEXED,
  title,
  body_text,
  tokenize = 'unicode61'
)
''');

  db.execute('DROP TRIGGER IF EXISTS tr_entries_fts_ai');
  db.execute('DROP TRIGGER IF EXISTS tr_entries_fts_au');
  db.execute('DROP TRIGGER IF EXISTS tr_entries_fts_ad');

  db.execute('''
CREATE TRIGGER tr_entries_fts_ai AFTER INSERT ON entries BEGIN
  INSERT INTO entries_fts(entry_key, title, body_text)
  SELECT NEW.key, COALESCE(NEW.title, ''), COALESCE(NEW.body_text, '')
  WHERE NEW.cognitiveRole = 'object';
END
''');
  db.execute('''
CREATE TRIGGER tr_entries_fts_au AFTER UPDATE ON entries BEGIN
  DELETE FROM entries_fts WHERE entry_key = OLD.key;
  INSERT INTO entries_fts(entry_key, title, body_text)
  SELECT NEW.key, COALESCE(NEW.title, ''), COALESCE(NEW.body_text, '')
  WHERE NEW.cognitiveRole = 'object';
END
''');
  db.execute('''
CREATE TRIGGER tr_entries_fts_ad AFTER DELETE ON entries BEGIN
  DELETE FROM entries_fts WHERE entry_key = OLD.key;
END
''');

  final cnt = _asInt(
    db.select('SELECT COUNT(*) AS c FROM entries_fts').first['c'],
    0,
  );
  if (cnt == 0) {
    rebuildEntriesFts5(db);
  }
}

/// Reconstruye el índice FTS desde `entries` (reparación / migración).
void rebuildEntriesFts5(Database db) {
  db.execute('DELETE FROM entries_fts');
  db.execute('''
INSERT INTO entries_fts(entry_key, title, body_text)
SELECT key, COALESCE(title, ''), COALESCE(body_text, '')
FROM entries
WHERE cognitiveRole = 'object'
''');
}

/// Búsqueda solo sobre objetos; GK no participa.
List<ObjectSearchHit> searchObjects(
  Database db,
  String matchQuery, {
  required Map<String, UsageBand> bands,
}) {
  if (matchQuery.trim().isEmpty) {
    final rows = db.select('''
      SELECT key, parentKey, title, body_text
      FROM entries
      WHERE cognitiveRole = 'object'
      ORDER BY key ASC
    ''');
    final out = <ObjectSearchHit>[];
    for (final r in rows) {
      final k = r['key'] as String;
      out.add(
        ObjectSearchHit(
          key: k,
          parentKey: (r['parentKey'] as String?)?.trim() ?? '',
          title: (r['title'] as String?)?.trim() ?? '',
          bodyText: r['body_text'] as String?,
          band: bands[k] ?? UsageBand.seek,
          bm25: 0,
        ),
      );
    }
    return out;
  }

  final q = buildFts5MatchQuery(matchQuery);
  if (q.isEmpty) return [];

  final rows = db.select(
    '''
SELECT
  e.key AS key,
  e.parentKey AS parentKey,
  e.title AS title,
  e.body_text AS body_text,
  bm25(entries_fts) AS rnk
FROM entries_fts
INNER JOIN entries e ON e.key = entries_fts.entry_key AND e.cognitiveRole = 'object'
WHERE entries_fts MATCH ?
ORDER BY rnk ASC
''',
    [q],
  );

  final out = <ObjectSearchHit>[];
  for (final r in rows) {
    final k = r['key'] as String;
    out.add(
      ObjectSearchHit(
        key: k,
        parentKey: (r['parentKey'] as String?)?.trim() ?? '',
        title: (r['title'] as String?)?.trim() ?? '',
        bodyText: r['body_text'] as String?,
        band: bands[k] ?? UsageBand.seek,
        bm25: _asDouble(r['rnk'], 0),
      ),
    );
  }
  return out;
}
