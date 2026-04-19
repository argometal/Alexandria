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

  /// Posición inicial de un **problema** (tsumego): superko empieza solo con este tablero.
  factory GoBoard.problemStart({
    required List<int> initialCells,
    required int toPlay,
    double komi = 5.5,
  }) {
    assert(initialCells.length == 81);
    final h = initialCells.join(',');
    return GoBoard._restore(
      size: 9,
      komi: komi,
      cells: List<int>.from(initialCells),
      toPlay: toPlay,
      consecutivePasses: 0,
      seen: {h},
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

  /// Quita grupos sin ninguna libertad (capturas que siguieron en el tablero al
  /// terminar con dos pasos). Repite hasta fijar — necesario para que el recuento
  /// por área no deje piedras muertas sumando y bloqueando territorio rival.
  void _removeGroupsWithNoLiberties() {
    while (true) {
      final toClear = <int>{};
      final visited = <int>{};
      for (var i = 0; i < len; i++) {
        if (cells[i] == 0 || visited.contains(i)) continue;
        final grp = _group(i);
        for (final x in grp) {
          visited.add(x);
        }
        if (_liberties(grp) == 0) {
          toClear.addAll(grp);
        }
      }
      if (toClear.isEmpty) return;
      for (final i in toClear) {
        cells[i] = 0;
      }
    }
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

  /// Piedras vivas en [cells] (sin retirar grupos sin libertad).
  (int black, int white) countStonesOnBoard() {
    var b = 0;
    var w = 0;
    for (var i = 0; i < len; i++) {
      if (cells[i] == 1) b++;
      if (cells[i] == 2) w++;
    }
    return (b, w);
  }

  /// Puntuación **área** (estilo chino) sobre una copia: primero retira grupos con
  /// 0 libertades (fin de partida con pasos), luego piedras + territorio vacío
  /// rodeado solo por un color.
  ///
  /// **Sin** komi; el komi se aplica solo al total de blancas en [areaScore].
  (double black, double whiteOnBoard) areaScoreOnBoard() {
    final g = copy();
    g._removeGroupsWithNoLiberties();
    return g._areaScoreOnBoardFromCurrentCells();
  }

  /// Misma lógica de área pero **sin** retirar capturas (solo diagnóstico / tests).
  (double black, double whiteOnBoard) areaScoreOnBoardRaw() {
    return _areaScoreOnBoardFromCurrentCells();
  }

  (double black, double whiteOnBoard) _areaScoreOnBoardFromCurrentCells() {
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
    return (b, w);
  }

  /// Totales finales: negras [black], blancas [white] = on-board + [komi] para blancas.
  (double black, double white) areaScore() {
    final (b, w0) = areaScoreOnBoard();
    return (b, w0 + komi);
  }

  /// +1 si ganan negras, -1 si ganan blancas, 0 empate.
  double outcomeBlack() {
    final (b, w) = areaScore();
    if (b > w) return 1;
    if (w > b) return -1;
    return 0;
  }
}
