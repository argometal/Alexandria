import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

/// PAO estándar **sistema de 2 dígitos (00–99)** — módulo cerrado, independiente del card system.
///
/// `code` en SQLite: **0..99** (UI muestra `00`..`99`).
class PaoStandardRow {
  const PaoStandardRow({
    required this.code,
    required this.person,
    required this.action,
    required this.object,
    this.imageRel = '',
    this.updatedAt,
  });

  final int code;
  final String person;
  final String action;
  final String object;
  /// Ruta relativa bajo `assets/` del realm (p.ej. `pao/pao_07.png`). Vacío = sin imagen.
  final String imageRel;
  final String? updatedAt;

  static String formatCode(int code) =>
      code.clamp(0, 99).toString().padLeft(2, '0');
}

void ensurePaoStandardSchema(Database db) {
  db.execute('''
CREATE TABLE IF NOT EXISTS pao_standard (
  code INTEGER PRIMARY KEY,
  person TEXT NOT NULL DEFAULT '',
  action TEXT NOT NULL DEFAULT '',
  object TEXT NOT NULL DEFAULT '',
  updated_at TEXT
)
''');
  final info = db.select('PRAGMA table_info(pao_standard)');
  final names = info.map((r) => r['name'] as String).toList();
  if (!names.contains('image_rel')) {
    db.execute(
      "ALTER TABLE pao_standard ADD COLUMN image_rel TEXT NOT NULL DEFAULT ''",
    );
  }
}

/// Carga 0..99 fusionando con la tabla (códigos sin fila → vacíos).
List<PaoStandardRow> loadPaoStandardMerged(Database db) {
  ensurePaoStandardSchema(db);
  final rows = db.select(
    'SELECT code, person, action, object, image_rel, updated_at FROM pao_standard WHERE code >= 0 AND code <= 99 ORDER BY code ASC',
  );
  final byCode = <int, PaoStandardRow>{};
  for (final r in rows) {
    final c = r['code'] as int;
    byCode[c] = PaoStandardRow(
      code: c,
      person: (r['person'] as String?) ?? '',
      action: (r['action'] as String?) ?? '',
      object: (r['object'] as String?) ?? '',
      imageRel: (r['image_rel'] as String?) ?? '',
      updatedAt: r['updated_at'] as String?,
    );
  }
  final out = <PaoStandardRow>[];
  for (var i = 0; i < 100; i++) {
    out.add(
      byCode[i] ??
          PaoStandardRow(
            code: i,
            person: '',
            action: '',
            object: '',
            imageRel: '',
          ),
    );
  }
  return out;
}

void upsertPaoStandard(
  Database db, {
  required int code,
  required String person,
  required String action,
  required String object,
  String imageRel = '',
}) {
  ensurePaoStandardSchema(db);
  final c = code.clamp(0, 99);
  final now = DateTime.now().toUtc().toIso8601String();
  db.execute(
    '''
INSERT INTO pao_standard (code, person, action, object, image_rel, updated_at)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(code) DO UPDATE SET
  person = excluded.person,
  action = excluded.action,
  object = excluded.object,
  image_rel = excluded.image_rel,
  updated_at = excluded.updated_at
''',
    [c, person, action, object, imageRel.trim(), now],
  );
}

/// Devuelve claves faltantes tipo `"07"` si el mapa no cubre 00..99.
List<String> missingPaoJsonKeys(Map<String, dynamic> map) {
  final present = <int>{};
  for (final e in map.entries) {
    final k = e.key.trim();
    if (k.isEmpty) continue;
    final n = int.tryParse(k);
    if (n == null || n < 0 || n > 99) continue;
    present.add(n);
  }
  final miss = <String>[];
  for (var i = 0; i < 100; i++) {
    if (!present.contains(i)) {
      miss.add(i.toString().padLeft(2, '0'));
    }
  }
  return miss;
}

Map<String, dynamic> _rowToJsonMap(PaoStandardRow r) => {
      'person': r.person,
      'action': r.action,
      'object': r.object,
      'image_rel': r.imageRel,
    };

/// Valida y devuelve mensaje de error, o `null` si OK.
String? importPaoStandardFromJsonMap(Database db, Map<String, dynamic> raw) {
  final miss = missingPaoJsonKeys(raw);
  if (miss.isNotEmpty) {
    return 'Faltan ${miss.length} códigos (ej. ${miss.take(5).join(", ")}${miss.length > 5 ? "…" : ""}).';
  }
  ensurePaoStandardSchema(db);
  final previous = loadPaoStandardMerged(db);
  final now = DateTime.now().toUtc().toIso8601String();
  db.execute('BEGIN');
  try {
    for (var i = 0; i < 100; i++) {
      final key = i.toString().padLeft(2, '0');
      final v = raw[key];
      if (v is! Map) {
        db.execute('ROLLBACK');
        return 'Código $key: se esperaba un objeto {person, action, object}.';
      }
      final m = Map<String, dynamic>.from(
        v.map((k, val) => MapEntry(k.toString(), val)),
      );
      final person = (m['person'] ?? '').toString();
      final action = (m['action'] ?? '').toString();
      final object = (m['object'] ?? '').toString();
      var imageRel = (m['image_rel'] ?? m['image'] ?? '').toString().trim();
      if (imageRel.isEmpty) {
        imageRel = previous[i].imageRel;
      }
      db.execute(
        '''
INSERT INTO pao_standard (code, person, action, object, image_rel, updated_at)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(code) DO UPDATE SET
  person = excluded.person,
  action = excluded.action,
  object = excluded.object,
  image_rel = excluded.image_rel,
  updated_at = excluded.updated_at
''',
        [i, person, action, object, imageRel, now],
      );
    }
    db.execute('COMMIT');
  } catch (e) {
    try {
      db.execute('ROLLBACK');
    } catch (_) {}
    return e.toString();
  }
  return null;
}

String? importPaoStandardFromJsonString(Database db, String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, dynamic>) {
    return 'JSON raíz: se esperaba un objeto {"00": {...}, ...}.';
  }
  return importPaoStandardFromJsonMap(db, decoded);
}

String exportPaoStandardJson(Database db) {
  final rows = loadPaoStandardMerged(db);
  final map = <String, dynamic>{};
  for (final r in rows) {
    map[r.code.toString().padLeft(2, '0')] = _rowToJsonMap(r);
  }
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(map);
}

String _csvCell(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\r') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String exportPaoStandardCsv(Database db) {
  final rows = loadPaoStandardMerged(db);
  final buf = StringBuffer()
    ..writeln('code,person,action,object,image_rel');
  for (final r in rows) {
    buf.writeln(
      '${_csvCell(r.code.toString().padLeft(2, '0'))},'
      '${_csvCell(r.person)},'
      '${_csvCell(r.action)},'
      '${_csvCell(r.object)},'
      '${_csvCell(r.imageRel)}',
    );
  }
  return buf.toString();
}

/// Plantilla vacía lista para rellenar (100 claves `"00"`..`"99"`).
Map<String, dynamic> emptyPaoStandardJsonMap() {
  final m = <String, dynamic>{};
  for (var i = 0; i < 100; i++) {
    final k = i.toString().padLeft(2, '0');
    m[k] = {'person': '', 'action': '', 'object': '', 'image_rel': ''};
  }
  return m;
}
