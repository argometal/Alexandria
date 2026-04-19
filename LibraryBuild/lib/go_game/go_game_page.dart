import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_lb_theme.dart';
import '../library_build.dart';
import '../l10n/app_localizations.dart';
import 'go_bot.dart';
import 'go_engine.dart';
import 'go_problems_builtin.dart';
import 'go_study_store.dart';

/// Colores fijos para piedras (no `ColorScheme.onSurface` / `surface`: en tema oscuro
/// se invierten y las negras se ven claras y las blancas oscuras).
const Color _kGoStoneBlack = Color(0xFF121212);
const Color _kGoStoneWhite = Color(0xFFF2F2F2);

enum _GoSection { free, problems }

/// Go 9×9: partida libre (PvP / bot) y **problemas** con progreso en BD.
///
/// Catálogo integrado en [kGoBuiltinProblems]; datos grandes → assets aparte.
class GoGamePage extends StatefulWidget {
  const GoGamePage({super.key, this.db});

  final Database? db;

  @override
  State<GoGamePage> createState() => _GoGamePageState();
}

class _GoGamePageState extends State<GoGamePage> {
  late GoBoard _board;
  _GoSection _section = _GoSection.free;
  bool _vsBot = true;
  final GoBot _bot = GoBot();
  bool _botBusy = false;

  int _problemIndex = 0;
  Map<String, GoProblemProgressRow> _progress = {};
  bool _showLegalFree = false;
  bool _hintVisible = false;

  @override
  void initState() {
    super.initState();
    _board = GoBoard();
    final db = widget.db;
    if (db != null) {
      ensureLibrarySchema(db);
      _progress = goLoadProblemProgress(db);
    }
  }

  void _reloadProgress() {
    final d = widget.db;
    if (d == null) return;
    ensureLibrarySchema(d);
    if (!mounted) return;
    setState(() {
      _progress = goLoadProblemProgress(d);
    });
  }

  GoProblem get _currentProblem =>
      kGoBuiltinProblems[_problemIndex.clamp(0, kGoBuiltinProblems.length - 1)];

  void _applyProblem(int i) {
    final n = kGoBuiltinProblems.length;
    if (n == 0) return;
    _problemIndex = i.clamp(0, n - 1);
    _board = _currentProblem.initialBoard();
    _hintVisible = false;
  }

  void _setSection(_GoSection s) {
    setState(() {
      _section = s;
      _hintVisible = false;
      _showLegalFree = false;
      if (s == _GoSection.problems) {
        _vsBot = false;
        _botBusy = false;
        _applyProblem(_problemIndex);
      } else {
        _board = GoBoard();
        _botBusy = false;
      }
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

  void _recordProblemAttempt({required bool solved}) {
    final d = widget.db;
    if (d == null) return;
    goRecordProblemAttempt(
      d,
      problemId: _currentProblem.id,
      solved: solved,
    );
    _reloadProgress();
  }

  void _onCellTap(int index) {
    if (_board.isTerminal || _botBusy) return;

    if (_section == _GoSection.problems) {
      final p = _currentProblem;
      if (_board.toPlay != p.toPlay) return;
      if (_board.cells[index] != 0) return;

      if (!p.accepts(index)) {
        _recordProblemAttempt(solved: false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.goStudyProblemWrong)),
        );
        return;
      }

      final ok = _board.play(index);
      if (!ok) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.goGameIllegal)),
        );
        return;
      }
      _recordProblemAttempt(solved: true);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.goStudyProblemCorrect)),
      );
      setState(() {});
      return;
    }

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
    if (_section == _GoSection.problems) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.goStudyPassDisabled)),
      );
      return;
    }
    if (_board.isTerminal || _botBusy) return;
    if (_vsBot && _board.toPlay != Stone.black.code) return;
    _board.play(-1);
    setState(() {});
    if (_vsBot) unawaited(_maybeBot());
  }

  void _newGame() {
    setState(() {
      if (_section == _GoSection.problems) {
        _applyProblem(_problemIndex);
      } else {
        _board = GoBoard();
      }
      _botBusy = false;
    });
  }

  Set<int>? get _legalHighlightIndices {
    if (_section != _GoSection.free || !_showLegalFree || _board.isTerminal) {
      return null;
    }
    return {
      for (final m in _board.legalMoves())
        if (m >= 0) m,
    };
  }

  int? get _hintMoveIndex {
    if (_section != _GoSection.problems || !_hintVisible) return null;
    return _currentProblem.solution;
  }

  void _showLibrarySheet() {
    final l10n = AppLocalizations.of(context)!;
    final solved = kGoBuiltinProblems
        .where((p) => (_progress[p.id]?.successCount ?? 0) >= 1)
        .length;
    final mastered = kGoBuiltinProblems
        .where((p) => (_progress[p.id]?.mastered ?? 0) >= 1)
        .length;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dl.goStudyLibraryTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  dl.goStudyLibraryLine(solved, mastered),
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: math.min(
                    420,
                    MediaQuery.sizeOf(ctx).height * 0.45,
                  ),
                  child: ListView.separated(
                    itemCount: kGoBuiltinProblems.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final p = kGoBuiltinProblems[i];
                      final row = _progress[p.id];
                      final succ = row?.successCount ?? 0;
                      final mast = (row?.mastered ?? 0) >= 1;
                      final att = row?.attempts ?? 0;
                      return ListTile(
                        dense: true,
                        title: Text(_problemTitle(dl, p)),
                        subtitle: Text(
                          mast
                              ? dl.goStudyMasteredLabel
                              : (succ >= 1
                                  ? dl.goStudySolvedLabel
                                  : dl.goStudyAttemptsLabel(att)),
                        ),
                        trailing: Icon(
                          mast
                              ? Icons.school_outlined
                              : (succ >= 1
                                  ? Icons.check_circle_outline
                                  : Icons.circle_outlined),
                          color: mast
                              ? AlexandriaLbTheme.gold
                              : Theme.of(c).colorScheme.outline,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _section = _GoSection.problems;
                            _vsBot = false;
                            _applyProblem(i);
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.goStudyBotDisabled,
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _problemTitle(AppLocalizations l10n, GoProblem p) {
    return switch (p.titleL10nKey) {
      'goProblemCapTitle' => l10n.goProblemCapTitle,
      'goProblemConnectTitle' => l10n.goProblemConnectTitle,
      'goProblemBridgeTitle' => l10n.goProblemBridgeTitle,
      _ => p.id,
    };
  }

  String _problemHint(AppLocalizations l10n, GoProblem p) {
    return switch (p.hintL10nKey) {
      'goProblemCapHint' => l10n.goProblemCapHint,
      'goProblemConnectHint' => l10n.goProblemConnectHint,
      'goProblemBridgeHint' => l10n.goProblemBridgeHint,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goGameTitle),
        actions: [
          IconButton(
            tooltip: l10n.goStudyLibraryTooltip,
            onPressed: _showLibrarySheet,
            icon: const Icon(Icons.menu_book_outlined),
          ),
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
            child: SegmentedButton<_GoSection>(
              segments: [
                ButtonSegment<_GoSection>(
                  value: _GoSection.free,
                  label: Text(l10n.goStudyTabFree),
                  icon: const Icon(Icons.sports_esports_outlined, size: 18),
                ),
                ButtonSegment<_GoSection>(
                  value: _GoSection.problems,
                  label: Text(l10n.goStudyTabProblems),
                  icon: const Icon(Icons.extension_outlined, size: 18),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                _setSection(s.first);
              },
            ),
          ),
          if (_section == _GoSection.free) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilterChip(
                label: Text(l10n.goStudyShowLegal),
                selected: _showLegalFree,
                onSelected: (v) => setState(() => _showLegalFree = v),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                _problemTitle(l10n, _currentProblem),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    l10n.goStudyProblemIndex(
                      _problemIndex + 1,
                      kGoBuiltinProblems.length,
                    ),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.goStudyPrevProblem,
                    onPressed: _problemIndex <= 0
                        ? null
                        : () => setState(() {
                              _applyProblem(_problemIndex - 1);
                            }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: l10n.goStudyNextProblem,
                    onPressed: _problemIndex >= kGoBuiltinProblems.length - 1
                        ? null
                        : () => setState(() {
                              _applyProblem(_problemIndex + 1);
                            }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _hintVisible = !_hintVisible;
                      });
                      if (_hintVisible) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _problemHint(l10n, _currentProblem),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.lightbulb_outline, size: 20),
                    label: Text(l10n.goStudyHint),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _applyProblem(_problemIndex)),
                    icon: const Icon(Icons.restart_alt, size: 20),
                    label: Text(l10n.goStudyResetProblem),
                  ),
                ],
              ),
            ),
          ],
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
                        legalMarks: _legalHighlightIndices,
                        hintMoveIndex: _hintMoveIndex,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _scoreLine(l10n),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stoneCountLine(l10n),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
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
    final (b, wBoard) = _board.areaScoreOnBoard();
    final k = _board.komi;
    final wTotal = wBoard + k;
    const eps = 1e-6;
    late String verdict;
    if ((b - wTotal).abs() < eps) {
      verdict = l10n.goGameVerdictDraw;
    } else if (b > wTotal) {
      verdict = l10n.goGameVerdictBlackWins((b - wTotal).toStringAsFixed(1));
    } else {
      verdict = l10n.goGameVerdictWhiteWins((wTotal - b).toStringAsFixed(1));
    }
    return l10n.goGameScoreSummary(
      b.toStringAsFixed(1),
      wBoard.toStringAsFixed(1),
      k.toStringAsFixed(1),
      wTotal.toStringAsFixed(1),
      verdict,
    );
  }

  String _stoneCountLine(AppLocalizations l10n) {
    final (nb, nw) = _board.countStonesOnBoard();
    return l10n.goGameStoneTotals(nb, nw);
  }
}

class _GoBoardPainterWidget extends StatelessWidget {
  const _GoBoardPainterWidget({
    required this.sizePx,
    required this.board,
    required this.onTap,
    this.legalMarks,
    this.hintMoveIndex,
  });

  final double sizePx;
  final GoBoard board;
  final void Function(int index) onTap;
  final Set<int>? legalMarks;
  final int? hintMoveIndex;

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
          blackStone: _kGoStoneBlack,
          whiteStone: _kGoStoneWhite,
          legalMarks: legalMarks,
          hintMoveIndex: hintMoveIndex,
          legalColor: cs.tertiary.withValues(alpha: 0.85),
          hintColor: cs.primary.withValues(alpha: 0.45),
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
    this.legalMarks,
    this.hintMoveIndex,
    required this.legalColor,
    required this.hintColor,
  });

  final GoBoard board;
  final Color lineColor;
  final Color blackStone;
  final Color whiteStone;
  final Set<int>? legalMarks;
  final int? hintMoveIndex;
  final Color legalColor;
  final Color hintColor;

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

    final hintIdx = hintMoveIndex;
    if (hintIdx != null &&
        hintIdx >= 0 &&
        hintIdx < board.len &&
        board.cells[hintIdx] == 0) {
      final r = hintIdx ~/ n;
      final c = hintIdx % n;
      final cx = pad + c * cell;
      final cy = pad + r * cell;
      canvas.drawCircle(
        Offset(cx, cy),
        cell * 0.22,
        Paint()..color = hintColor,
      );
    }

    final marks = legalMarks;
    if (marks != null && marks.isNotEmpty) {
      final dotR = cell * 0.12;
      for (final i in marks) {
        if (i < 0 || i >= board.len || board.cells[i] != 0) continue;
        final r = i ~/ n;
        final c = i % n;
        canvas.drawCircle(
          Offset(pad + c * cell, pad + r * cell),
          dotR,
          Paint()..color = legalColor,
        );
      }
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
