import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import 'fts_object_search.dart';
import 'library_build.dart';
import 'l10n/app_localizations.dart';
import 'node_card_reader_page.dart';
import 'usage_tier_l10n.dart';

/// Resultado al elegir un locus desde la búsqueda (bridge + lista principal).
class ObjectSearchPick {
  const ObjectSearchPick({
    required this.parentKey,
    required this.focusKey,
  });

  final String parentKey;
  final String focusKey;
}

class ObjectSearchPage extends StatefulWidget {
  const ObjectSearchPage({super.key, required this.db});

  final Database db;

  @override
  State<ObjectSearchPage> createState() => _ObjectSearchPageState();
}

class _ObjectSearchPageState extends State<ObjectSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Map<String, UsageBand> _bands = {};
  List<ObjectSearchHit> _hits = [];
  String? _ftsError;
  /// `null` = Core + Active + Seek; si no, solo esa banda.
  UsageBand? _bandFilter;

  @override
  void initState() {
    super.initState();
    ensureLibrarySchema(widget.db);
    _bands = computeObjectUsageBands(widget.db);
    _runSearch('');
    _controller.addListener(_onChanged);
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      final t = _controller.text;
      if (t != _query) {
        setState(() => _query = t);
        _runSearch(t);
      }
    });
  }

  void _runSearch(String q) {
    try {
      _ftsError = null;
      final list = searchObjects(widget.db, q, bands: _bands);
      setState(() => _hits = list);
    } catch (e) {
      setState(() {
        _ftsError = e.toString();
        _hits = [];
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  String _plainPreview(String? body, int max) {
    final blocks = parseBody(body);
    final buf = StringBuffer();
    for (final b in blocks) {
      if (shouldOmitFromLocusReadingExport(b)) continue;
      final t = (b['text'] ?? b['key'] ?? '').toString();
      if (t.isNotEmpty) {
        buf.write(t);
        buf.write(' ');
      }
      if (buf.length > max + 40) break;
    }
    var s = buf.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.length > max) s = '${s.substring(0, max)}…';
    return s.isEmpty ? '—' : s;
  }

  Widget _leading(String key, String? body) {
    final path = resolveListHeroThumbPath(key, body);
    if (path != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.article_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  List<ObjectSearchHit> _orderedHits() {
    final copy = List<ObjectSearchHit>.from(_hits);
    copy.sort((a, b) {
      final bo = a.band.index.compareTo(b.band.index);
      if (bo != 0) return bo;
      if (_query.trim().isNotEmpty) {
        final r = a.bm25.compareTo(b.bm25);
        if (r != 0) return r;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return copy;
  }

  List<Widget> _buildSections(
    List<ObjectSearchHit> ordered,
    AppLocalizations l,
  ) {
    final cs = Theme.of(context).colorScheme;
    Widget bandHeader(UsageBand b) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(
          children: [
            Icon(
              switch (b) {
                UsageBand.core => Icons.bolt_outlined,
                UsageBand.active => Icons.autorenew,
                UsageBand.seek => Icons.travel_explore_outlined,
              },
              size: 18,
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10nUsageBandShort(l, b),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10nUsageBandSubtitle(l, b),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final out = <Widget>[];
    for (final band in UsageBand.values) {
      if (_bandFilter != null && band != _bandFilter) continue;
      final inBand = ordered.where((h) => h.band == band).toList();
      if (inBand.isEmpty) continue;
      out.add(bandHeader(band));
      for (final h in inBand) {
        out.add(_card(h));
      }
    }
    return out;
  }

  Widget _card(ObjectSearchHit h) {
    final title = h.title.isNotEmpty ? h.title : h.key;
    final preview = _plainPreview(h.bodyText, 220);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(
            ObjectSearchPick(
              parentKey: h.parentKey.isEmpty ? 'ROOT' : h.parentKey,
              focusKey: h.key,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _leading(h.key, h.bodyText),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      h.key,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.objectSearchCardReaderTooltip,
                icon: const Icon(Icons.chrome_reader_mode_outlined),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => NodeCardReaderPage(
                        db: widget.db,
                        entryKey: h.key,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ordered = _orderedHits();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.objectSearchTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _controller,
              hintText: l.objectSearchHint,
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                      _runSearch('');
                    },
                  ),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<UsageBand?>(
              multiSelectionEnabled: false,
              segments: [
                ButtonSegment<UsageBand?>(
                  value: null,
                  label: Text(l.usageBandAll),
                  icon: const Icon(Icons.view_agenda_outlined, size: 18),
                ),
                ButtonSegment<UsageBand?>(
                  value: UsageBand.core,
                  label: Text(l.usageBandCore),
                  icon: const Icon(Icons.bolt_outlined, size: 18),
                ),
                ButtonSegment<UsageBand?>(
                  value: UsageBand.active,
                  label: Text(l.usageBandActive),
                  icon: const Icon(Icons.autorenew, size: 18),
                ),
                ButtonSegment<UsageBand?>(
                  value: UsageBand.seek,
                  label: Text(l.usageBandSeek),
                  icon: const Icon(Icons.travel_explore_outlined, size: 18),
                ),
              ],
              selected: {_bandFilter},
              emptySelectionAllowed: true,
              onSelectionChanged: (s) {
                setState(() {
                  _bandFilter = s.isEmpty ? null : s.first;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              l.objectSearchUsageCaption,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          if (_ftsError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _ftsError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ensureLibrarySchema(widget.db);
                setState(() {
                  _bands = computeObjectUsageBands(widget.db);
                  _runSearch(_query);
                });
              },
              child: ordered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                        Center(
                          child: Text(
                            _query.trim().isEmpty
                                ? l.objectSearchNoObjects
                                : l.objectSearchNoMatches,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      children: _buildSections(ordered, l),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
