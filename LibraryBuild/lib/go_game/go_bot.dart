import 'dart:math' as math;

import 'go_engine.dart';

/// Argumento para [goBotChooseInIsolate] / [compute] (evita congelar la UI).
class GoBotIsolateArgs {
  GoBotIsolateArgs({
    required this.snapshot,
    required this.botColor,
    required this.rolloutsPerMove,
  });

  final GoBoardSnapshot snapshot;
  final int botColor;
  final int rolloutsPerMove;
}

/// Top-level para [compute]: debe ser función global, no método de instancia.
int goBotChooseInIsolate(GoBotIsolateArgs args) {
  final board = GoBoard.fromSnapshot(args.snapshot);
  final bot = GoBot(rolloutsPerMove: args.rolloutsPerMove);
  return bot.choose(board, args.botColor);
}

/// Bot por **Monte Carlo** (promedio de rollouts tras cada jugada legal). Jugable en 9×9 sin dependencias.
///
/// Parámetros ajustados para **respuesta rápida** en isolate: pocas jugadas candidatas
/// cuando el tablero está abierto, pocos rollouts y partidas simuladas cortas.
class GoBot {
  GoBot({
    this.rolloutsPerMove = 8,
    this.maxCandidateMoves = 12,
    this.maxRolloutPlies = 100,
    math.Random? rng,
  }) : _rng = rng ?? math.Random();

  /// Partidas simuladas por jugada candidata (sube fuerza, sube tiempo).
  final int rolloutsPerMove;

  /// Tope de jugadas a evaluar; si hay más legales, se elige una muestra aleatoria (+ paso).
  final int maxCandidateMoves;

  /// Máximo de piedras por simulación (evita tableros casi llenos eternos).
  final int maxRolloutPlies;

  final math.Random _rng;

  /// Subconjunto de [legal] para no gastar O(|legal| × rollouts) al inicio de partida.
  List<int> _candidateMoves(List<int> legal) {
    if (legal.length <= maxCandidateMoves) return List<int>.from(legal);
    final hasPass = legal.contains(-1);
    final nonPass = <int>[for (final m in legal) if (m != -1) m];
    nonPass.shuffle(_rng);
    final reservePass = hasPass ? 1 : 0;
    final take = maxCandidateMoves - reservePass;
    final out = nonPass.take(take).toList();
    if (hasPass) out.add(-1);
    return out;
  }

  /// [botColor] = quien es el bot (1 negras, 2 blancas).
  int choose(GoBoard board, int botColor) {
    final legal = board.legalMoves();
    if (legal.isEmpty) return -1;
    if (legal.length == 1) return legal.first;

    final toEval = _candidateMoves(legal);
    var best = toEval.first;
    var bestAvg = -1.0;

    for (final m in toEval) {
      var sum = 0.0;
      var used = 0;
      for (var k = 0; k < rolloutsPerMove; k++) {
        final root = board.copy();
        if (!root.play(m)) continue;
        used++;
        sum += _rolloutWinProb(root, botColor);
      }
      final avg = used > 0 ? sum / used : 0.0;
      if (avg > bestAvg) {
        bestAvg = avg;
        best = m;
      }
    }
    return best;
  }

  double _rolloutWinProb(GoBoard start, int botColor) {
    var s = start.copy();
    var steps = 0;
    while (!s.isTerminal && steps < maxRolloutPlies) {
      final lm = s.legalMoves();
      if (lm.isEmpty) break;
      s.play(lm[_rng.nextInt(lm.length)]);
      steps++;
    }
    final ob = s.outcomeBlack();
    if (ob == 0) return 0.5;
    if (botColor == Stone.black.code) return ob > 0 ? 1.0 : 0.0;
    return ob < 0 ? 1.0 : 0.0;
  }
}
