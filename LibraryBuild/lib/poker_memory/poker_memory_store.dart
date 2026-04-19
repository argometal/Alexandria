import 'package:sqlite3/sqlite3.dart';

/// Índice de palo: 0 espadas, 1 corazones, 2 diamantes, 3 tréboles.
const int kPokerSuitSpades = 0;
const int kPokerSuitHearts = 1;
const int kPokerSuitDiamonds = 2;
const int kPokerSuitClubs = 3;

const int kPokerRanksPerSuit = 13;

/// Etiquetas de rango fijas: A, 2–10, J, Q, K (orden dentro de cada bloque numérico).
const List<String> kPokerRankChars = [
  'A',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
  'J',
  'Q',
  'K',
];

class PokerSuitRange {
  const PokerSuitRange({
    required this.suitIndex,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final int suitIndex;
  final int rangeStart;
  final int rangeEnd;

  int get span => rangeEnd - rangeStart + 1;
}

/// Carta lógica (palo + índice de rango 0..12).
class PokerCardRef {
  const PokerCardRef({required this.suitIndex, required this.rankIndex});

  final int suitIndex;
  final int rankIndex;
}

class PokerNumberCardMapping {
  const PokerNumberCardMapping({
    required this.number,
    required this.card,
  });

  final int number;
  final PokerCardRef card;
}

void ensurePokerMemorySchema(Database db) {
  db.execute('''
CREATE TABLE IF NOT EXISTS lb_poker_memory_ranges (
  suit_index INTEGER PRIMARY KEY CHECK (suit_index >= 0 AND suit_index <= 3),
  range_start INTEGER NOT NULL,
  range_end INTEGER NOT NULL,
  updated_at TEXT
)
''');
  final n = db.select('SELECT COUNT(*) AS c FROM lb_poker_memory_ranges');
  final c = n.isEmpty ? 0 : (n.first['c'] as num).toInt();
  if (c == 0) {
    final now = DateTime.now().toUtc().toIso8601String();
    const defaults = <List<int>>[
      [1, 13],
      [41, 53],
      [61, 73],
      [81, 93],
    ];
    for (var s = 0; s < 4; s++) {
      db.execute(
        '''
INSERT INTO lb_poker_memory_ranges (suit_index, range_start, range_end, updated_at)
VALUES (?, ?, ?, ?)
''',
        [s, defaults[s][0], defaults[s][1], now],
      );
    }
  }
}

List<PokerSuitRange> loadPokerMemoryRanges(Database db) {
  ensurePokerMemorySchema(db);
  final rows = db.select(
    'SELECT suit_index, range_start, range_end FROM lb_poker_memory_ranges ORDER BY suit_index ASC',
  );
  final out = <PokerSuitRange>[];
  for (final r in rows) {
    out.add(
      PokerSuitRange(
        suitIndex: r['suit_index'] as int,
        rangeStart: r['range_start'] as int,
        rangeEnd: r['range_end'] as int,
      ),
    );
  }
  return out;
}

/// Cada palo debe cubrir exactamente [kPokerRanksPerSuit] números; los cuatro intervalos no deben solaparse.
String? validatePokerRanges(List<PokerSuitRange> ranges) {
  if (ranges.length != 4) {
    return 'Se requieren exactamente 4 palos.';
  }
  final seen = <int>{};
  for (final r in ranges) {
    if (r.suitIndex < 0 || r.suitIndex > 3) return 'Índice de palo inválido.';
    if (r.rangeEnd < r.rangeStart) {
      return 'El fin del rango debe ser ≥ al inicio (palo ${r.suitIndex}).';
    }
    if (r.span != kPokerRanksPerSuit) {
      return 'Cada palo debe tener exactamente $kPokerRanksPerSuit números consecutivos (palo ${r.suitIndex}: ${r.rangeStart}–${r.rangeEnd}).';
    }
    for (var n = r.rangeStart; n <= r.rangeEnd; n++) {
      if (seen.contains(n)) {
        return 'El número $n está en más de un palo.';
      }
      seen.add(n);
    }
  }
  return null;
}

void savePokerMemoryRanges(Database db, List<PokerSuitRange> ranges) {
  final err = validatePokerRanges(ranges);
  if (err != null) {
    throw StateError(err);
  }
  ensurePokerMemorySchema(db);
  final now = DateTime.now().toUtc().toIso8601String();
  db.execute('BEGIN');
  try {
    for (final r in ranges) {
      db.execute(
        '''
INSERT INTO lb_poker_memory_ranges (suit_index, range_start, range_end, updated_at)
VALUES (?, ?, ?, ?)
ON CONFLICT(suit_index) DO UPDATE SET
  range_start = excluded.range_start,
  range_end = excluded.range_end,
  updated_at = excluded.updated_at
''',
        [r.suitIndex, r.rangeStart, r.rangeEnd, now],
      );
    }
    db.execute('COMMIT');
  } catch (e) {
    try {
      db.execute('ROLLBACK');
    } catch (_) {}
    rethrow;
  }
}

/// Mapa suit_index → rango (tras cargar y validar).
Map<int, PokerSuitRange> pokerRangeBySuit(List<PokerSuitRange> ranges) {
  final m = <int, PokerSuitRange>{};
  for (final r in ranges) {
    m[r.suitIndex] = r;
  }
  return m;
}

PokerCardRef? cardForNumber(List<PokerSuitRange> ranges, int number) {
  for (final r in ranges) {
    if (number >= r.rangeStart && number <= r.rangeEnd) {
      final idx = number - r.rangeStart;
      if (idx >= 0 && idx < kPokerRanksPerSuit) {
        return PokerCardRef(suitIndex: r.suitIndex, rankIndex: idx);
      }
    }
  }
  return null;
}

int? numberForCard(List<PokerSuitRange> ranges, PokerCardRef card) {
  final bySuit = pokerRangeBySuit(ranges);
  final range = bySuit[card.suitIndex];
  if (range == null) return null;
  final n = range.rangeStart + card.rankIndex;
  if (n >= range.rangeStart && n <= range.rangeEnd) return n;
  return null;
}

/// Orden estable: por número ascendente.
List<PokerNumberCardMapping> buildPokerMappingTable(List<PokerSuitRange> ranges) {
  final err = validatePokerRanges(ranges);
  if (err != null) return [];
  final list = <PokerNumberCardMapping>[];
  final nums = <int>[];
  for (final r in ranges) {
    for (var n = r.rangeStart; n <= r.rangeEnd; n++) {
      nums.add(n);
    }
  }
  nums.sort();
  for (final n in nums) {
    final c = cardForNumber(ranges, n);
    if (c != null) {
      list.add(PokerNumberCardMapping(number: n, card: c));
    }
  }
  return list;
}

String formatPokerNumberForDisplay(int n) {
  if (n >= 100) return '$n';
  return n.toString().padLeft(2, '0');
}

String pokerRankChar(int rankIndex) {
  if (rankIndex < 0 || rankIndex >= kPokerRankChars.length) return '?';
  return kPokerRankChars[rankIndex];
}

/// Símbolo de palo (Unicode).
String pokerSuitSymbol(int suitIndex) {
  switch (suitIndex) {
    case kPokerSuitSpades:
      return '\u2660';
    case kPokerSuitHearts:
      return '\u2665';
    case kPokerSuitDiamonds:
      return '\u2666';
    case kPokerSuitClubs:
      return '\u2663';
    default:
      return '?';
  }
}

String formatPokerCardShort(PokerCardRef c) {
  return '${pokerRankChar(c.rankIndex)}${pokerSuitSymbol(c.suitIndex)}';
}
