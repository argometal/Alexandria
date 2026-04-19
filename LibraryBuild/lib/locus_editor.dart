import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'package:super_clipboard/super_clipboard.dart';

import 'alexandria_lb_theme.dart';
import 'alexandria_paths.dart';
import 'l10n/app_localizations.dart';
import 'library_build.dart'
    show
        buildViewerForKey,
        deleteEntrySubtreeAndSync,
        ensureLibrarySchema,
        kCognitiveRoles,
        normalizeCognitiveRole,
        normalizeTextKind,
        readFocusKeyWithFallback,
        runLibraryBuild,
        writeViewerCurrentJson;

const _kCognitiveRoleLabels = <String, String>{
  'realm': 'Realm',
  'parcour': 'Parcour',
  'object': 'Object',
};

const _kTextKinds = <String, String>{
  'text': 'Text',
  'ridiculous_story': 'Ridiculous story',
  'hint': 'Hint',
  'place': 'Place',
};

const _heroExts = ['png', 'jpg', 'jpeg', 'webp'];

List<String> _parseRelatedKeysLine(String raw) {
  final out = <String>[];
  for (final part in raw.split(RegExp(r'[\s,;]+'))) {
    final s = part.trim();
    if (s.isNotEmpty) out.add(s);
  }
  return out;
}

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

/// Editor de contenido por locus (bloques `p`, `link`, `img`). Reemplaza el panel inferior de main.
class LocusEditorPage extends StatefulWidget {
  const LocusEditorPage({
    super.key,
    required this.db,
    required this.entryKey,
  });

  final Database db;
  final String entryKey;

  @override
  State<LocusEditorPage> createState() => _LocusEditorPageState();
}

class _LocusEditorPageState extends State<LocusEditorPage> {
  final List<_BlockDraft> _blocks = [];
  final ScrollController _blocksScrollController = ScrollController();
  final List<GlobalKey> _blockItemKeys = [];
  String _cognitiveRole = 'object';
  /// Si el padre en DB es parcour, el rol cognitivo queda fijado a `object`.
  bool _isParentParcour = false;
  /// GK: `left` | `right` | vacío (recto; el siguiente marco sigue la dirección relativa).
  String _spatialTurn = '';
  /// Bloque `img` seleccionado para Ctrl/Cmd+H (portada marco GK).
  int? _focusedImageBlockIndex;

  String _cognitiveRoleLabel(AppLocalizations l10n) {
    switch (_cognitiveRole) {
      case 'realm':
        return l10n.roleRealm;
      case 'parcour':
        return l10n.roleParcour;
      case 'object':
        return l10n.roleObject;
      default:
        return _cognitiveRole;
    }
  }

  String _spatialTurnLabel(AppLocalizations l10n) {
    switch (_spatialTurn) {
      case 'left':
        return l10n.locusEditorSpatialLeft;
      case 'right':
        return l10n.locusEditorSpatialRight;
      default:
        return l10n.locusEditorSpatialStraight;
    }
  }

  void _showLocusEditorHelpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.locusEditorHelpDialogTitle),
        content: SingleChildScrollView(
          child: Text(
            l10n.locusEditorHelpDialogBody,
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.helpGuideClose),
          ),
        ],
      ),
    );
  }

  bool get _canDeleteLocus =>
      widget.entryKey != 'ROOT' && widget.entryKey != 'PARCOUR_MAIN';

  Future<void> _confirmDeleteLocus(BuildContext outerContext) async {
    if (!_canDeleteLocus) return;
    final l10n = AppLocalizations.of(outerContext)!;
    final phraseExact = l10n.locusEditorDeleteConfirmPhraseExact;
    final ctrl = TextEditingController();
    var listenerAttached = false;
    final ok = await showDialog<bool>(
      context: outerContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!listenerAttached) {
              listenerAttached = true;
              ctrl.addListener(() => setDialogState(() {}));
            }
            final canDelete = ctrl.text.trim() == phraseExact;
            return AlertDialog(
              title: Text(l10n.locusEditorDeleteConfirmTitle),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.locusEditorDeleteConfirmDescription(
                        AlexandriaPaths.realmDataRoot(),
                      ),
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      l10n.locusEditorDeleteConfirmDeletingLabel(widget.entryKey),
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.locusEditorDeleteConfirmTypeInstruction,
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        phraseExact,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.locusEditorDeleteConfirmFieldHint,
                        border: const OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                  ),
                  onPressed: canDelete ? () => Navigator.pop(ctx, true) : null,
                  child: Text(l10n.locusEditorDeleteConfirmButton),
                ),
              ],
            );
          },
        );
      },
    );
    ctrl.dispose();
    if (ok != true || !mounted) return;
    try {
      deleteEntrySubtreeAndSync(widget.db, widget.entryKey);
      if (!mounted) return;
      Navigator.of(outerContext).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(outerContext).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _showLocusMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final l10nSheet = AppLocalizations.of(ctx)!;
        final bottomPad = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Locus',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.entryKey,
                      style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setModal) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isParentParcour)
                              InputDecorator(
                                decoration: const InputDecoration(
                                  labelText:
                                      'Cognitive role (LB only; GK does not read this)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                child: Text(
                                  'Object (fijo bajo parcour)',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                            else
                              InputDecorator(
                                decoration: const InputDecoration(
                                  labelText:
                                      'Cognitive role (LB only; GK does not read this)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    isDense: true,
                                    value: _cognitiveRole,
                                    items: [
                                      for (final r in kCognitiveRoles)
                                        DropdownMenuItem<String>(
                                          value: r,
                                          child: Text(
                                              _kCognitiveRoleLabels[r] ?? r),
                                        ),
                                    ],
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _cognitiveRole = v);
                                      setModal(() {});
                                    },
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.help_outline,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                      title: Text(l10nSheet.locusEditorHelpMenuLabel),
                      subtitle: Text(
                        l10nSheet.locusEditorHelpMenuSubtitle,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showLocusEditorHelpDialog(context);
                      },
                    ),
                    if (_canDeleteLocus) ...[
                      const SizedBox(height: 4),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_forever_outlined,
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                        title: Text(
                          l10nSheet.locusEditorDeleteMenuLabel,
                          style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                        ),
                        subtitle: Text(
                          l10nSheet.locusEditorDeleteMenuSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _confirmDeleteLocus(context);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    _loadFromDb();
  }

  @override
  void dispose() {
    _blocksScrollController.dispose();
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  void _ensureBlockItemKeys() {
    while (_blockItemKeys.length < _blocks.length) {
      _blockItemKeys.add(GlobalKey());
    }
    while (_blockItemKeys.length > _blocks.length) {
      _blockItemKeys.removeLast();
    }
  }

  void _scrollToBlock(int index) {
    if (index < 0 || index >= _blockItemKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _blockItemKeys[index].currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  Color _blockRailColor(_BlockDraft b) {
    if (b.isLink) {
      return AlexandriaLbTheme.blockRailLink;
    }
    if (b.isCard) {
      return AlexandriaLbTheme.blockRailCard;
    }
    if (b.isImage) {
      if (b.imgRole == 'hero') {
        return AlexandriaLbTheme.blockRailHero;
      }
      if (b.imgRole == 'collage') {
        return AlexandriaLbTheme.blockRailCollage;
      }
      if (b.imgRole == 'recall_crop') {
        return const Color(0xFFE65100);
      }
      return AlexandriaLbTheme.blockRailImage;
    }
    switch (b.textKind) {
      case 'place':
        return AlexandriaLbTheme.blockRailPlace;
      case 'hint':
        return AlexandriaLbTheme.blockRailHint;
      case 'ridiculous_story':
        return AlexandriaLbTheme.blockRailRidiculous;
      default:
        return AlexandriaLbTheme.blockRailTextDefault;
    }
  }

  String _blockRailTooltip(
    _BlockDraft b,
    int i,
    Map<int, int> collageSeqByIndex,
  ) {
    if (b.isLink) {
      return 'Link #${i + 1}';
    }
    if (b.isCard) {
      return 'Card · bloque ${i + 1}';
    }
    if (b.isImage) {
      if (b.imgRole == 'hero') {
        return 'HERO · bloque ${i + 1}';
      }
      if (b.imgRole == 'collage') {
        return 'Collage #${collageSeqByIndex[i] ?? 0} · bloque ${i + 1}';
      }
      if (b.imgRole == 'recall_crop') {
        return 'RECALL · bloque ${i + 1}';
      }
      return 'Imagen contenido · bloque ${i + 1}';
    }
    final kind = _kTextKinds[b.textKind] ?? 'Text';
    return '$kind · bloque ${i + 1}';
  }

  Widget _buildBlockOverviewRail(
    BuildContext context,
    Map<int, int> collageSeqByIndex,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message:
          'Mapa de bloques: colores por tipo. Pulsa una franja para ir al bloque.',
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 28,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Icon(
                  Icons.view_agenda_outlined,
                  size: 14,
                  color: cs.primary,
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_blocks.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: List.generate(_blocks.length, (i) {
                        final b = _blocks[i];
                        final imgFocused =
                            b.isImage && _focusedImageBlockIndex == i;
                        final col = _blockRailColor(b);
                        return Expanded(
                          child: Tooltip(
                            message: _blockRailTooltip(
                              b,
                              i,
                              collageSeqByIndex,
                            ),
                            waitDuration: const Duration(milliseconds: 400),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 1,
                              ),
                              child: Material(
                                color: col,
                                borderRadius: BorderRadius.circular(4),
                                elevation: imgFocused ? 2 : 0,
                                child: InkWell(
                                  onTap: () => _scrollToBlock(i),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: imgFocused
                                          ? Border.all(
                                              color: AlexandriaLbTheme.gold,
                                              width: 2,
                                            )
                                          : Border.all(
                                              color: Colors.black26,
                                              width: 0.5,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Directory _assetsDir() =>
      Directory(
          '${AlexandriaPaths.assetsRoot}${Platform.pathSeparator}${widget.entryKey}');

  void _deleteHeroAssetFiles() {
    final dir = _assetsDir();
    if (!dir.existsSync()) return;
    for (final ext in _heroExts) {
      final p = File('${dir.path}${Platform.pathSeparator}hero.$ext');
      if (p.existsSync()) p.deleteSync();
    }
  }

  /// Borra en `assets/<entryKey>/` los archivos que ya no aparecen en los bloques guardados (p. ej. `paste_*` viejos).
  /// Alinea `hero.*` en disco con el bloque marcado hero (mismo criterio que GK). Sin bloque hero, borra `hero.*`.
  void _syncHeroFileFromBlocks() {
    _BlockDraft? heroBlock;
    for (final b in _blocks) {
      if (b.isImage && b.imgRole == 'hero') {
        heroBlock = b;
        break;
      }
    }
    _deleteHeroAssetFiles();
    if (heroBlock == null) return;
    final srcName = heroBlock.srcCtrl!.text.trim();
    if (srcName.isEmpty) return;
    final dir = _assetsDir();
    dir.createSync(recursive: true);
    final srcPath = '${dir.path}${Platform.pathSeparator}$srcName';
    final srcFile = File(srcPath);
    if (!srcFile.existsSync()) return;
    final lower = srcName.toLowerCase();
    var ext = 'png';
    for (final e in _heroExts) {
      if (lower.endsWith('.$e')) {
        ext = e;
        break;
      }
    }
    final destPath = '${dir.path}${Platform.pathSeparator}hero.$ext';
    srcFile.copySync(destPath);
  }

  void _purgeOrphanAssetFiles(Set<String> keepBasenames) {
    final dir = _assetsDir();
    if (!dir.existsSync()) return;
    for (final e in dir.listSync(followLinks: false)) {
      if (e is! File) continue;
      final name = e.path.split(Platform.pathSeparator).last;
      if (keepBasenames.contains(name)) continue;
      try {
        e.deleteSync();
      } catch (err, st) {
        debugPrint('[LocusEditor] orphan asset delete failed: $name — $err\n$st');
      }
    }
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
      _pasteFromClipboard();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyH && mod) {
      _heroShortcut();
      return true;
    }
    return false;
  }

  Future<void> _pasteFromClipboard() async {
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
          await _writePastedBytes(bytes, _extForClipboardImageFormat(fmt));
          return;
        }
      }
      final text = await reader.readValue<String>(Formats.plainText);
      final t = text?.trim() ?? '';
      if (t.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _blocks.add(_BlockDraft.p(text: t));
      });
    } catch (_) {}
  }

  Future<void> _writePastedBytes(Uint8List bytes, String ext) async {
    final dir = _assetsDir();
    dir.createSync(recursive: true);
    final name = 'paste_${DateTime.now().microsecondsSinceEpoch}.$ext';
    final f = File('${dir.path}${Platform.pathSeparator}$name');
    await f.writeAsBytes(bytes);
    if (!mounted) return;
    setState(() {
      _blocks.add(_BlockDraft.img(src: name));
    });
  }

  void _heroShortcut() {
    final i = _focusedImageBlockIndex;
    if (i == null || i < 0 || i >= _blocks.length) return;
    if (!_blocks[i].isImage) return;
    _promoteBlockToHero(i);
  }

  Future<void> _promoteBlockToHero(int i) async {
    final b = _blocks[i];
    if (!b.isImage) return;
    if (b.imgRole == 'recall_crop') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recall crop: use the role dropdown to switch to Hero — not ⌘H.',
          ),
        ),
      );
      return;
    }
    final srcName = b.srcCtrl!.text.trim();
    if (srcName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set an asset filename for this image block')),
      );
      return;
    }
    final dir = _assetsDir();
    dir.createSync(recursive: true);
    final srcPath = '${dir.path}${Platform.pathSeparator}$srcName';
    final srcFile = File(srcPath);
    if (!srcFile.existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File not found: $srcPath')),
      );
      return;
    }
    _deleteHeroAssetFiles();
    final lower = srcName.toLowerCase();
    var ext = 'png';
    for (final e in _heroExts) {
      if (lower.endsWith('.$e')) {
        ext = e;
        break;
      }
    }
    final destPath = '${dir.path}${Platform.pathSeparator}hero.$ext';
    await srcFile.copy(destPath);
    if (!mounted) return;
    setState(() {
      for (var j = 0; j < _blocks.length; j++) {
        if (!_blocks[j].isImage) continue;
        if (j == i) {
          _blocks[j].imgRole = 'hero';
        } else if (_blocks[j].imgRole == 'hero') {
          _blocks[j].imgRole = 'content';
        }
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hero image updated for GK frame')),
    );
  }

  Future<void> _ingestFileFromDisk(String path, {String? suggestedName}) async {
    final srcFile = File(path);
    if (!srcFile.existsSync()) return;
    var baseName = (suggestedName ?? '').trim();
    if (baseName.isEmpty) {
      baseName = srcFile.uri.pathSegments.isNotEmpty
          ? srcFile.uri.pathSegments.last
          : 'image.png';
    }
    final dir = _assetsDir();
    dir.createSync(recursive: true);
    var destPath = '${dir.path}${Platform.pathSeparator}$baseName';
    if (File(destPath).existsSync()) {
      final dot = baseName.lastIndexOf('.');
      final stem = dot > 0 ? baseName.substring(0, dot) : baseName;
      final ext = dot > 0 && dot < baseName.length - 1
          ? baseName.substring(dot + 1)
          : 'png';
      baseName = '${stem}_${DateTime.now().microsecondsSinceEpoch}.$ext';
      destPath = '${dir.path}${Platform.pathSeparator}$baseName';
    }
    await srcFile.copy(destPath);
    if (!mounted) return;
    setState(() {
      _blocks.add(_BlockDraft.img(src: baseName));
    });
  }

  bool _useDesktopDrop() =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> _onDropDone(DropDoneDetails details) async {
    for (final item in details.files) {
      final path = item.path;
      if (path.isEmpty) continue;
      final low = path.toLowerCase();
      const ok = <String>['.png', '.jpg', '.jpeg', '.webp'];
      var allowed = false;
      for (final s in ok) {
        if (low.endsWith(s)) {
          allowed = true;
          break;
        }
      }
      if (!allowed) continue;
      await _ingestFileFromDisk(path, suggestedName: item.name);
    }
  }

  void _loadFromDb() {
    final rows = widget.db.select(
      'SELECT body_text, cognitiveRole, spatial_turn, parentKey FROM entries WHERE key = ? LIMIT 1',
      [widget.entryKey],
    );
    final raw = rows.isEmpty ? null : rows.first['body_text'] as String?;
    final roleRaw = rows.isEmpty ? null : rows.first['cognitiveRole'];
    final parentKey = rows.isEmpty
        ? null
        : rows.first['parentKey']?.toString().trim();

    var isParcourParent = false;
    if (parentKey != null && parentKey.isNotEmpty) {
      final parentRows = widget.db.select(
        'SELECT cognitiveRole FROM entries WHERE key = ? LIMIT 1',
        [parentKey],
      );
      if (parentRows.isNotEmpty) {
        isParcourParent = normalizeCognitiveRole(
                parentRows.first['cognitiveRole']) ==
            'parcour';
      }
    }

    final stRaw = rows.isEmpty
        ? ''
        : rows.first['spatial_turn']?.toString().trim().toLowerCase() ?? '';
    var loadedRole = normalizeCognitiveRole(roleRaw);
    if (isParcourParent) {
      loadedRole = 'object';
    }

    final loaded = _decodeBodyText(raw);
    setState(() {
      _isParentParcour = isParcourParent;
      _cognitiveRole = loadedRole;
      _spatialTurn =
          (stRaw == 'left' || stRaw == 'right') ? stRaw : '';
      for (final b in _blocks) {
        b.dispose();
      }
      _blocks.clear();
      _blocks.addAll(loaded);
    });
  }

  /// Legacy-compatible: null, plain text, or JSON block arrays.
  List<_BlockDraft> _decodeBodyText(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [_BlockDraft.p(text: raw.trim())];
      }
      if (decoded.isEmpty) {
        return [];
      }
      final out = <_BlockDraft>[];
      for (final el in decoded) {
        if (el is! Map) continue;
        final m = Map<String, dynamic>.from(
          el.map((k, v) => MapEntry(k.toString(), v)),
        );
        final t = (m['t'] ?? m['type'] ?? 'p').toString().toLowerCase().trim();
        if (t == 'link') {
          out.add(
            _BlockDraft.link(
              destKey: (m['key'] ?? '').toString(),
              text: (m['text'] ?? '').toString(),
            ),
          );
          continue;
        }
        if (t == 'img') {
          final src = (m['src'] ?? m['assetKey'] ?? '').toString();
          var role =
              (m['role'] ?? m['imgRole'] ?? 'content').toString().toLowerCase().trim();
          if (role == 'img') role = 'content';
          if (role != 'hero' &&
              role != 'collage' &&
              role != 'content' &&
              role != 'recall_crop') {
            role = 'content';
          }
          int? collageOrder;
          if (role == 'collage') {
            final o = m['collageOrder'];
            if (o is int) collageOrder = o;
            if (o is num) collageOrder = o.toInt();
          }
          out.add(_BlockDraft.img(src: src, role: role, collageOrder: collageOrder));
          continue;
        }
        if (t == 'card') {
          final word = (m['word'] ?? '').toString();
          final image = (m['image'] ?? m['src'] ?? '').toString();
          final phonetic = (m['phonetic'] ?? '').toString();
          final audio = (m['audio'] ?? '').toString();
          final relRaw = m['related_to'];
          var relStr = '';
          if (relRaw is List) {
            relStr = relRaw
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .join(', ');
          }
          out.add(
            _BlockDraft.card(
              word: word,
              image: image,
              phonetic: phonetic,
              audio: audio,
              related: relStr,
            ),
          );
          continue;
        }
        var textKind = (m['textKind'] ?? '').toString().toLowerCase().trim();
        if (textKind.isEmpty) {
          if (t == 'hint') textKind = 'hint';
          if (t == 'place') textKind = 'place';
          if (t == 'ridiculous_story' || t == 'story') textKind = 'ridiculous_story';
        }
        if (!_kTextKinds.containsKey(textKind)) textKind = 'text';
        final plain = (m['text'] ?? '').toString().trim();
        final imgLegacy = RegExp(r'^\[img:\s*(.+?)\]\s*$').firstMatch(plain);
        if (imgLegacy != null) {
          out.add(_BlockDraft.img(src: imgLegacy.group(1)!.trim()));
        } else {
          out.add(_BlockDraft.p(text: plain, textKind: textKind));
        }
      }
      if (out.isEmpty) {
        return [_BlockDraft.p(text: raw.trim(), textKind: 'text')];
      }
      var heroSeen = false;
      for (final b in out) {
        if (b.isImage && b.imgRole == 'hero') {
          if (heroSeen) {
            b.imgRole = 'content';
          }
          heroSeen = true;
        }
      }
      var recallSeen = false;
      for (final b in out) {
        if (b.isImage && b.imgRole == 'recall_crop') {
          if (recallSeen) {
            b.imgRole = 'content';
          }
          recallSeen = true;
        }
      }
      return out;
    } catch (_) {
      return [_BlockDraft.p(text: raw.trim(), textKind: 'text')];
    }
  }

  void _addParagraph() {
    setState(() {
      _blocks.add(_BlockDraft.p());
    });
  }

  void _addLink() {
    setState(() {
      _blocks.add(_BlockDraft.link());
    });
  }

  void _addCard() {
    setState(() {
      _blocks.add(_BlockDraft.card());
    });
  }

  Future<void> _addImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final path = picked.path;
    if (path == null || path.isEmpty) return;
    var baseName = picked.name.trim();
    if (baseName.isEmpty) {
      final srcFile = File(path);
      baseName = srcFile.uri.pathSegments.isNotEmpty
          ? srcFile.uri.pathSegments.last
          : 'image.webp';
    }
    await _ingestFileFromDisk(path, suggestedName: baseName);
  }

  void _removeAt(int i) {
    final b = _blocks[i];
    if (b.isImage && b.imgRole == 'hero') {
      _deleteHeroAssetFiles();
    }
    setState(() {
      _blocks.removeAt(i);
      b.dispose();
      if (_focusedImageBlockIndex != null) {
        if (_focusedImageBlockIndex == i) {
          _focusedImageBlockIndex = null;
        } else if (_focusedImageBlockIndex! > i) {
          _focusedImageBlockIndex = _focusedImageBlockIndex! - 1;
        }
      }
    });
  }

  void _moveUp(int i) {
    if (i <= 0) return;
    setState(() {
      final b = _blocks.removeAt(i);
      _blocks.insert(i - 1, b);
      if (_focusedImageBlockIndex == i) {
        _focusedImageBlockIndex = i - 1;
      } else if (_focusedImageBlockIndex == i - 1) {
        _focusedImageBlockIndex = i;
      }
    });
  }

  void _moveDown(int i) {
    if (i >= _blocks.length - 1) return;
    setState(() {
      final b = _blocks.removeAt(i);
      _blocks.insert(i + 1, b);
      if (_focusedImageBlockIndex == i) {
        _focusedImageBlockIndex = i + 1;
      } else if (_focusedImageBlockIndex == i + 1) {
        _focusedImageBlockIndex = i;
      }
    });
  }

  int _nextCollageOrder() {
    var maxOrder = 0;
    for (final b in _blocks) {
      if (!b.isImage || b.imgRole != 'collage') continue;
      final o = b.collageOrder ?? 0;
      if (o > maxOrder) maxOrder = o;
    }
    return maxOrder + 1;
  }

  Future<void> _save() async {
    _syncHeroFileFromBlocks();

    final l10nValidate = AppLocalizations.of(context)!;
    for (final b in _blocks) {
      if (!b.isCard) continue;
      for (final k in _parseRelatedKeysLine(b.relatedCtrl!.text)) {
        final ok = widget.db.select(
          'SELECT 1 FROM entries WHERE key = ? LIMIT 1',
          [k],
        );
        if (ok.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10nValidate.locusEditorUnknownRelatedKey(k))),
          );
          return;
        }
      }
    }

    final payload = <Map<String, dynamic>>[];
    final keepAssetNames = <String>{};
    final collagesOrdered = _blocks
        .where((b) => b.isImage && b.imgRole == 'collage')
        .toList()
      ..sort((a, b) => (a.collageOrder ?? 99999).compareTo(b.collageOrder ?? 99999));
    var nextAutoOrder = 1;
    for (final c in collagesOrdered) {
      if ((c.collageOrder ?? 0) < nextAutoOrder) c.collageOrder = nextAutoOrder;
      nextAutoOrder = c.collageOrder! + 1;
    }

    for (final b in _blocks) {
      if (b.isLink) {
        final k = b.linkKeyCtrl!.text.trim();
        final t = b.textCtrl!.text.trim();
        if (k.isEmpty) continue;
        payload.add({'type': 'link', 'key': k, 'text': t});
      } else if (b.isCard) {
        final w = b.wordCtrl!.text.trim();
        final img = b.srcCtrl!.text.trim();
        if (w.isEmpty && img.isEmpty) continue;
        final phon = b.phoneticCtrl!.text.trim();
        final aud = b.audioCtrl!.text.trim();
        final rel = _parseRelatedKeysLine(b.relatedCtrl!.text);
        final row = <String, dynamic>{
          'type': 'card',
          'word': w,
        };
        if (img.isNotEmpty) row['image'] = img;
        if (phon.isNotEmpty) row['phonetic'] = phon;
        if (aud.isNotEmpty) row['audio'] = aud;
        if (rel.isNotEmpty) row['related_to'] = rel;
        payload.add(row);
        if (img.isNotEmpty) keepAssetNames.add(img);
        if (phon.isNotEmpty) keepAssetNames.add(phon);
        if (aud.isNotEmpty) keepAssetNames.add(aud);
      } else if (b.isImage) {
        final s = b.srcCtrl!.text.trim();
        if (s.isEmpty) continue;
        keepAssetNames.add(s);
        if (b.imgRole == 'hero') {
          for (final ext in _heroExts) {
            keepAssetNames.add('hero.$ext');
          }
        }
        final row = <String, dynamic>{'type': 'img', 'src': s};
        if (b.imgRole == 'hero') {
          row['role'] = 'hero';
        } else if (b.imgRole == 'collage') {
          row['role'] = 'collage';
          row['collageOrder'] = b.collageOrder ?? nextAutoOrder++;
        } else if (b.imgRole == 'recall_crop') {
          row['role'] = 'recall_crop';
        } else {
          row['role'] = 'content';
        }
        payload.add(row);
      } else {
        final t = b.textCtrl!.text.trim();
        if (t.isEmpty) continue;
        payload.add({
          'type': 'p',
          'text': t,
          'textKind': normalizeTextKind(b.textKind),
        });
      }
    }

    final String? stored =
        payload.isEmpty ? null : jsonEncode(payload);

    final stDb = _spatialTurn.isEmpty ? null : _spatialTurn;
    final roleToSave = _isParentParcour ? 'object' : _cognitiveRole;
    const praSave = 0;
    widget.db.execute(
      'UPDATE entries SET body_text = ?, cognitiveRole = ?, spatial_turn = ?, place_recall_active = ? WHERE key = ?',
      [stored, roleToSave, stDb, praSave, widget.entryKey],
    );
    _purgeOrphanAssetFiles(keepAssetNames);

    try {
      ensureLibrarySchema(widget.db);
      final focus = readFocusKeyWithFallback();
      if (focus == widget.entryKey) {
        writeViewerCurrentJson(widget.db, widget.entryKey);
      }
      buildViewerForKey(widget.entryKey);
      runLibraryBuild();
    } catch (_) {}

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.locusEditorSaved)),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final collageSeqByIndex = <int, int>{};
    var collageSeq = 1;
    for (var j = 0; j < _blocks.length; j++) {
      final b = _blocks[j];
      if (b.isImage && b.imgRole == 'collage') {
        collageSeqByIndex[j] = collageSeq;
        collageSeq++;
      }
    }
    _ensureBlockItemKeys();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.locusEditorTitle),
            Text(
              widget.entryKey,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              l10n.locusEditorSubtitleLine(
                _cognitiveRoleLabel(l10n),
                _spatialTurnLabel(l10n),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          Tooltip(
            message: l10n.locusEditorSpatialTurnTooltip,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: (value) {
                setState(() {
                  _spatialTurn = value == 'straight' ? '' : value;
                });
              },
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  value: 'straight',
                  child: Text(l10n.locusEditorSpatialStraight),
                ),
                PopupMenuItem<String>(
                  value: 'left',
                  child: Text(l10n.locusEditorSpatialLeft),
                ),
                PopupMenuItem<String>(
                  value: 'right',
                  child: Text(l10n.locusEditorSpatialRight),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.alt_route, size: 18, color: cs.primary),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 88),
                          child: Text(
                            _spatialTurnLabel(l10n),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.locusEditorAddBlockTooltip,
            onSelected: (value) {
              switch (value) {
                case 'p':
                  _addParagraph();
                  break;
                case 'l':
                  _addLink();
                  break;
                case 'i':
                  _addImage();
                  break;
                case 'c':
                  _addCard();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'p',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.text_fields, size: 20),
                  title: Text(l10n.locusEditorBlockParagraph),
                ),
              ),
              PopupMenuItem<String>(
                value: 'l',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link, size: 20),
                  title: Text(l10n.locusEditorBlockLink),
                ),
              ),
              PopupMenuItem<String>(
                value: 'i',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image_outlined, size: 20),
                  title: Text(l10n.locusEditorBlockImage),
                ),
              ),
              PopupMenuItem<String>(
                value: 'c',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.style_outlined, size: 20),
                  title: Text(l10n.locusEditorBlockCard),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 20, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.locusEditorAddBlockTooltip,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: l10n.locusEditorMenuTooltip,
            onPressed: () => _showLocusMenu(context),
          ),
          TextButton(
            onPressed: _save,
            child: Text(l10n.locusEditorSave),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                Widget core = _blocks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.locusEditorEmptyBlocksHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _blocksScrollController,
                              padding: const EdgeInsets.fromLTRB(12, 0, 4, 16),
                              itemCount: _blocks.length,
                              itemBuilder: (context, i) {
                          final b = _blocks[i];
                          final last = i == _blocks.length - 1;
                          final imgFocused =
                              b.isImage && _focusedImageBlockIndex == i;
                          final tagLabel = b.isLink
                              ? 'link'
                              : b.isCard
                                  ? l10n.locusEditorBlockCard.toUpperCase()
                                  : b.isImage
                                      ? (b.imgRole == 'hero'
                                          ? 'HERO'
                                          : b.imgRole == 'collage'
                                              ? 'COLLAGE #${collageSeqByIndex[i] ?? 0}'
                                              : b.imgRole == 'recall_crop'
                                                  ? 'RECALL'
                                                  : 'CONTENT')
                                      : (_kTextKinds[b.textKind] ?? 'Text')
                                          .toUpperCase();
                          return Card(
                            key: _blockItemKeys[i],
                            margin: const EdgeInsets.only(bottom: 12),
                            color: imgFocused
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.35)
                                : null,
                            shape: b.isImage
                                ? RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: b.imgRole == 'hero'
                                          ? AlexandriaLbTheme.blockRailHero
                                          : b.imgRole == 'collage'
                                              ? AlexandriaLbTheme.blockRailCollage
                                              : b.imgRole == 'recall_crop'
                                                  ? const Color(0xFFE65100)
                                                  : const Color(0xFF6B6258),
                                      width: 2,
                                    ),
                                  )
                                : b.isCard
                                    ? RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: AlexandriaLbTheme.blockRailCard,
                                          width: 2,
                                        ),
                                      )
                                    : null,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: b.isImage
                                  ? () => setState(
                                        () => _focusedImageBlockIndex = i,
                                      )
                                  : () => setState(
                                        () => _focusedImageBlockIndex = null,
                                      ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Chip(
                                          label: Text(
                                            tagLabel,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          backgroundColor: b.isImage
                                              ? (b.imgRole == 'hero'
                                                  ? AlexandriaLbTheme.chipHeroBg
                                                  : b.imgRole == 'collage'
                                                      ? AlexandriaLbTheme
                                                          .chipCollageBg
                                                      : b.imgRole == 'recall_crop'
                                                          ? const Color(
                                                              0xFFFFE0B2)
                                                      : AlexandriaLbTheme
                                                          .chipImageBg)
                                              : b.isCard
                                                  ? AlexandriaLbTheme.chipImageBg
                                                  : null,
                                        ),
                                        if (imgFocused &&
                                            b.imgRole != 'recall_crop') ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '⌘H',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                        if (!b.isImage &&
                                            !b.isLink &&
                                            !b.isCard) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              initialValue: b.textKind,
                                              isDense: true,
                                              decoration: const InputDecoration(
                                                labelText: 'Tipo texto',
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                border: OutlineInputBorder(),
                                              ),
                                              items: [
                                                for (final e
                                                    in _kTextKinds.entries)
                                                  DropdownMenuItem<String>(
                                                    value: e.key,
                                                    child: Text(
                                                      e.value,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                              onChanged: (v) {
                                                if (v == null) return;
                                                setState(() => b.textKind = v);
                                              },
                                            ),
                                          ),
                                        ],
                                        if (b.isImage) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child:
                                                DropdownButtonFormField<String>(
                                              key: ValueKey<String>(
                                                '${widget.entryKey}_$i'
                                                '_role_${b.imgRole}_co_${b.collageOrder}',
                                              ),
                                              initialValue: b.imgRole,
                                              isDense: true,
                                              decoration: const InputDecoration(
                                                labelText: 'Rol (GK)',
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                border: OutlineInputBorder(),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'content',
                                                  child: Text(
                                                    'Viewer',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'collage',
                                                  child: Text(
                                                    'Collage muro',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'hero',
                                                  child: Text(
                                                    'Hero marco',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'recall_crop',
                                                  child: Text(
                                                    'Recall crop (quiz)',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (v) {
                                                if (v == null) return;
                                                setState(() {
                                                  if (v == 'hero') {
                                                    for (final other
                                                        in _blocks) {
                                                      if (other.isImage &&
                                                          other.imgRole ==
                                                              'hero') {
                                                        other.imgRole =
                                                            'content';
                                                      }
                                                    }
                                                    b.collageOrder = null;
                                                  } else if (v == 'collage') {
                                                    b.collageOrder ??=
                                                        _nextCollageOrder();
                                                  } else if (v ==
                                                      'recall_crop') {
                                                    for (final other
                                                        in _blocks) {
                                                      if (other.isImage &&
                                                          other.imgRole ==
                                                              'recall_crop') {
                                                        other.imgRole =
                                                            'content';
                                                      }
                                                    }
                                                    b.collageOrder = null;
                                                  } else {
                                                    b.collageOrder = null;
                                                  }
                                                  b.imgRole = v;
                                                });
                                              },
                                            ),
                                          ),
                                          if (b.imgRole == 'collage') ...[
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              width: 64,
                                              child: TextFormField(
                                                initialValue: (b.collageOrder ??
                                                        1)
                                                    .toString(),
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                  signed: false,
                                                  decimal: false,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                                decoration: const InputDecoration(
                                                  labelText: '#',
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 6,
                                                  ),
                                                  border: OutlineInputBorder(),
                                                ),
                                                onChanged: (v) {
                                                  final n =
                                                      int.tryParse(v.trim());
                                                  if (n == null || n <= 0) {
                                                    return;
                                                  }
                                                  b.collageOrder = n;
                                                },
                                              ),
                                            ),
                                          ],
                                        ],
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.arrow_upward,
                                              size: 20),
                                          tooltip: 'Move up',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: i == 0
                                              ? null
                                              : () => _moveUp(i),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_downward,
                                            size: 20,
                                          ),
                                          tooltip: 'Move down',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: last
                                              ? null
                                              : () => _moveDown(i),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                          ),
                                          tooltip: 'Delete',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _removeAt(i),
                                        ),
                                      ],
                                    ),
                                    if (b.isLink) ...[
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: b.linkKeyCtrl!,
                                        decoration: const InputDecoration(
                                          labelText: 'Target KEY',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ],
                                    if (b.isCard) ...[
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: b.wordCtrl!,
                                        decoration: InputDecoration(
                                          labelText: l10n.locusEditorCardWordLabel,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: b.srcCtrl!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                        ),
                                        decoration: InputDecoration(
                                          labelText: l10n.locusEditorCardImageLabel,
                                          hintText: 'illustration.png',
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _ImagePreviewTile(
                                        entryKey: widget.entryKey,
                                        srcController: b.srcCtrl!,
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: b.phoneticCtrl!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                        ),
                                        decoration: InputDecoration(
                                          labelText:
                                              l10n.locusEditorCardPhoneticLabel,
                                          hintText: 'ipa.txt',
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: b.audioCtrl!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                        ),
                                        decoration: InputDecoration(
                                          labelText: l10n.locusEditorCardAudioLabel,
                                          hintText: 'pronunciation.ogg',
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: b.relatedCtrl!,
                                        minLines: 2,
                                        maxLines: 6,
                                        decoration: InputDecoration(
                                          labelText:
                                              l10n.locusEditorCardRelatedLabel,
                                          hintText: l10n.locusEditorCardRelatedHint,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ],
                                    if (b.isImage) ...[
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: b.srcCtrl!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                        ),
                                        decoration: InputDecoration(
                                          labelText:
                                              'assets/${widget.entryKey}/',
                                          hintText: 'archivo.png',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          border: const OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _ImagePreviewTile(
                                        entryKey: widget.entryKey,
                                        srcController: b.srcCtrl!,
                                      ),
                                    ],
                                    if (!b.isImage && !b.isLink && !b.isCard)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: TextField(
                                          controller: b.textCtrl!,
                                          minLines: b.isLink ? 2 : 3,
                                          maxLines: 8,
                                          decoration: InputDecoration(
                                            labelText: b.isLink
                                                ? 'Link label'
                                                : 'Text',
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 6, bottom: 8),
                            child: _buildBlockOverviewRail(
                              context,
                              collageSeqByIndex,
                            ),
                          ),
                        ],
                      );
                if (_useDesktopDrop()) {
                  core = DropTarget(
                    onDragDone: _onDropDone,
                    child: core,
                  );
                }
                return core;
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _BlockKind { paragraph, link, image, card }

class _BlockDraft {
  _BlockDraft._paragraph(this.textCtrl)
      : kind = _BlockKind.paragraph,
        linkKeyCtrl = null,
        srcCtrl = null,
        wordCtrl = null,
        phoneticCtrl = null,
        audioCtrl = null,
        relatedCtrl = null,
        imgRole = 'content',
        textKind = 'text';

  _BlockDraft._link(this.textCtrl, this.linkKeyCtrl)
      : kind = _BlockKind.link,
        srcCtrl = null,
        wordCtrl = null,
        phoneticCtrl = null,
        audioCtrl = null,
        relatedCtrl = null,
        imgRole = 'content',
        textKind = 'text';

  _BlockDraft._image(this.srcCtrl, {String role = 'content', this.collageOrder})
      : kind = _BlockKind.image,
        textCtrl = null,
        linkKeyCtrl = null,
        wordCtrl = null,
        phoneticCtrl = null,
        audioCtrl = null,
        relatedCtrl = null,
        // Conservar recall_crop (quiz); antes se colapsaba a content/"Viewer" al reabrir el editor.
        imgRole = (role == 'hero' || role == 'collage' || role == 'recall_crop')
            ? role
            : 'content',
        textKind = 'text';

  _BlockDraft._card(
    this.wordCtrl,
    this.srcCtrl,
    this.phoneticCtrl,
    this.audioCtrl,
    this.relatedCtrl,
  )   : kind = _BlockKind.card,
        textCtrl = null,
        linkKeyCtrl = null,
        imgRole = 'content',
        textKind = 'text';

  factory _BlockDraft.p({String text = '', String textKind = 'text'}) {
    final b = _BlockDraft._paragraph(TextEditingController(text: text));
    b.textKind = _kTextKinds.containsKey(textKind) ? textKind : 'text';
    return b;
  }

  factory _BlockDraft.link({String destKey = '', String text = ''}) {
    return _BlockDraft._link(
      TextEditingController(text: text),
      TextEditingController(text: destKey),
    );
  }

  factory _BlockDraft.img({String src = '', String role = 'content', int? collageOrder}) {
    return _BlockDraft._image(
      TextEditingController(text: src),
      role: role,
      collageOrder: collageOrder,
    );
  }

  factory _BlockDraft.card({
    String word = '',
    String image = '',
    String phonetic = '',
    String audio = '',
    String related = '',
  }) {
    return _BlockDraft._card(
      TextEditingController(text: word),
      TextEditingController(text: image),
      TextEditingController(text: phonetic),
      TextEditingController(text: audio),
      TextEditingController(text: related),
    );
  }

  final _BlockKind kind;
  final TextEditingController? textCtrl;
  final TextEditingController? linkKeyCtrl;
  final TextEditingController? srcCtrl;
  final TextEditingController? wordCtrl;
  final TextEditingController? phoneticCtrl;
  final TextEditingController? audioCtrl;
  final TextEditingController? relatedCtrl;

  /// Bloques `img`: `hero`, `collage`, `recall_crop` (recorte quiz LB), `content`.
  String imgRole;
  int? collageOrder;
  String textKind;

  bool get isLink => kind == _BlockKind.link;
  bool get isImage => kind == _BlockKind.image;
  bool get isCard => kind == _BlockKind.card;

  void dispose() {
    textCtrl?.dispose();
    linkKeyCtrl?.dispose();
    srcCtrl?.dispose();
    wordCtrl?.dispose();
    phoneticCtrl?.dispose();
    audioCtrl?.dispose();
    relatedCtrl?.dispose();
  }
}

/// Miniatura local del archivo `src` bajo `assets/<entryKey>/`.
class _ImagePreviewTile extends StatefulWidget {
  const _ImagePreviewTile({
    required this.entryKey,
    required this.srcController,
  });

  final String entryKey;
  final TextEditingController srcController;

  @override
  State<_ImagePreviewTile> createState() => _ImagePreviewTileState();
}

class _ImagePreviewTileState extends State<_ImagePreviewTile> {
  @override
  void initState() {
    super.initState();
    widget.srcController.addListener(_onSrcChanged);
  }

  @override
  void dispose() {
    widget.srcController.removeListener(_onSrcChanged);
    super.dispose();
  }

  void _onSrcChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.srcController.text.trim();
    if (name.isEmpty) {
      return Text(
        'Preview: set a filename',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final path =
        '${AlexandriaPaths.assetsRoot}${Platform.pathSeparator}${widget.entryKey}${Platform.pathSeparator}$name';
    final f = File(path);
    if (!f.existsSync()) {
      return Text(
        'Not found: $path',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        f,
        height: 160,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Text('Could not load image'),
      ),
    );
  }
}
