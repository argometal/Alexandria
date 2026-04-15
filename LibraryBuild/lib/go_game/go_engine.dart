/// Piedra: [empty], [black], [white].
enum Stone {
  empty(0),
  black(1),
  white(2);

  const Stone(this.code);
  final int code;

  static Stone fromCode(int c) {
    return switch (c) {
      0 => Stone.empty,
      1 => Stone.black,
      2 => Stone.white,
      _ => Stone.empty,
    };
  }
}

/// Estado copiable para [compute] / isolates (superko: historial de tableros).
class GoBoardSnapshot {
  const GoBoardSnapshot({
    required this.size,
    required this.komi,
    required this.cells,
    required this.toPlay,
    required this.consecutivePasses,
    required this.seenHashes,
  });

  final int size;
  final double komi;
  final List<int> cells;
  final int toPlay;
  final int consecutivePasses;
  final List<String> seenHashes;
}

/// Go 9×9: capturas, suicidio ilegal, superko posicional (tablero ya visto).
/// Pasar dos veces seguidas → fin. Komi para blancas [komi] (p. ej. 5.5).
class GoBoard {
  GoBoard({
    this.size = 9,
    this.komi = 5.5,
  })  : cells = List<int>.filled(size * size, 0),
        toPlay = Stone.black.code,
        consecutivePasses = 0,
        _seen = <String>{} {
    _seen.add(_boardHash());
  }

  GoBoard._copy(GoBoard o)
      : size = o.size,
        komi = o.komi,
        cells = List<int>.from(o.cells),
        toPlay = o.toPlay,
        consecutivePasses = o.consecutivePasses,
        _seen = {...o._seen};

  /// Restaura desde [GoBoardSnapshot] (p. ej. otro isolate).
  GoBoard._restore({
    required this.size,
    required this.komi,
    required this.cells,
    required this.toPlay,
    required this.consecutivePasses,
    required Set<String> seen,
  }) : _seen = {...seen};

  factory GoBoard.fromSnapshot(GoBoardSnapshot s) {
    assert(s.cells.length == s.size * s.size);
    return GoBoard._restore(
      size: s.size,
      komi: s.komi,
      cells: List<int>.from(s.cells),
      toPlay: s.toPlay,
      consecutivePasses: s.consecutivePasses,
      seen: s.seenHashes.toSet(),
    );
  }

  final int size;
  final double komi;
  final List<int> cells;
  int toPlay;
  int consecutivePasses;
  final Set<String> _seen;

  int get len => size * size;

  GoBoard copy() => GoBoard._copy(this);

  GoBoardSnapshot toSnapshot() => GoBoardSnapshot(
        size: size,
        komi: komi,
        cells: List<int>.from(cells),
        toPlay: toPlay,
        consecutivePasses: consecutivePasses,
        seenHashes: _seen.toList(),
      );

  String _boardHash() => cells.join(',');

  bool get isTerminal => consecutivePasses >= 2;

  int idx(int r, int c) => r * size + c;

  List<int> neighbors(int i) {
    final r = i ~/ size;
    final c = i % size;
    final out = <int>[];
    if (r > 0) out.add(i - size);
    if (r < size - 1) out.add(i + size);
    if (c > 0) out.add(i - 1);
    if (c < size - 1) out.add(i + 1);
    return out;
  }

  /// Grupo conectado mismo color desde [start].
  List<int> _group(int start) {
    final color = cells[start];
    if (color == 0) return [];
    final q = <int>[start];
    final vis = {start};
    var qi = 0;
    while (qi < q.length) {
      final i = q[qi++];
      for (final n in neighbors(i)) {
        if (cells[n] == color && !vis.contains(n)) {
          vis.add(n);
          q.add(n);
        }
      }
    }
    return q;
  }

  int _liberties(List<int> group) {
    final lib = <int>{};
    for (final i in group) {
      for (final n in neighbors(i)) {
        if (cells[n] == 0) lib.add(n);
      }
    }
    return lib.length;
  }

  /// Quita grupos rivales sin libertades; devuelve piedras capturadas.
  int _captureOpponent(int playedIdx) {
    final me = cells[playedIdx];
    final opp = (me == 1) ? 2 : 1;
    var captured = 0;
    final toClear = <int>{};
    for (final n in neighbors(playedIdx)) {
      if (cells[n] != opp) continue;
      final g = _group(n);
      if (_liberties(g) == 0) {
        toClear.addAll(g);
      }
    }
    for (final i in toClear) {
      cells[i] = 0;
      captured++;
    }
    return captured;
  }

  bool _ownGroupDead(int playedIdx) {
    final g = _group(playedIdx);
    return _liberties(g) == 0;
  }

  /// Intenta colocar en [i]; devuelve false si ilegal.
  bool _tryPlace(int i) {
    if (i < 0 || i >= len || cells[i] != 0) return false;
    final snapshot = List<int>.from(cells);
    cells[i] = toPlay;
    _captureOpponent(i);
    if (_ownGroupDead(i)) {
      cells.setAll(0, snapshot);
      return false;
    }
    final h = _boardHash();
    if (_seen.contains(h)) {
      cells.setAll(0, snapshot);
      return false;
    }
    return true;
  }

  /// true = jugada aplicada.
  bool play(int move) {
    if (isTerminal) return false;
    if (move == -1) {
      consecutivePasses++;
      toPlay = (toPlay == 1) ? 2 : 1;
      return true;
    }
    consecutivePasses = 0;
    if (!_tryPlace(move)) return false;
    _seen.add(_boardHash());
    toPlay = (toPlay == 1) ? 2 : 1;
    return true;
  }

  List<int> legalMoves() {
    if (isTerminal) return [];
    final out = <int>[];
    for (var i = 0; i < len; i++) {
      if (cells[i] != 0) continue;
      final t = copy();
      if (t._tryPlace(i)) out.add(i);
    }
    out.add(-1);
    return out;
  }

  /// Puntuación área simple al terminar: piedras + vacíos alcanzables solo por un color (BFS por vacíos).
  (double black, double white) areaScore() {
    var b = 0.0;
    var w = 0.0;
    for (var i = 0; i < len; i++) {
      if (cells[i] == 1) b += 1;
      if (cells[i] == 2) w += 1;
    }
    final seen = List<bool>.filled(len, false);
    for (var i = 0; i < len; i++) {
      if (cells[i] != 0 || seen[i]) continue;
      final q = <int>[i];
      seen[i] = true;
      var qi = 0;
      final region = <int>[i];
      final touches = <int>{};
      while (qi < q.length) {
        final u = q[qi++];
        for (final n in neighbors(u)) {
          final v = cells[n];
          if (v == 0) {
            if (!seen[n]) {
              seen[n] = true;
              q.add(n);
              region.add(n);
            }
          } else {
            touches.add(v);
          }
        }
      }
      if (touches.length == 1) {
        if (touches.contains(1)) b += region.length.toDouble();
        if (touches.contains(2)) w += region.length.toDouble();
      }
    }
    w += komi;
    return (b, w);
  }

  /// +1 si ganan negras, -1 si ganan blancas, 0 empate.
  double outcomeBlack() {
    final (b, w) = areaScore();
    if (b > w) return 1;
    if (w > b) return -1;
    return 0;
  }
}
