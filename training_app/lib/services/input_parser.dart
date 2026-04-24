import '../models/stimulus.dart';

class ParsedSlot {
  const ParsedSlot({
    required this.position,
    required this.expected,
    this.user,
    this.errorType,
  });

  final int position;
  final String expected;
  final String? user;
  final String? errorType; // null correct
}

class InputParser {
  static List<String> _splitCards(String input) {
    return input
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<String> _splitDigits(String input) {
    return input
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _normCardToken(String t) {
    return t.toUpperCase().replaceAll(' ', '');
  }

  static String _normDigitToken(String t) {
    final s = t.trim();
    if (s.isEmpty) return '';
    final n = int.tryParse(s);
    if (n == null) return s;
    if (n < 0 || n > 99) return s;
    return n.toString().padLeft(2, '0');
  }

  static List<ParsedSlot> parseCardsInput(
    String input,
    List<Stimulus> expectedSequence,
  ) {
    final toks = _splitCards(input).map(_normCardToken).toList();
    return _align(toks, expectedSequence, isDigits: false);
  }

  static List<ParsedSlot> parseDigitsInput(
    String input,
    List<Stimulus> expectedSequence,
  ) {
    final toks = _splitDigits(input).map(_normDigitToken).toList();
    return _align(toks, expectedSequence, isDigits: true);
  }

  static List<ParsedSlot> _align(
    List<String> toks,
    List<Stimulus> expectedSequence, {
    required bool isDigits,
  }) {
    final n = expectedSequence.length;
    final expectIds = [for (final s in expectedSequence) s.id];

    String normExpectedId(String e) {
      if (isDigits) return _normDigitToken(e);
      return _normCardToken(e);
    }

    final out = <ParsedSlot>[];
    for (var i = 0; i < n; i++) {
      final exp = normExpectedId(expectIds[i]);
      if (i >= toks.length) {
        out.add(
          ParsedSlot(
            position: i,
            expected: expectIds[i],
            user: null,
            errorType: 'omit',
          ),
        );
        continue;
      }
      final u = toks[i];
      if (u.isEmpty) {
        out.add(
          ParsedSlot(
            position: i,
            expected: expectIds[i],
            user: u,
            errorType: 'omit',
          ),
        );
        continue;
      }
      if (u == exp) {
        out.add(
          ParsedSlot(
            position: i,
            expected: expectIds[i],
            user: toks[i],
            errorType: null,
          ),
        );
        continue;
      }
      // existe en otra posición
      var foundJ = -1;
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        if (u == normExpectedId(expectIds[j])) {
          foundJ = j;
          break;
        }
      }
      if (foundJ >= 0) {
        out.add(
          ParsedSlot(
            position: i,
            expected: expectIds[i],
            user: toks[i],
            errorType: 'order',
          ),
        );
      } else {
        out.add(
          ParsedSlot(
            position: i,
            expected: expectIds[i],
            user: toks[i],
            errorType: 'substitution',
          ),
        );
      }
    }
    return out;
  }
}
