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
    /// Max pairs in one round (e.g. 8 → 16 cards).
    this.maxPairs = 8,
  });

  final Database db;
  final int deckId;
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
        appBar: AppBar(title: Text(l10n.matchCardsSessionTitle)),
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
        title: Text(l10n.matchCardsSessionTitle),
        actions: [
          TextButton(
            onPressed: _buildDeck,
            child: Text(l10n.matchCardsPlayAgain),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lemma,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: t.titleSmall?.copyWith(height: 1.25),
            ),
            if (transliteration != null && transliteration!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transliteration!,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: t.labelSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
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
