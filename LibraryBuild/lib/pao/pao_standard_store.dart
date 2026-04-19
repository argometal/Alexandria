import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import 'pao_phonetic_store.dart';

/// Rangos de `code` en SQLite (una sola tabla `pao_standard`):
/// - **0–99** → visual `00`..`99` (par)
/// - **100–109** → visual `0`..`9` (un dígito)
/// - **110–1109** → visual `000`..`999` (tres dígitos)
const int kPaoCodePairMin = 0;
const int kPaoCodePairMax = 99;
const int kPaoCodeDigitMin = 100;
const int kPaoCodeDigitMax = 109;
const int kPaoCodeTripleMin = 110;
const int kPaoCodeTripleMax = 1109;

enum PaoCodeTier { pair, digit, triple }

PaoCodeTier paoTierForCode(int code) {
  if (code >= kPaoCodeDigitMin && code <= kPaoCodeDigitMax) {
    return PaoCodeTier.digit;
  }
  if (code >= kPaoCodeTripleMin && code <= kPaoCodeTripleMax) {
    return PaoCodeTier.triple;
  }
  return PaoCodeTier.pair;
}

bool paoCodeIsValid(int code) =>
    (code >= kPaoCodePairMin && code <= kPaoCodePairMax) ||
    (code >= kPaoCodeDigitMin && code <= kPaoCodeDigitMax) ||
    (code >= kPaoCodeTripleMin && code <= kPaoCodeTripleMax);

/// PAO estándar — módulo cerrado (persona / acción / objeto + imágenes).
///
/// `code` en SQLite: ver constantes [kPaoCodePairMin] … [kPaoCodeTripleMax].
class PaoStandardRow {
  const PaoStandardRow({
    required this.code,
    required this.person,
    required this.action,
    required this.object,
    this.imageRel = '',
    this.personImageRel = '',
    this.personImageRel2 = '',
    this.objectImageRel = '',
    this.objectImageRel2 = '',
    this.updatedAt,
  });

  final int code;
  final String person;
  final String action;
  final String object;
  /// Imagen del **código** (número). Ruta bajo `assets/` del realm.
  final String imageRel;
  /// Imágenes opcionales del **personaje** (hasta 2).
  final String personImageRel;
  final String personImageRel2;
  /// Imágenes opcionales del **objeto** (hasta 2).
  final String objectImageRel;
  final String objectImageRel2;
  final String? updatedAt;

  /// Etiqueta mostrada: `00`–`99`, un dígito `0`–`9`, o `000`–`999`.
  static String formatCode(int code) {
    if (code >= kPaoCodeDigitMin && code <= kPaoCodeDigitMax) {
      return '${code - kPaoCodeDigitMin}';
    }
    if (code >= kPaoCodeTripleMin && code <= kPaoCodeTripleMax) {
      return (code - kPaoCodeTripleMin).toString().padLeft(3, '0');
    }
    return code.clamp(kPaoCodePairMin, kPaoCodePairMax).toString().padLeft(2, '0');
  }

  /// Base de nombre de archivo bajo `pao/` (sin prefijo `pao_`): `07`, `d3`, `t042`.
  static String storageFileStem(int code) {
    if (code >= kPaoCodeDigitMin && code <= kPaoCodeDigitMax) {
      return 'd${code - kPaoCodeDigitMin}';
    }
    if (code >= kPaoCodeTripleMin && code <= kPaoCodeTripleMax) {
      return 't${(code - kPaoCodeTripleMin).toString().padLeft(3, '0')}';
    }
    return code.clamp(kPaoCodePairMin, kPaoCodePairMax).toString().padLeft(2, '0');
  }
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
  if (!names.contains('person_image_rel')) {
    db.execute(
      "ALTER TABLE pao_standard ADD COLUMN person_image_rel TEXT NOT NULL DEFAULT ''",
    );
  }
  if (!names.contains('person_image_rel2')) {
    db.execute(
      "ALTER TABLE pao_standard ADD COLUMN person_image_rel2 TEXT NOT NULL DEFAULT ''",
    );
  }
  if (!names.contains('object_image_rel')) {
    db.execute(
      "ALTER TABLE pao_standard ADD COLUMN object_image_rel TEXT NOT NULL DEFAULT ''",
    );
  }
  if (!names.contains('object_image_rel2')) {
    db.execute(
      "ALTER TABLE pao_standard ADD COLUMN object_image_rel2 TEXT NOT NULL DEFAULT ''",
    );
  }
}

PaoStandardRow _rowFromSqlite(Row r) {
  final c = r['code'] as int;
  return PaoStandardRow(
    code: c,
    person: (r['person'] as String?) ?? '',
    action: (r['action'] as String?) ?? '',
    object: (r['object'] as String?) ?? '',
    imageRel: (r['image_rel'] as String?) ?? '',
    personImageRel: (r['person_image_rel'] as String?) ?? '',
    personImageRel2: (r['person_image_rel2'] as String?) ?? '',
    objectImageRel: (r['object_image_rel'] as String?) ?? '',
    objectImageRel2: (r['object_image_rel2'] as String?) ?? '',
    updatedAt: r['updated_at'] as String?,
  );
}

PaoStandardRow _emptyRow(int code) => PaoStandardRow(
      code: code,
      person: '',
      action: '',
      object: '',
      imageRel: '',
      personImageRel: '',
      personImageRel2: '',
      objectImageRel: '',
      objectImageRel2: '',
    );

/// Carga **00–99** fusionando con la tabla (códigos sin fila → vacíos).
List<PaoStandardRow> loadPaoStandardMerged(Database db) {
  ensurePaoStandardSchema(db);
  final rows = db.select(
    'SELECT code, person, action, object, image_rel, person_image_rel, person_image_rel2, object_image_rel, object_image_rel2, updated_at FROM pao_standard WHERE code >= ? AND code <= ? ORDER BY code ASC',
    [kPaoCodePairMin, kPaoCodePairMax],
  );
  final byCode = <int, PaoStandardRow>{};
  for (final r in rows) {
    final c = r['code'] as int;
    byCode[c] = _rowFromSqlite(r);
  }
  final out = <PaoStandardRow>[];
  for (var i = kPaoCodePairMin; i <= kPaoCodePairMax; i++) {
    out.add(byCode[i] ?? _emptyRow(i));
  }
  return out;
}

/// Carga **0–9** (códigos internos 100–109).
List<PaoStandardRow> loadPaoDigitMerged(Database db) {
  ensurePaoStandardSchema(db);
  final rows = db.select(
    'SELECT code, person, action, object, image_rel, person_image_rel, person_image_rel2, object_image_rel, object_image_rel2, updated_at FROM pao_standard WHERE code >= ? AND code <= ? ORDER BY code ASC',
    [kPaoCodeDigitMin, kPaoCodeDigitMax],
  );
  final byCode = <int, PaoStandardRow>{};
  for (final r in rows) {
    final c = r['code'] as int;
    byCode[c] = _rowFromSqlite(r);
  }
  final out = <PaoStandardRow>[];
  for (var i = 0; i <= 9; i++) {
    final c = kPaoCodeDigitMin + i;
    out.add(byCode[c] ?? _emptyRow(c));
  }
  return out;
}

/// Carga **000–999** (códigos internos 110–1109).
List<PaoStandardRow> loadPaoTripleMerged(Database db) {
  ensurePaoStandardSchema(db);
  final rows = db.select(
    'SELECT code, person, action, object, image_rel, person_image_rel, person_image_rel2, object_image_rel, object_image_rel2, updated_at FROM pao_standard WHERE code >= ? AND code <= ? ORDER BY code ASC',
    [kPaoCodeTripleMin, kPaoCodeTripleMax],
  );
  final byCode = <int, PaoStandardRow>{};
  for (final r in rows) {
    final c = r['code'] as int;
    byCode[c] = _rowFromSqlite(r);
  }
  final out = <PaoStandardRow>[];
  for (var i = 0; i <= 999; i++) {
    final c = kPaoCodeTripleMin + i;
    out.add(byCode[c] ?? _emptyRow(c));
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
  String personImageRel = '',
  String personImageRel2 = '',
  String objectImageRel = '',
  String objectImageRel2 = '',
}) {
  ensurePaoStandardSchema(db);
  if (!paoCodeIsValid(code)) {
    throw ArgumentError.value(code, 'code', 'Fuera de rango PAO válido');
  }
  final now = DateTime.now().toUtc().toIso8601String();
  db.execute(
    '''
INSERT INTO pao_standard (code, person, action, object, image_rel, person_image_rel, person_image_rel2, object_image_rel, object_image_rel2, updated_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(code) DO UPDATE SET
  person = excluded.person,
  action = excluded.action,
  object = excluded.object,
  image_rel = excluded.image_rel,
  person_image_rel = excluded.person_image_rel,
  person_image_rel2 = excluded.person_image_rel2,
  object_image_rel = excluded.object_image_rel,
  object_image_rel2 = excluded.object_image_rel2,
  updated_at = excluded.updated_at
''',
    [
      code,
      person,
      action,
      object,
      imageRel.trim(),
      personImageRel.trim(),
      personImageRel2.trim(),
      objectImageRel.trim(),
      objectImageRel2.trim(),
      now,
    ],
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
      'person_image_rel': r.personImageRel,
      'person_image_rel2': r.personImageRel2,
      'object_image_rel': r.objectImageRel,
      'object_image_rel2': r.objectImageRel2,
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
      String pick(String k, String fallback) {
        final v = (m[k] ?? '').toString().trim();
        return v.isEmpty ? fallback : v;
      }

      final pImg = pick('person_image_rel', previous[i].personImageRel);
      final pImg2 = pick('person_image_rel2', previous[i].personImageRel2);
      final oImg = pick('object_image_rel', previous[i].objectImageRel);
      final oImg2 = pick('object_image_rel2', previous[i].objectImageRel2);
      db.execute(
        '''
INSERT INTO pao_standard (code, person, action, object, image_rel, person_image_rel, person_image_rel2, object_image_rel, object_image_rel2, updated_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(code) DO UPDATE SET
  person = excluded.person,
  action = excluded.action,
  object = excluded.object,
  image_rel = excluded.image_rel,
  person_image_rel = excluded.person_image_rel,
  person_image_rel2 = excluded.person_image_rel2,
  object_image_rel = excluded.object_image_rel,
  object_image_rel2 = excluded.object_image_rel2,
  updated_at = excluded.updated_at
''',
        [i, person, action, object, imageRel, pImg, pImg2, oImg, oImg2, now],
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

/// JSON solo **pares 00–99** (compatibilidad con exportaciones antiguas).
String exportPaoStandardJson(Database db) {
  final rows = loadPaoStandardMerged(db);
  final map = <String, dynamic>{};
  for (final r in rows) {
    map[r.code.toString().padLeft(2, '0')] = _rowToJsonMap(r);
  }
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(map);
}

const int kPaoLibrarySchemaVersion = 2;

/// Exporta **fonética + 0–9 + 00–99 + 000–999**.
String exportPaoLibraryJsonV2(Database db) {
  ensurePaoPhoneticSchema(db);
  final phon = loadPaoPhoneticMerged(db);
  final digits = loadPaoDigitMerged(db);
  final pairs = loadPaoStandardMerged(db);
  final triples = loadPaoTripleMerged(db);

  final digitMap = <String, dynamic>{};
  for (final r in digits) {
    digitMap[PaoStandardRow.formatCode(r.code)] = _rowToJsonMap(r);
  }
  final pairMap = <String, dynamic>{};
  for (final r in pairs) {
    pairMap[r.code.toString().padLeft(2, '0')] = _rowToJsonMap(r);
  }
  final tripleMap = <String, dynamic>{};
  for (final r in triples) {
    tripleMap[PaoStandardRow.formatCode(r.code)] = _rowToJsonMap(r);
  }

  final root = <String, dynamic>{
    'schema_version': kPaoLibrarySchemaVersion,
    'phonetic': paoPhoneticToJsonMap(phon),
    'digit': digitMap,
    'pair': pairMap,
    'triple': tripleMap,
  };
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(root);
}

String? importPaoLibraryFromJsonMap(Database db, Map<String, dynamic> raw) {
  if ((raw['schema_version'] as num?)?.toInt() != kPaoLibrarySchemaVersion) {
    return 'schema_version: se esperaba $kPaoLibrarySchemaVersion.';
  }
  ensurePaoStandardSchema(db);
  ensurePaoPhoneticSchema(db);

  final phonRaw = raw['phonetic'];
  if (phonRaw is Map) {
    importPaoPhoneticFromJsonMap(
      db,
      Map<String, dynamic>.from(
        phonRaw.map((k, v) => MapEntry(k.toString(), v)),
      ),
    );
  }

  final prevDigit = loadPaoDigitMerged(db);
  final prevPair = loadPaoStandardMerged(db);
  final prevTriple = loadPaoTripleMerged(db);

  void mergeTier(
    dynamic section,
    List<PaoStandardRow> previous,
    int count,
  ) {
    if (section is! Map<String, dynamic>) return;
    final now = DateTime.now().toUtc().toIso8601String();
    for (var i = 0; i < count; i++) {
      final row = previous[i];
      final key = PaoStandardRow.formatCode(row.code);
      final v = section[key];
      if (v is! Map) continue;
      final m = Map<String, dynamic>.from(
        v.map((k, val) => MapEntry(k.toString(), val)),
      );
      final person = (m['person'] ?? '').toString();
      final action = (m['action'] ?? '').toString();
      final object = (m['object'] ?? '').toString();
      var imageRel = (m['image_rel'] ?? m['image'] ?? '').toString().trim();
      if (imageRel.isEmpty) imageRel = row.imageRel;
      String pick(String k, String fb) {
        final x = (m[k] ?? '').toString().trim();
        return x.isEmpty ? fb : x;
      }

      final pImg = pick('person_image_rel', row.personImageRel);
      final pImg2 = pick('person_image_rel2', row.personImageRel2);
      final oImg = pick('object_image_rel', row.objectImageRel);
      final oImg2 = pick('object_image_rel2', row.objectImageRel2);
      final code = row.code;
      db.execute(
        '''
INSERT INTO pao_standard (code, person, action, object, image_rel, person_image_rel, person_image_rel2, object_image_rel, object_image_rel2, updated_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(code) DO UPDATE SET
  person = excluded.person,
  action = excluded.action,
  object = excluded.object,
  image_rel = excluded.image_rel,
  person_image_rel = excluded.person_image_rel,
  person_image_rel2 = excluded.person_image_rel2,
  object_image_rel = excluded.object_image_rel,
  object_image_rel2 = excluded.object_image_rel2,
  updated_at = excluded.updated_at
''',
        [
          code,
          person,
          action,
          object,
          imageRel,
          pImg,
          pImg2,
          oImg,
          oImg2,
          now,
        ],
      );
    }
  }

  mergeTier(raw['digit'], prevDigit, 10);
  mergeTier(raw['pair'], prevPair, 100);
  mergeTier(raw['triple'], prevTriple, 1000);

  return null;
}

String? importPaoLibraryFromJsonString(Database db, String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, dynamic>) {
    return 'JSON raíz: se esperaba un objeto con schema_version.';
  }
  return importPaoLibraryFromJsonMap(db, decoded);
}

/// Si el JSON es v2 (`schema_version`) importa la biblioteca completa; si no, solo 00–99.
String? importPaoJsonAuto(Database db, String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic> &&
        (decoded['schema_version'] as num?)?.toInt() == kPaoLibrarySchemaVersion) {
      return importPaoLibraryFromJsonMap(db, decoded);
    }
  } catch (_) {}
  return importPaoStandardFromJsonString(db, json);
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
    ..writeln(
      'tier,code,person,action,object,image_rel,person_image_rel,person_image_rel2,object_image_rel,object_image_rel2',
    );
  for (final r in rows) {
    buf.writeln(
      'pair,'
      '${_csvCell(PaoStandardRow.formatCode(r.code))},'
      '${_csvCell(r.person)},'
      '${_csvCell(r.action)},'
      '${_csvCell(r.object)},'
      '${_csvCell(r.imageRel)},'
      '${_csvCell(r.personImageRel)},'
      '${_csvCell(r.personImageRel2)},'
      '${_csvCell(r.objectImageRel)},'
      '${_csvCell(r.objectImageRel2)}',
    );
  }
  return buf.toString();
}

/// Plantilla vacía lista para rellenar (100 claves `"00"`..`"99"`).
Map<String, dynamic> emptyPaoStandardJsonMap() {
  final m = <String, dynamic>{};
  for (var i = 0; i < 100; i++) {
    final k = i.toString().padLeft(2, '0');
    m[k] = {
      'person': '',
      'action': '',
      'object': '',
      'image_rel': '',
      'person_image_rel': '',
      'person_image_rel2': '',
      'object_image_rel': '',
      'object_image_rel2': '',
    };
  }
  return m;
}

/// Plantilla JSON v2 (fonética + tres niveles PAO).
Map<String, dynamic> emptyPaoLibraryJsonMapV2() {
  final phon = <String, dynamic>{};
  for (var d = 0; d <= 9; d++) {
    phon['$d'] = {'consonants': '', 'vowel_note': ''};
  }
  final digit = <String, dynamic>{};
  for (var i = 0; i <= 9; i++) {
    digit['$i'] = {
      'person': '',
      'action': '',
      'object': '',
      'image_rel': '',
      'person_image_rel': '',
      'person_image_rel2': '',
      'object_image_rel': '',
      'object_image_rel2': '',
    };
  }
  final pair = emptyPaoStandardJsonMap();
  final triple = <String, dynamic>{};
  for (var i = 0; i <= 999; i++) {
    final k = i.toString().padLeft(3, '0');
    triple[k] = {
      'person': '',
      'action': '',
      'object': '',
      'image_rel': '',
      'person_image_rel': '',
      'person_image_rel2': '',
      'object_image_rel': '',
      'object_image_rel2': '',
    };
  }
  return {
    'schema_version': kPaoLibrarySchemaVersion,
    'phonetic': phon,
    'digit': digit,
    'pair': pair,
    'triple': triple,
  };
}
