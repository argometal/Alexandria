import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_paths.dart';
import '../library_build.dart';
import '../l10n/app_localizations.dart';

/// Tamaño del rango + palo en práctica y tabla (referencia visual: lista PAO en editor usa tile ~120px).
const double _kPokerCardSymbolSizeDrill = 64;
const double _kPokerCardSymbolSizeMap = 44;
const double _kPokerCardSymbolSizeAnswer = 56;

/// Palos que en muchas fuentes se dibujan como “negros”; en tema oscuro pueden perderse sobre el fondo.
bool _pokerBlackSuit(int suitIndex) =>
    suitIndex == kPokerSuitSpades || suitIndex == kPokerSuitClubs;

Widget _pokerCardRichText(
  PokerCardRef c,
  ThemeData theme, {
  required double fontSize,
  TextAlign align = TextAlign.center,
}) {
  final isRed =
      c.suitIndex == kPokerSuitHearts || c.suitIndex == kPokerSuitDiamonds;
  final color = isRed ? Colors.red.shade700 : theme.colorScheme.onSurface;
  final baseStyle = theme.textTheme.displayLarge?.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        height: 1.05,
        color: color,
      ) ??
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        height: 1.05,
        color: color,
      );
  final label = '${pokerRankChar(c.rankIndex)}${pokerSuitSymbol(c.suitIndex)}';

  final needsDarkOutline = theme.brightness == Brightness.dark &&
      !isRed &&
      _pokerBlackSuit(c.suitIndex);
  if (!needsDarkOutline) {
    return Text(label, textAlign: align, style: baseStyle);
  }

  final outline = Color.lerp(theme.colorScheme.surface, Colors.white, 0.55)!;
  final strokeW = fontSize >= 52 ? 2.25 : 1.75;
  return Stack(
    alignment: Alignment.center,
    children: [
      Text(
        label,
        textAlign: align,
        style: baseStyle.copyWith(
          color: null,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeJoin = StrokeJoin.round
            ..color = outline,
        ),
      ),
      Text(label, textAlign: align, style: baseStyle),
    ],
  );
}

/// Ayuda memorización rápida **número ↔ carta** (52 cartas de póker): rangos por palo editables.
class PokerMemoryPage extends StatefulWidget {
  const PokerMemoryPage({super.key, required this.db});

  final Database db;

  @override
  State<PokerMemoryPage> createState() => _PokerMemoryPageState();
}

class _PokerMemoryPageState extends State<PokerMemoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<PokerSuitRange> _ranges = [];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    ensureLibrarySchema(widget.db);
    setState(() {
      _ranges = loadPokerMemoryRanges(widget.db);
    });
  }

  String? _validationError() => validatePokerRanges(_ranges);

  List<PokerNumberCardMapping> get _table {
    final err = _validationError();
    if (err != null) return [];
    return buildPokerMappingTable(_ranges);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pokerMemoryTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.pokerMemoryTabMap),
            Tab(text: l10n.pokerMemoryTabRanges),
            Tab(text: l10n.pokerMemoryTabDrill),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PokerMapTab(table: _table, l10n: l10n, validationError: _validationError()),
          _PokerRangesTab(
            db: widget.db,
            initialRanges: _ranges,
            onSaved: _reload,
            l10n: l10n,
          ),
          _PokerDrillTab(
            table: _table,
            validationError: _validationError(),
            l10n: l10n,
            rng: _rng,
          ),
        ],
      ),
    );
  }
}

class _PokerMapTab extends StatelessWidget {
  const _PokerMapTab({
    required this.table,
    required this.l10n,
    required this.validationError,
  });

  final List<PokerNumberCardMapping> table;
  final AppLocalizations l10n;
  final String? validationError;

  @override
  Widget build(BuildContext context) {
    if (validationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            validationError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    if (table.isEmpty) {
      return Center(child: Text(l10n.pokerMemoryMapEmpty));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: table.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.pokerMemoryMapIntro,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        final m = table[i - 1];
        final card = m.card;
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            minLeadingWidth: 56,
            leading: CircleAvatar(
              radius: 26,
              child: Text(
                formatPokerNumberForDisplay(m.number),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              formatPokerNumberForDisplay(m.number),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: _pokerCardRichText(
              card,
              Theme.of(context),
              fontSize: _kPokerCardSymbolSizeMap,
              align: TextAlign.end,
            ),
          ),
        );
      },
    );
  }
}

class _PokerRangesTab extends StatefulWidget {
  const _PokerRangesTab({
    required this.db,
    required this.initialRanges,
    required this.onSaved,
    required this.l10n,
  });

  final Database db;
  final List<PokerSuitRange> initialRanges;
  final VoidCallback onSaved;
  final AppLocalizations l10n;

  @override
  State<_PokerRangesTab> createState() => _PokerRangesTabState();
}

class _PokerRangesTabState extends State<_PokerRangesTab> {
  late List<TextEditingController> _startCtrls;
  late List<TextEditingController> _endCtrls;
  var _controllersReady = false;

  @override
  void initState() {
    super.initState();
    _syncFrom(widget.initialRanges);
  }

  @override
  void didUpdateWidget(covariant _PokerRangesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRanges != widget.initialRanges) {
      _syncFrom(widget.initialRanges);
    }
  }

  void _disposeCtrls() {
    if (!_controllersReady) return;
    for (final c in _startCtrls) {
      c.dispose();
    }
    for (final c in _endCtrls) {
      c.dispose();
    }
    _controllersReady = false;
  }

  void _syncFrom(List<PokerSuitRange> ranges) {
    _disposeCtrls();
    final by = <int, PokerSuitRange>{};
    for (final r in ranges) {
      by[r.suitIndex] = r;
    }
    _startCtrls = List.generate(
      4,
      (s) => TextEditingController(
        text: '${by[s]?.rangeStart ?? 1}',
      ),
    );
    _endCtrls = List.generate(
      4,
      (s) => TextEditingController(
        text: '${by[s]?.rangeEnd ?? 13}',
      ),
    );
    _controllersReady = true;
  }

  @override
  void dispose() {
    _disposeCtrls();
    super.dispose();
  }

  String _suitLabel(int s, AppLocalizations l10n) {
    switch (s) {
      case kPokerSuitSpades:
        return l10n.pokerMemorySuitSpades;
      case kPokerSuitHearts:
        return l10n.pokerMemorySuitHearts;
      case kPokerSuitDiamonds:
        return l10n.pokerMemorySuitDiamonds;
      case kPokerSuitClubs:
        return l10n.pokerMemorySuitClubs;
      default:
        return '?';
    }
  }

  Future<void> _save() async {
    final l10n = widget.l10n;
    final list = <PokerSuitRange>[];
    for (var s = 0; s < 4; s++) {
      final a = int.tryParse(_startCtrls[s].text.trim());
      final b = int.tryParse(_endCtrls[s].text.trim());
      if (a == null || b == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pokerMemoryRangesInvalidNumber)),
        );
        return;
      }
      list.add(PokerSuitRange(suitIndex: s, rangeStart: a, rangeEnd: b));
    }
    final err = validatePokerRanges(list);
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
      return;
    }
    try {
      savePokerMemoryRanges(widget.db, list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return;
    }
    widget.onSaved();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.pokerMemoryRangesSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.pokerMemoryRangesIntro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        for (var s = 0; s < 4; s++) ...[
          Text(
            '${_suitLabel(s, l10n)} ${pokerSuitSymbol(s)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startCtrls[s],
                  decoration: InputDecoration(
                    labelText: l10n.pokerMemoryRangeFrom,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _endCtrls[s],
                  decoration: InputDecoration(
                    labelText: l10n.pokerMemoryRangeTo,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(l10n.pokerMemoryRangesSave),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.pokerMemoryRangesHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

enum _DrillMode {
  numberToCard,
  cardToNumber,
}

class _PokerDrillTab extends StatefulWidget {
  const _PokerDrillTab({
    required this.table,
    required this.validationError,
    required this.l10n,
    required this.rng,
  });

  final List<PokerNumberCardMapping> table;
  final String? validationError;
  final AppLocalizations l10n;
  final math.Random rng;

  @override
  State<_PokerDrillTab> createState() => _PokerDrillTabState();
}

class _PokerDrillTabState extends State<_PokerDrillTab> {
  PokerNumberCardMapping? _current;
  bool _answersVisible = false;
  int _modeOrd = 0;

  @override
  void initState() {
    super.initState();
    _pickRound(rotateMode: false);
  }

  @override
  void didUpdateWidget(covariant _PokerDrillTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table != widget.table && widget.table.isNotEmpty) {
      _pickRound(rotateMode: false);
    }
  }

  void _pickRound({required bool rotateMode}) {
    final pool = widget.table;
    if (pool.isEmpty) return;
    setState(() {
      if (rotateMode) {
        _modeOrd = (_modeOrd + 1) % 2;
      }
      _current = pool[widget.rng.nextInt(pool.length)];
      _answersVisible = false;
    });
  }

  _DrillMode get _mode =>
      _modeOrd == 0 ? _DrillMode.numberToCard : _DrillMode.cardToNumber;

  Widget _cardText(PokerCardRef c, ThemeData theme, {double fontSize = _kPokerCardSymbolSizeDrill}) =>
      _pokerCardRichText(c, theme, fontSize: fontSize);

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    if (widget.validationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.validationError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    final pool = widget.table;
    if (pool.isEmpty || _current == null) {
      return Center(child: Text(l10n.pokerMemoryDrillEmpty));
    }
    final m = _current!;
    final mode = _mode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.pokerMemoryDrillInstruction, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              avatar: const Icon(Icons.shuffle, size: 18),
              label: Text(
                mode == _DrillMode.numberToCard
                    ? l10n.pokerMemoryDrillModeNumberToCard
                    : l10n.pokerMemoryDrillModeCardToNumber,
              ),
            ),
            Text(
              l10n.pokerMemoryDrillPoolInfo(pool.length, AlexandriaPaths.readActiveRealmId()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (mode == _DrillMode.numberToCard) ...[
                  Text(l10n.pokerMemoryStimulusNumber, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Text(
                    formatPokerNumberForDisplay(m.number),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ] else ...[
                  Text(l10n.pokerMemoryStimulusCard, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  _cardText(m.card, Theme.of(context)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!_answersVisible)
          FilledButton.icon(
            onPressed: () => setState(() => _answersVisible = true),
            icon: const Icon(Icons.visibility_outlined),
            label: Text(l10n.pokerMemoryShowAnswer),
          )
        else ...[
          Text(l10n.pokerMemoryAnswerHeading, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.pokerMemoryAnswerNumber),
            trailing: Text(
              formatPokerNumberForDisplay(m.number),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            title: Text(l10n.pokerMemoryAnswerCard),
            trailing: _cardText(
              m.card,
              Theme.of(context),
              fontSize: _kPokerCardSymbolSizeAnswer,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pickRound(rotateMode: true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.pokerMemoryPass),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pickRound(rotateMode: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l10n.pokerMemoryFail),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _pickRound(rotateMode: false),
            icon: const Icon(Icons.skip_next),
            label: Text(l10n.pokerMemoryNext),
          ),
        ],
      ],
    );
  }
}
