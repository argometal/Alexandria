import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_lb_theme.dart';
import '../l10n/app_localizations.dart';
import 'match_cards_store.dart';

class _Tile {
  _Tile({
    required this.pairId,
    required this.isImage,
    required this.imagePath,
    required this.caption,
    this.transliteration,
  });

  final int pairId;
  final bool isImage;
  final String imagePath;
  final String caption;
  final String? transliteration;
}

/// Grid matching: all tiles visible, shuffled; tap two to pair; matched tiles vanish. Text = lemma + optional transliteration (no gloss).
class MatchCardsSessionPage extends StatefulWidget {
  const MatchCardsSessionPage({
    super.key,
    required this.db,
    required this.deckId,
    /// Mazos disponibles para cambiar sin salir (misma pantalla de lista).
    this.decks = const [],
    /// Max pairs in one round (e.g. 8 → 16 cards).
    this.maxPairs = 8,
  });

  final Database db;
  final int deckId;
  final List<LbMatchDeckRow> decks;
  final int maxPairs;

  @override
  State<MatchCardsSessionPage> createState() => _MatchCardsSessionPageState();
}

class _MatchCardsSessionPageState extends State<MatchCardsSessionPage> {
  final List<_Tile> _tiles = [];
  /// First selected index (highlighted).
  int? _selA;
  /// Second index while evaluating a pair (brief wrong flash).
  int? _selB;
  bool _busy = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _buildDeck();
  }

  String _deckName(AppLocalizations l10n) {
    for (final d in widget.decks) {
      if (d.id == widget.deckId) return d.name;
    }
    return '${l10n.matchCardsDeckLabel} #${widget.deckId}';
  }

  void _buildDeck() {
    final pairs = lbPickRandomPairsForSession(
      widget.db,
      deckId: widget.deckId,
      maxPairs: widget.maxPairs,
    );
    _tiles.clear();
    _selA = null;
    _selB = null;
    _busy = false;
    _attempts = 0;
    for (final p in pairs) {
      final path = p.imageAbsolutePath;
      _tiles.add(
        _Tile(
          pairId: p.id,
          isImage: true,
          imagePath: path,
          caption: p.captionText,
          transliteration: p.transliteration,
        ),
      );
      _tiles.add(
        _Tile(
          pairId: p.id,
          isImage: false,
          imagePath: path,
          caption: p.captionText,
          transliteration: p.transliteration,
        ),
      );
    }
    _tiles.shuffle();
    setState(() {});
  }

  void _openDeck(int newDeckId) {
    if (newDeckId == widget.deckId) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MatchCardsSessionPage(
          db: widget.db,
          deckId: newDeckId,
          decks: widget.decks,
          maxPairs: widget.maxPairs,
        ),
      ),
    );
  }

  Future<void> _showDeckPicker() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  l10n.matchCardsSessionPickDeckTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              for (final d in widget.decks)
                ListTile(
                  leading: Icon(
                    d.id == widget.deckId
                        ? Icons.check_circle_outline
                        : Icons.folder_outlined,
                    color: d.id == widget.deckId
                        ? AlexandriaLbTheme.gold
                        : null,
                  ),
                  title: Text(d.name),
                  selected: d.id == widget.deckId,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openDeck(d.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStatsSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final stats = lbListMatchPairStats(widget.db, deckId: widget.deckId);
    final hasAny =
        stats.any((s) => s.failCount > 0 || s.passCount > 0);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (ctx, scroll) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.matchCardsSessionStatsTitle,
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.matchCardsSessionStatsSubtitle,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!hasAny)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.matchCardsSessionStatsEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: stats.length,
                      itemBuilder: (c, i) {
                        final s = stats[i];
                        return ListTile(
                          title: Text(
                            s.pair.captionText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: (s.pair.transliteration ?? '')
                                  .trim()
                                  .isEmpty
                              ? null
                              : Text(
                                  s.pair.transliteration!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10n.matchCardsSessionStatsFailPass(
                                  s.failCount,
                                  s.passCount,
                                ),
                                style: Theme.of(ctx).textTheme.labelLarge,
                              ),
                              Text(
                                l10n.matchCardsSessionStatsFib(s.fibIndex),
                                style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _onTap(int i) async {
    if (_busy || _tiles.isEmpty) return;
    if (_selB != null) return;

    if (_selA == null) {
      setState(() => _selA = i);
      return;
    }
    if (_selA == i) {
      setState(() => _selA = null);
      return;
    }

    final a = _selA!;
    final b = i;
    setState(() {
      _selB = b;
      _busy = true;
    });

    final ta = _tiles[a];
    final tb = _tiles[b];
    final ok = ta.pairId == tb.pairId && ta.isImage != tb.isImage;
    setState(() => _attempts++);

    if (ok) {
      final hi = a > b ? a : b;
      final lo = a > b ? b : a;
      final matchedId = ta.pairId;
      lbRecordMatchPairOutcome(widget.db, pairId: matchedId, pass: true);
      setState(() {
        _tiles.removeAt(hi);
        _tiles.removeAt(lo);
        _selA = null;
        _selB = null;
        _busy = false;
      });
      return;
    }

    lbRecordMatchPairOutcome(widget.db, pairId: ta.pairId, pass: false);
    lbRecordMatchPairOutcome(widget.db, pairId: tb.pairId, pass: false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.matchCardsNoMatch),
        duration: const Duration(milliseconds: 700),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _selA = null;
      _selB = null;
      _busy = false;
    });
  }

  bool get _won => _tiles.isEmpty;

  int _gridCrossAxisCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 820) return 5;
    if (width >= 560) return 4;
    if (width >= 380) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_tiles.length < 4) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.matchCardsSessionTitle),
          actions: [
            if (widget.decks.length > 1)
              TextButton(
                onPressed: _showDeckPicker,
                child: Text(l10n.matchCardsSessionChangeDeck),
              ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.matchCardsNeedTwoPairs,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.matchCardsSessionTitle),
            if (widget.decks.isNotEmpty)
              Text(
                _deckName(l10n),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.matchCardsSessionNewRound,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _buildDeck,
          ),
          PopupMenuButton<String>(
            tooltip: l10n.matchCardsSessionMenuTooltip,
            onSelected: (v) {
              switch (v) {
                case 'round':
                  _buildDeck();
                  break;
                case 'deck':
                  _showDeckPicker();
                  break;
                case 'stats':
                  _showStatsSheet();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'round',
                child: Text(l10n.matchCardsSessionNewRound),
              ),
              if (widget.decks.length > 1)
                PopupMenuItem(
                  value: 'deck',
                  child: Text(l10n.matchCardsSessionChangeDeck),
                ),
              PopupMenuItem(
                value: 'stats',
                child: Text(l10n.matchCardsSessionStats),
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.matchCardsComplete),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cols = _gridCrossAxisCount(constraints.maxWidth);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    Text(
                      l10n.matchCardsAttempts(_attempts),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${_tiles.length ~/ 2} ${l10n.matchCardsPairsRemaining}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    if (_won) ...[
                      const SizedBox(width: 12),
                      Text(
                        l10n.matchCardsComplete,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AlexandriaLbTheme.gold,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: _tiles.length,
                  itemBuilder: (context, i) {
                    final t = _tiles[i];
                    final selected = _selA == i || _selB == i;
                    return _SessionCard(
                      selected: selected,
                      tile: t,
                      onTap: _busy ? null : () => _onTap(i),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.selected,
    required this.tile,
    required this.onTap,
  });

  final bool selected;
  final _Tile tile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = BorderRadius.circular(10);
    return Material(
      color: cs.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: BorderSide(
          color: selected ? AlexandriaLbTheme.gold : Colors.transparent,
          width: selected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: r),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Center(
            child: tile.isImage
                ? _SmallImage(path: tile.imagePath)
                : _SmallTextFace(
                    lemma: tile.caption,
                    transliteration: tile.transliteration,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Escala de tipografía respecto al tema base en caras de texto (práctica).
const double _kMatchCardFaceFontScale = 1.6;

double? _scaledFontSize(TextStyle? style, double scale) {
  final s = style?.fontSize;
  if (s == null) return null;
  return s * scale;
}

class _SmallTextFace extends StatelessWidget {
  const _SmallTextFace({
    required this.lemma,
    this.transliteration,
  });

  final String lemma;
  final String? transliteration;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final lemmaStyle = t.titleSmall?.copyWith(
      fontSize: _scaledFontSize(t.titleSmall, _kMatchCardFaceFontScale),
      height: 1.28,
    );
    final transStyle = t.labelSmall?.copyWith(
      fontSize: _scaledFontSize(t.labelSmall, _kMatchCardFaceFontScale),
      fontStyle: FontStyle.italic,
      color: cs.onSurfaceVariant,
      height: 1.25,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        const padH = 12.0;
        final w = constraints.maxWidth;
        final innerW = !w.isFinite
            ? 160.0
            : (w - padH).clamp(32.0, w);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: innerW,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lemma,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 12,
                    style: lemmaStyle,
                  ),
                  if (transliteration != null && transliteration!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      transliteration!,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 8,
                      style: transStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SmallImage extends StatelessWidget {
  const _SmallImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final f = File(path);
    if (!f.existsSync()) {
      return Icon(
        Icons.broken_image_outlined,
        size: 22,
        color: Theme.of(context).colorScheme.outline,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        f,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
