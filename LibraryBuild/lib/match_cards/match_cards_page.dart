import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'package:super_clipboard/super_clipboard.dart';

import '../alexandria_lb_theme.dart';
import '../library_build.dart';
import '../l10n/app_localizations.dart';
import 'match_cards_bundle_io.dart';
import 'match_cards_deck_overview.dart';
import 'match_cards_session_page.dart';
import 'match_cards_store.dart';

Future<Uint8List?> _readClipboardFile(DataReader reader, FileFormat format) async {
  final c = Completer<Uint8List?>();
  final progress = reader.getFile(
    format,
    (file) async {
      try {
        final all = await file.readAll();
        if (!c.isCompleted) c.complete(all);
      } catch (_) {
        if (!c.isCompleted) c.complete(null);
      }
    },
    onError: (_) {
      if (!c.isCompleted) c.complete(null);
    },
  );
  if (progress == null && !c.isCompleted) c.complete(null);
  return c.future;
}

String _extForClipboardImageFormat(FileFormat fmt) {
  if (fmt == Formats.png) return 'png';
  if (fmt == Formats.jpeg) return 'jpg';
  if (fmt == Formats.webp) return 'webp';
  if (fmt == Formats.gif) return 'gif';
  if (fmt == Formats.bmp) return 'bmp';
  if (fmt == Formats.tiff) return 'tiff';
  return 'png';
}

bool _isImagePathAllowed(String path) {
  final low = path.toLowerCase();
  for (final s in const [
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
    '.bmp',
    '.tif',
    '.tiff',
  ]) {
    if (low.endsWith(s)) return true;
  }
  return false;
}

/// Lista de pares imagen ↔ texto y acceso a sesión de emparejamiento (solo LB).
///
/// [embedded]: si es true, no usa [Scaffold] propio (cabecera + FAB van dentro del padre, p. ej. [LbHome]).
class MatchCardsPage extends StatefulWidget {
  const MatchCardsPage({
    super.key,
    required this.db,
    this.embedded = false,
  });

  final Database db;
  final bool embedded;

  @override
  State<MatchCardsPage> createState() => _MatchCardsPageState();
}

class _MatchCardsPageState extends State<MatchCardsPage> {
  List<LbMatchPairRow> _rows = [];
  List<LbMatchDeckRow> _decks = [];
  int? _selectedDeckId;
  LbMatchDeckOverview? _deckOverview;

  final TextEditingController _searchCtrl = TextEditingController();
  bool _dupesOnly = false;

  Map<String, int> _lemmaCountByNormalized() {
    final m = <String, int>{};
    for (final r in _rows) {
      final k = r.captionText.toLowerCase().trim();
      if (k.isEmpty) continue;
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  static bool _isLemmaDuplicate(LbMatchPairRow r, Map<String, int> counts) {
    final k = r.captionText.toLowerCase().trim();
    return k.isNotEmpty && (counts[k] ?? 0) > 1;
  }

  int _duplicateLemmaGroupCount(Map<String, int> counts) =>
      counts.entries.where((e) => e.value > 1).length;

  List<LbMatchPairRow> _buildFilteredRows(Map<String, int> lemmaCounts) {
    final q = _searchCtrl.text.trim().toLowerCase();
    bool matchesSearch(LbMatchPairRow r) {
      if (q.isEmpty) return true;
      if (r.captionText.toLowerCase().contains(q)) return true;
      final tr = r.transliteration?.toLowerCase() ?? '';
      if (tr.contains(q)) return true;
      final gl = r.gloss?.toLowerCase() ?? '';
      if (gl.contains(q)) return true;
      return false;
    }

    return _rows.where((r) {
      if (_dupesOnly && !_isLemmaDuplicate(r, lemmaCounts)) return false;
      return matchesSearch(r);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    ensureLibrarySchema(widget.db);
    _reload();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    super.dispose();
  }

  void _reload({int? selectDeckId}) {
    setState(() {
      if (selectDeckId != null) {
        _selectedDeckId = selectDeckId;
      }
      _decks = lbListDecks(widget.db);
      if (_decks.isEmpty) {
        _selectedDeckId = null;
        _rows = [];
        _deckOverview = null;
        return;
      }
      if (_selectedDeckId == null ||
          !_decks.any((d) => d.id == _selectedDeckId)) {
        _selectedDeckId = _decks.first.id;
      }
      _rows = lbListMatchPairs(
        widget.db,
        poolOnly: true,
        deckId: _selectedDeckId,
      );
      _deckOverview = _selectedDeckId == null
          ? null
          : lbLoadMatchDeckOverview(widget.db, deckId: _selectedDeckId!);
    });
  }

  bool _isPrimaryFocusInEditableText() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final meta = pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    final mod = ctrl || meta;
    if (event.logicalKey == LogicalKeyboardKey.keyV && mod) {
      if (_isPrimaryFocusInEditableText()) return false;
      _pasteImageFromClipboard();
      return true;
    }
    return false;
  }

  Future<void> _pasteImageFromClipboard() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    try {
      final reader = await clipboard.read();
      const formats = [
        Formats.png,
        Formats.jpeg,
        Formats.webp,
        Formats.gif,
        Formats.bmp,
        Formats.tiff,
      ];
      for (final fmt in formats) {
        if (!reader.canProvide(fmt)) continue;
        final bytes = await _readClipboardFile(reader, fmt);
        if (bytes != null && bytes.isNotEmpty) {
          if (!mounted) return;
          await _showAddPairDialog(
            initialBytes: bytes,
            initialExt: _extForClipboardImageFormat(fmt),
          );
          return;
        }
      }
    } catch (e, st) {
      debugPrint('[MatchCards] paste $e\n$st');
    }
  }

  Future<void> _ingestDroppedFile(String path) async {
    if (!_isImagePathAllowed(path)) return;
    final f = File(path);
    if (!f.existsSync()) return;
    try {
      final bytes = await f.readAsBytes();
      if (bytes.isEmpty) return;
      if (!mounted) return;
      var ext = path.toLowerCase();
      final dot = ext.lastIndexOf('.');
      ext = dot >= 0 && dot < ext.length - 1 ? ext.substring(dot + 1) : 'png';
      await _showAddPairDialog(initialBytes: bytes, initialExt: ext);
    } catch (e, st) {
      debugPrint('[MatchCards] drop $e\n$st');
    }
  }

  Future<void> _onDropDone(DropDoneDetails details) async {
    for (final item in details.files) {
      final path = item.path;
      if (path.isEmpty) continue;
      await _ingestDroppedFile(path);
      break;
    }
  }

  bool _useDesktopDrop() =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> _showAddPairDialog({
    Uint8List? initialBytes,
    String? initialExt,
  }) async {
    final deckId = _selectedDeckId;
    if (deckId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AddMatchPairDialog(
        db: widget.db,
        deckId: deckId,
        initialBytes: initialBytes,
        initialExt: initialExt ?? 'png',
      ),
    );
    if (ok == true) _reload();
  }

  Future<void> _addPair() => _showAddPairDialog();

  void _openSession() {
    final deckId = _selectedDeckId;
    if (deckId == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MatchCardsSessionPage(
          db: widget.db,
          deckId: deckId,
          decks: _decks,
        ),
      ),
    );
  }

  bool get _canOpenDeckStats =>
      _selectedDeckId != null && (_deckOverview?.pairCount ?? 0) > 0;

  Future<void> _openDeckStatsDialog() async {
    final deckId = _selectedDeckId;
    final l10n = AppLocalizations.of(context)!;
    if (deckId == null) return;
    final o =
        _deckOverview ?? lbLoadMatchDeckOverview(widget.db, deckId: deckId);
    if (!mounted) return;
    if (o.pairCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.matchCardsEmpty)),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(dl.matchCardsSessionStatsTitle),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: MatchCardsDeckOverviewCard(
                overview: o,
                compact: true,
                showTitleRow: false,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(dl.matchCardsCancel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptNewDeck() async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.matchCardsNewDeckTitle),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.matchCardsDeckNameLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dl.matchCardsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dl.matchCardsSavePair),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (name.isEmpty) return;
    try {
      final id = lbInsertDeck(widget.db, name);
      setState(() => _selectedDeckId = id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _promptRenameDeck() async {
    final deckId = _selectedDeckId;
    if (deckId == null) return;
    LbMatchDeckRow? row;
    for (final d in _decks) {
      if (d.id == deckId) {
        row = d;
        break;
      }
    }
    if (row == null) return;
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: row.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.matchCardsRenameDeckTitle),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.matchCardsDeckNameLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dl.matchCardsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dl.matchCardsSavePair),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (name.isEmpty) return;
    try {
      lbRenameDeck(widget.db, deckId, name);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _confirmDeleteDeck() async {
    final deckId = _selectedDeckId;
    if (deckId == null || _decks.length < 2) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.matchCardsDeleteDeckTitle),
        content: Text(l10n.matchCardsDeleteDeckBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.matchCardsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.matchCardsDeleteDeckConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      lbDeleteDeck(widget.db, deckId);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _exportDeck() async {
    final deckId = _selectedDeckId;
    if (deckId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: l10n.matchCardsExportTitle,
      fileName: 'match_cards_deck.zip',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (path == null || !mounted) return;
    var p = path;
    if (!p.toLowerCase().endsWith('.zip')) p = '$p.zip';
    try {
      await lbExportDeckToZipFile(
        db: widget.db,
        deckId: deckId,
        zipAbsolutePath: p,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.matchCardsExportDone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.matchCardsExportError('$e'))),
      );
    }
  }

  Future<void> _importDeck() async {
    final l10n = AppLocalizations.of(context)!;
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (pick == null || pick.files.isEmpty || !mounted) return;
    final fp = pick.files.single.path;
    if (fp == null || fp.isEmpty) return;
    String? suggestedName;
    try {
      suggestedName = await lbPeekMatchCardsBundleDeckName(fp);
    } catch (_) {}
    if (!mounted) return;
    final ctrl = TextEditingController(
      text: suggestedName ?? l10n.matchCardsImportDefaultDeckName,
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.matchCardsImportTitle),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.matchCardsImportNewDeckNameLabel,
              helperText: l10n.matchCardsImportNewDeckNameHelper,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dl.matchCardsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.matchCardsImportConfirm),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (name.isEmpty) return;
    try {
      final newId = lbInsertDeck(widget.db, name);
      final n = await lbImportDeckFromZipFile(
        db: widget.db,
        deckId: newId,
        zipAbsolutePath: fp,
      );
      if (!mounted) return;
      setState(() => _selectedDeckId = newId);
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.matchCardsImportDone(n))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.matchCardsImportError('$e'))),
      );
    }
  }

  Widget _deckOverflowMenu(AppLocalizations l10n) {
    return PopupMenuButton<String>(
      tooltip: l10n.matchCardsDeckMenuTooltip,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'new',
          child: Text(l10n.matchCardsNewDeckMenu),
        ),
        PopupMenuItem(
          value: 'rename',
          child: Text(l10n.matchCardsRenameDeckMenu),
        ),
        PopupMenuItem(
          value: 'delete',
          enabled: _decks.length > 1,
          child: Text(l10n.matchCardsDeleteDeckMenu),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'deckStats',
          enabled: _canOpenDeckStats,
          child: Text(l10n.matchCardsDeckStatsMenu),
        ),
        PopupMenuItem(
          value: 'export',
          child: Text(l10n.matchCardsExportMenu),
        ),
        PopupMenuItem(
          value: 'import',
          child: Text(l10n.matchCardsImportMenu),
        ),
      ],
      onSelected: (v) {
        switch (v) {
          case 'new':
            _promptNewDeck();
            break;
          case 'rename':
            _promptRenameDeck();
            break;
          case 'delete':
            _confirmDeleteDeck();
            break;
          case 'export':
            _exportDeck();
            break;
          case 'import':
            _importDeck();
            break;
          case 'deckStats':
            _openDeckStatsDialog();
            break;
        }
      },
    );
  }

  Widget _buildBodyContent(AppLocalizations l10n) {
    final lemmaCounts = _lemmaCountByNormalized();
    final filtered = _buildFilteredRows(lemmaCounts);
    final dupGroups = _duplicateLemmaGroupCount(lemmaCounts);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.embedded)
          Material(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  Icon(Icons.style_outlined, color: cs.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.matchCardsTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bar_chart_outlined),
                    tooltip: l10n.matchCardsDeckStatsMenu,
                    onPressed: _canOpenDeckStats ? _openDeckStatsDialog : null,
                  ),
                  _deckOverflowMenu(l10n),
                  if (_rows.length >= 2 && _selectedDeckId != null)
                    TextButton(
                      onPressed: _openSession,
                      child: Text(l10n.matchCardsPractice),
                    ),
                ],
              ),
            ),
          ),
        if (_decks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<int>(
              value: _selectedDeckId,
              decoration: InputDecoration(
                labelText: l10n.matchCardsDeckLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final d in _decks)
                  DropdownMenuItem<int>(value: d.id, child: Text(d.name)),
              ],
              onChanged: (v) {
                if (v == null) return;
                _reload(selectDeckId: v);
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l10n.matchCardsPasteDropHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.matchCardsOrmHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: _rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.matchCardsEmpty,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: l10n.matchCardsSearchHint,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: MaterialLocalizations.of(context)
                                          .deleteButtonTooltip,
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _searchCtrl.clear(),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilterChip(
                                label: Text(l10n.matchCardsDuplicatesOnly),
                                selected: _dupesOnly,
                                onSelected: (v) =>
                                    setState(() => _dupesOnly = v),
                              ),
                              if (dupGroups > 0)
                                Text(
                                  l10n.matchCardsDuplicateSummary(dupGroups),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  l10n.matchCardsSearchNoResults,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 0, 12, 88),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final r = filtered[i];
                                final img = r.imageAbsolutePath;
                                final file = File(img);
                                final isDup =
                                    _isLemmaDuplicate(r, lemmaCounts);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: file.existsSync()
                                            ? Image.file(
                                                file,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                      ),
                                    ),
                                    title: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isDup)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                              top: 2,
                                            ),
                                            child: Tooltip(
                                              message: l10n
                                                  .matchCardsDuplicateLemmaTooltip,
                                              child: Icon(
                                                Icons.copy_all_outlined,
                                                size: 20,
                                                color: cs.error,
                                              ),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            r.captionText,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (r.transliteration != null &&
                                            r.transliteration!.isNotEmpty)
                                          Text(
                                            r.transliteration!,
                                            style: theme
                                                .textTheme.labelMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (r.gloss != null &&
                                            r.gloss!.isNotEmpty)
                                          Text(
                                            r.gloss!,
                                            style:
                                                theme.textTheme.bodySmall,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        Text(
                                          r.imageBasename,
                                          style: theme.textTheme.labelSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: l10n.matchCardsDeleteTooltip,
                                      onPressed: () {
                                        lbDeleteMatchPair(widget.db, r.id);
                                        _reload();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final core = _buildBodyContent(l10n);
    final wrapped = _useDesktopDrop()
        ? DropTarget(
            onDragDone: _onDropDone,
            child: core,
          )
        : core;

    final fab = FloatingActionButton.extended(
      onPressed: _addPair,
      icon: const Icon(Icons.add),
      label: Text(l10n.matchCardsAddPair),
      backgroundColor: AlexandriaLbTheme.gold.withValues(alpha: 0.92),
      foregroundColor: AlexandriaLbTheme.stoneDeep,
    );

    if (widget.embedded) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: wrapped),
          Positioned(
            right: 16,
            bottom: 16,
            child: fab,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.matchCardsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: l10n.matchCardsDeckStatsMenu,
            onPressed: _canOpenDeckStats ? _openDeckStatsDialog : null,
          ),
          _deckOverflowMenu(l10n),
          if (_rows.length >= 2 && _selectedDeckId != null)
            TextButton(
              onPressed: _openSession,
              child: Text(l10n.matchCardsPractice),
            ),
        ],
      ),
      body: wrapped,
      floatingActionButton: fab,
    );
  }
}

class _AddMatchPairDialog extends StatefulWidget {
  const _AddMatchPairDialog({
    required this.db,
    required this.deckId,
    this.initialBytes,
    this.initialExt = 'png',
  });

  final Database db;
  final int deckId;
  final Uint8List? initialBytes;
  final String initialExt;

  @override
  State<_AddMatchPairDialog> createState() => _AddMatchPairDialogState();
}

class _AddMatchPairDialogState extends State<_AddMatchPairDialog> {
  late final TextEditingController _lemmaCtrl;
  late final TextEditingController _transCtrl;
  late final TextEditingController _glossCtrl;
  Uint8List? _bytes;
  String _ext = 'png';
  String? _pickedPath;

  @override
  void initState() {
    super.initState();
    _lemmaCtrl = TextEditingController();
    _transCtrl = TextEditingController();
    _glossCtrl = TextEditingController();
    _bytes = widget.initialBytes;
    _ext = widget.initialExt;
  }

  @override
  void dispose() {
    _lemmaCtrl.dispose();
    _transCtrl.dispose();
    _glossCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteImageInDialog() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    try {
      final reader = await clipboard.read();
      const formats = [
        Formats.png,
        Formats.jpeg,
        Formats.webp,
        Formats.gif,
        Formats.bmp,
        Formats.tiff,
      ];
      for (final fmt in formats) {
        if (!reader.canProvide(fmt)) continue;
        final bytes = await _readClipboardFile(reader, fmt);
        if (bytes != null && bytes.isNotEmpty) {
          setState(() {
            _bytes = bytes;
            _ext = _extForClipboardImageFormat(fmt);
            _pickedPath = null;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.matchCardsClipboardNoImage)),
      );
    }
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'png',
        'jpg',
        'jpeg',
        'webp',
        'gif',
      ],
    );
    if (r == null || r.files.isEmpty) return;
    final path = r.files.single.path;
    if (path == null || path.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _pickedPath = path;
      _bytes = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final lemma = _lemmaCtrl.text.trim();
    if (lemma.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.matchCardsLemmaRequired)),
      );
      return;
    }
    if (lbDeckContainsLemmaNormalized(
          widget.db,
          deckId: widget.deckId,
          lemma: lemma,
        )) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final dl = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(l10n.matchCardsDuplicateSaveTitle),
            content: Text(l10n.matchCardsDuplicateSaveBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(dl.matchCardsCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.matchCardsContinueAnyway),
              ),
            ],
          );
        },
      );
      if (go != true) return;
      if (!mounted) return;
    }
    final tr = _transCtrl.text.trim();
    final gl = _glossCtrl.text.trim();
    try {
      if (_pickedPath != null) {
        lbInsertMatchPairFromFile(
          widget.db,
          sourceFile: _pickedPath!,
          captionText: lemma,
          transliteration: tr.isEmpty ? null : tr,
          gloss: gl.isEmpty ? null : gl,
          deckId: widget.deckId,
        );
      } else if (_bytes != null) {
        lbInsertMatchPairFromBytes(
          widget.db,
          bytes: _bytes!,
          extensionNoDot: _ext,
          captionText: lemma,
          transliteration: tr.isEmpty ? null : tr,
          gloss: gl.isEmpty ? null : gl,
          deckId: widget.deckId,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.matchCardsImageRequired)),
        );
        return;
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImage = _pickedPath != null || (_bytes != null && _bytes!.isNotEmpty);
    return AlertDialog(
      title: Text(l10n.matchCardsAddDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _lemmaCtrl,
              decoration: InputDecoration(
                labelText: l10n.matchCardsLemmaLabel,
                hintText: l10n.matchCardsLemmaHint,
                helperText: l10n.matchCardsLemmaUnicodeHelper,
                border: const OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _transCtrl,
              decoration: InputDecoration(
                labelText: l10n.matchCardsTransliterationLabel,
                hintText: l10n.matchCardsTransliterationHint,
                border: const OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _glossCtrl,
              decoration: InputDecoration(
                labelText: l10n.matchCardsGlossLabel,
                hintText: l10n.matchCardsGlossHint,
                border: const OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            if (hasImage)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.matchCardsImageReady,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(l10n.matchCardsPickImage),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pasteImageInDialog,
              icon: const Icon(Icons.content_paste),
              label: Text(l10n.matchCardsPasteImageInDialog),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.matchCardsCancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.matchCardsSavePair),
        ),
      ],
    );
  }
}
