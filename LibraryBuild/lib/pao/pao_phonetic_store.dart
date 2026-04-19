import 'package:sqlite3/sqlite3.dart';

/// Tablero editable: **dígito → consonantes** (codificación); vocales como referencia libre.
///
/// Independiente de las filas PAO (persona/acción/objeto).
class PaoPhoneticRow {
  const PaoPhoneticRow({
    required this.digit,
    this.consonants = '',
    this.vowelNote = '',
    this.updatedAt,
  });

  final int digit;
  final String consonants;
  /// Notas sobre vocales / rellenos (solo referencia, no codifican dígitos).
  final String vowelNote;
  final String? updatedAt;
}

void ensurePaoPhoneticSchema(Database db) {
  db.execute('''
CREATE TABLE IF NOT EXISTS pao_phonetic (
  digit INTEGER PRIMARY KEY CHECK (digit >= 0 AND digit <= 9),
  consonants TEXT NOT NULL DEFAULT '',
  vowel_note TEXT NOT NULL DEFAULT '',
  updated_at TEXT
)
''');
}

List<PaoPhoneticRow> loadPaoPhoneticMerged(Database db) {
  ensurePaoPhoneticSchema(db);
  final rows = db.select(
    'SELECT digit, consonants, vowel_note, updated_at FROM pao_phonetic WHERE digit >= 0 AND digit <= 9 ORDER BY digit ASC',
  );
  final by = <int, PaoPhoneticRow>{};
  for (final r in rows) {
    final d = r['digit'] as int;
    by[d] = PaoPhoneticRow(
      digit: d,
      consonants: (r['consonants'] as String?) ?? '',
      vowelNote: (r['vowel_note'] as String?) ?? '',
      updatedAt: r['updated_at'] as String?,
    );
  }
  final out = <PaoPhoneticRow>[];
  for (var d = 0; d <= 9; d++) {
    out.add(
      by[d] ??
          PaoPhoneticRow(
            digit: d,
            consonants: '',
            vowelNote: '',
          ),
    );
  }
  return out;
}

void upsertPaoPhonetic(
  Database db, {
  required int digit,
  required String consonants,
  required String vowelNote,
}) {
  ensurePaoPhoneticSchema(db);
  final d = digit.clamp(0, 9);
  final now = DateTime.now().toUtc().toIso8601String();
  db.execute(
    '''
INSERT INTO pao_phonetic (digit, consonants, vowel_note, updated_at)
VALUES (?, ?, ?, ?)
ON CONFLICT(digit) DO UPDATE SET
  consonants = excluded.consonants,
  vowel_note = excluded.vowel_note,
  updated_at = excluded.updated_at
''',
    [d, consonants.trim(), vowelNote.trim(), now],
  );
}

Map<String, dynamic> paoPhoneticToJsonMap(List<PaoPhoneticRow> rows) {
  final m = <String, dynamic>{};
  for (final r in rows) {
    m['${r.digit}'] = {
      'consonants': r.consonants,
      'vowel_note': r.vowelNote,
    };
  }
  return m;
}

void importPaoPhoneticFromJsonMap(Database db, Map<String, dynamic> raw) {
  ensurePaoPhoneticSchema(db);
  final previous = loadPaoPhoneticMerged(db);
  for (var d = 0; d <= 9; d++) {
    final key = '$d';
    final v = raw[key];
    if (v is! Map) continue;
    final m = Map<String, dynamic>.from(
      v.map((k, val) => MapEntry(k.toString(), val)),
    );
    var cons = (m['consonants'] ?? '').toString().trim();
    var vow = (m['vowel_note'] ?? m['vowels'] ?? '').toString().trim();
    if (cons.isEmpty) cons = previous[d].consonants;
    if (vow.isEmpty) vow = previous[d].vowelNote;
    upsertPaoPhonetic(db, digit: d, consonants: cons, vowelNote: vow);
  }
}
