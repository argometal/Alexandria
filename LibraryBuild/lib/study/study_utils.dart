import '../library_build.dart' show parseBody;

bool _isEvaluableTextKind(Object? raw) {
  final t = raw?.toString().toLowerCase().trim() ?? '';
  return t == 'hint' || t == 'place' || t == 'ridiculous_story';
}

/// Bloques evaluables (hint / place / ridiculous_story) en orden; [applyLocusReviewOutcome] exige ≥3.
int countEvaluableBlocks(String? bodyText) {
  final blocks = parseBody(bodyText);
  var n = 0;
  for (final b in blocks) {
    if (b['type'] != 'p') continue;
    if (_isEvaluableTextKind(b['textKind'])) n++;
  }
  return n;
}

/// [recalledIndices]: índices 0..N-1 sobre la lista de solo bloques evaluables.
int countCorrectBlocks(String? bodyText, List<int> recalledIndices) {
  final n = countEvaluableBlocks(bodyText);
  if (n == 0) return 0;
  var c = 0;
  final seen = <int>{};
  for (final i in recalledIndices) {
    if (i >= 0 && i < n && seen.add(i)) c++;
  }
  return c;
}

/// Si no hay bloques evaluables, retorna 1.0 (no usar para [applyLocusReviewOutcome] sin bloques).
double computeRecallPct(String? bodyText, List<int> recalledIndices) {
  final total = countEvaluableBlocks(bodyText);
  if (total == 0) return 1.0;
  return countCorrectBlocks(bodyText, recalledIndices) / total;
}

/// **Realm / completitud (ORM-16):** el locus cuenta como activo solo si hay ≥1 bloque `p` con
/// `textKind == ridiculous_story` (misma semántica que normalización en [parseBody]).
bool isRealmActiveLocus(String? bodyText) {
  final blocks = parseBody(bodyText);
  for (final b in blocks) {
    if (b['type'] != 'p') continue;
    final tk = b['textKind']?.toString().toLowerCase().trim() ?? '';
    if (tk == 'ridiculous_story') return true;
  }
  return false;
}
