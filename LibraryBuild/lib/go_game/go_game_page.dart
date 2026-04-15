import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';

import '../alexandria_lb_theme.dart';
import '../l10n/app_localizations.dart';
import 'go_bot.dart';
import 'go_engine.dart';

/// Go 9×9: dos humanos o humano (negras) vs bot (blancas + komi).
class GoGamePage extends StatefulWidget {
  const GoGamePage({super.key});

  @override
  State<GoGamePage> createState() => _GoGamePageState();
}

class _GoGamePageState extends State<GoGamePage> {
  late GoBoard _board;
  bool _vsBot = true;
  final GoBot _bot = GoBot();
  bool _botBusy = false;

  @override
  void initState() {
    super.initState();
    _board = GoBoard();
  }

  void _newGame() {
    setState(() {
      _board = GoBoard();
      _botBusy = false;
    });
  }

  Future<void> _maybeBot() async {
    if (!_vsBot || _board.isTerminal || _botBusy) return;
    if (_board.toPlay != Stone.white.code) return;
    setState(() => _botBusy = true);
    try {
      final args = GoBotIsolateArgs(
        snapshot: _board.toSnapshot(),
        botColor: Stone.white.code,
        rolloutsPerMove: _bot.rolloutsPerMove,
      );
      final m = await compute(goBotChooseInIsolate, args);
      if (!mounted) return;
      setState(() {
        _board.play(m);
        _botBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _botBusy = false);
    }
  }

  void _onCellTap(int index) {
    if (_board.isTerminal || _botBusy) return;
    if (_vsBot && _board.toPlay != Stone.black.code) return;
    if (_board.cells[index] != 0) return;
    final ok = _board.play(index);
    if (!ok) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.goGameIllegal)),
      );
      return;
    }
    setState(() {});
    if (_vsBot) unawaited(_maybeBot());
  }

  void _pass() {
    if (_board.isTerminal || _botBusy) return;
    if (_vsBot && _board.toPlay != Stone.black.code) return;
    _board.play(-1);
    setState(() {});
    if (_vsBot) unawaited(_maybeBot());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goGameTitle),
        actions: [
          TextButton(
            onPressed: _newGame,
            child: Text(l10n.goGameNew),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              l10n.goGameSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: false,
                  label: Text(l10n.goGameModePvp),
                  icon: const Icon(Icons.people_outline, size: 18),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(l10n.goGameModeBot),
                  icon: const Icon(Icons.smart_toy_outlined, size: 18),
                ),
              ],
              selected: {_vsBot},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                setState(() {
                  _vsBot = s.first;
                  _board = GoBoard();
                  _botBusy = false;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _board.isTerminal
                        ? l10n.goGameOver
                        : (_board.toPlay == Stone.black.code
                            ? l10n.goGameBlackTurn
                            : l10n.goGameWhiteTurn),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_botBusy)
                  Text(
                    l10n.goGameBotThinking,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AlexandriaLbTheme.gold,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final side = math.min(c.maxWidth, c.maxHeight);
                      return _GoBoardPainterWidget(
                        sizePx: side,
                        board: _board,
                        onTap: _onCellTap,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                FilledButton.tonal(
                  onPressed: _board.isTerminal || _botBusy ? null : _pass,
                  child: Text(l10n.goGamePass),
                ),
                const SizedBox(width: 16),
                if (_board.isTerminal)
                  Expanded(
                    child: Text(
                      _scoreLine(l10n),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scoreLine(AppLocalizations l10n) {
    final (b, w) = _board.areaScore();
    return l10n.goGameScoreLine(b.toStringAsFixed(1), w.toStringAsFixed(1), _board.komi.toStringAsFixed(1));
  }
}

class _GoBoardPainterWidget extends StatelessWidget {
  const _GoBoardPainterWidget({
    required this.sizePx,
    required this.board,
    required this.onTap,
  });

  final double sizePx;
  final GoBoard board;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapUp: (d) {
        final p = d.localPosition;
        final cell = sizePx / board.size;
        final c = (p.dx / cell).floor().clamp(0, board.size - 1);
        final r = (p.dy / cell).floor().clamp(0, board.size - 1);
        onTap(board.idx(r, c));
      },
      child: CustomPaint(
        size: Size(sizePx, sizePx),
        painter: _BoardPainter(
          board: board,
          lineColor: cs.outline,
          blackStone: cs.onSurface,
          whiteStone: cs.surface,
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.lineColor,
    required this.blackStone,
    required this.whiteStone,
  });

  final GoBoard board;
  final Color lineColor;
  final Color blackStone;
  final Color whiteStone;

  @override
  void paint(Canvas canvas, Size size) {
    final n = board.size;
    final cell = size.width / n;
    final pad = cell * 0.5;

    final bg = Paint()..color = const Color(0xFFD4A574);
    canvas.drawRect(Offset.zero & size, bg);

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2;
    for (var i = 0; i < n; i++) {
      final x = pad + i * cell;
      canvas.drawLine(Offset(x, pad), Offset(x, size.height - pad), line);
      canvas.drawLine(Offset(pad, x), Offset(size.width - pad, x), line);
    }

    const hoshi = <(int, int)>[(2, 2), (6, 2), (2, 6), (6, 6), (4, 4)];
    for (final p in hoshi) {
      canvas.drawCircle(
        Offset(pad + p.$2 * cell, pad + p.$1 * cell),
        3,
        Paint()..color = lineColor,
      );
    }

    final stoneR = cell * 0.42;
    for (var i = 0; i < board.len; i++) {
      final v = board.cells[i];
      if (v == 0) continue;
      final r = i ~/ n;
      final c = i % n;
      final cx = pad + c * cell;
      final cy = pad + r * cell;
      final fill = v == Stone.black.code ? blackStone : whiteStone;
      canvas.drawCircle(
        Offset(cx, cy),
        stoneR,
        Paint()..color = fill,
      );
      if (v == Stone.white.code) {
        canvas.drawCircle(
          Offset(cx, cy),
          stoneR,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
