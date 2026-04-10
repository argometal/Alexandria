import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'package:super_clipboard/super_clipboard.dart';

import 'alexandria_paths.dart';
import 'library_build.dart'
    show
        buildViewerForKey,
        ensureLibrarySchema,
        kCognitiveRoles,
        normalizeCognitiveRole,
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
  String _cognitiveRole = 'object';
  /// Bloque `img` seleccionado para Ctrl/Cmd+H (portada marco GK).
  int? _focusedImageBlockIndex;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    _loadFromDb();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
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
        if (_blocks[j].isImage) {
          _blocks[j].imgRole = j == i ? 'hero' : 'content';
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
      'SELECT body_text, cognitiveRole FROM entries WHERE key = ? LIMIT 1',
      [widget.entryKey],
    );
    final raw = rows.isEmpty ? null : rows.first['body_text'] as String?;
    final roleRaw = rows.isEmpty ? null : rows.first['cognitiveRole'];
    final loaded = _decodeBodyText(raw);
    setState(() {
      _cognitiveRole = normalizeCognitiveRole(roleRaw);
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
          var role = (m['role'] ?? 'content').toString().toLowerCase().trim();
          if (role == 'img') role = 'content';
          if (role != 'hero' && role != 'collage' && role != 'content') {
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
    final payload = <Map<String, dynamic>>[];
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
      } else if (b.isImage) {
        final s = b.srcCtrl!.text.trim();
        if (s.isEmpty) continue;
        final row = <String, dynamic>{'type': 'img', 'src': s};
        if (b.imgRole == 'hero') {
          row['role'] = 'hero';
        } else if (b.imgRole == 'collage') {
          row['role'] = 'collage';
          row['collageOrder'] = b.collageOrder ?? nextAutoOrder++;
        } else {
          row['role'] = 'content';
        }
        payload.add(row);
      } else {
        final t = b.textCtrl!.text.trim();
        if (t.isEmpty) continue;
        payload.add({'type': 'p', 'text': t, 'textKind': b.textKind});
      }
    }

    final String? stored =
        payload.isEmpty ? null : jsonEncode(payload);

    widget.db.execute(
      'UPDATE entries SET body_text = ?, cognitiveRole = ? WHERE key = ?',
      [stored, _cognitiveRole, widget.entryKey],
    );

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardado')),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('LocusEditor · ${widget.entryKey}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'migrate') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Migrate content: pending functional definition'),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'migrate',
                child: Text('Migrate content (pending)'),
              ),
            ],
          ),
          TextButton(
            onPressed: _save,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Cognitive role (LB only; GK does not read this)',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _cognitiveRole,
                  items: [
                    for (final r in kCognitiveRoles)
                      DropdownMenuItem<String>(
                        value: r,
                        child: Text(_kCognitiveRoleLabels[r] ?? r),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _cognitiveRole = v);
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _addParagraph,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('Paragraph'),
                ),
                OutlinedButton.icon(
                  onPressed: _addLink,
                  icon: const Icon(Icons.link),
                  label: const Text('Link'),
                ),
                OutlinedButton.icon(
                  onPressed: _addImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Image'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Paste image or text: Ctrl+V / Cmd+V (with focus outside text fields). '
              'Set image target: Content (viewer only), Collage (GK wall), or Hero (GK frame). '
              'Hero shortcut: click image + Ctrl/Cmd+H. '
              'Desktop: drop .png / .jpg / .webp files.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                Widget core = _blocks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No blocks yet. Add paragraph, link, image, '
                            'or paste/drop an image.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _blocks.length,
                        itemBuilder: (context, i) {
                          final b = _blocks[i];
                          final last = i == _blocks.length - 1;
                          final imgFocused =
                              b.isImage && _focusedImageBlockIndex == i;
                          final tagLabel = b.isLink
                              ? 'link'
                              : b.isImage
                                  ? (b.imgRole == 'hero'
                                      ? 'HERO'
                                      : b.imgRole == 'collage'
                                          ? 'COLLAGE #${collageSeqByIndex[i] ?? 0}'
                                          : 'CONTENT')
                                  : 'p';
                          return Card(
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
                                          ? const Color(0xFF1565C0)
                                          : b.imgRole == 'collage'
                                              ? const Color(0xFF2E7D32)
                                          : Colors.grey.shade600,
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
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(
                                            tagLabel,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: b.isImage
                                              ? (b.imgRole == 'hero'
                                                  ? Colors.blue.shade100
                                                  : b.imgRole == 'collage'
                                                      ? Colors.green.shade100
                                                  : Colors.grey.shade300)
                                              : null,
                                        ),
                                        if (imgFocused) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'focus · Ctrl/Cmd+H',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.arrow_upward),
                                          tooltip: 'Move up',
                                          onPressed: i == 0
                                              ? null
                                              : () => _moveUp(i),
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.arrow_downward),
                                          tooltip: 'Move down',
                                          onPressed:
                                              last ? null : () => _moveDown(i),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          tooltip: 'Delete',
                                          onPressed: () => _removeAt(i),
                                        ),
                                      ],
                                    ),
                                    if (!b.isImage && !b.isLink) ...[
                                      DropdownButtonFormField<String>(
                                        initialValue: b.textKind,
                                        decoration: const InputDecoration(
                                          labelText: 'Text kind',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: [
                                          for (final e in _kTextKinds.entries)
                                            DropdownMenuItem<String>(
                                              value: e.key,
                                              child: Text(e.value),
                                            ),
                                        ],
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(() => b.textKind = v);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (b.isLink) ...[
                                      TextField(
                                        controller: b.linkKeyCtrl!,
                                        decoration: const InputDecoration(
                                          labelText: 'Target KEY',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (b.isImage) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              initialValue: b.imgRole,
                                              decoration: const InputDecoration(
                                                labelText: 'Image target',
                                                border: OutlineInputBorder(),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'content',
                                                  child: Text('Viewer only'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'collage',
                                                  child: Text('Wall collage (GK)'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'hero',
                                                  child: Text('Hero (GK frame)'),
                                                ),
                                              ],
                                              onChanged: (v) {
                                                if (v == null) return;
                                                setState(() {
                                                  if (v == 'hero') {
                                                    for (final other in _blocks) {
                                                      if (other.isImage && other.imgRole == 'hero') {
                                                        other.imgRole = 'content';
                                                      }
                                                    }
                                                    b.collageOrder = null;
                                                  } else if (v == 'collage') {
                                                    b.collageOrder ??= _nextCollageOrder();
                                                  } else {
                                                    b.collageOrder = null;
                                                  }
                                                  b.imgRole = v;
                                                });
                                              },
                                            ),
                                          ),
                                          if (b.imgRole == 'collage') ...[
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 92,
                                              child: TextFormField(
                                                initialValue: (b.collageOrder ?? 1).toString(),
                                                keyboardType: const TextInputType.numberWithOptions(
                                                  signed: false,
                                                  decimal: false,
                                                ),
                                                decoration: const InputDecoration(
                                                  labelText: 'Order',
                                                  border: OutlineInputBorder(),
                                                  isDense: true,
                                                ),
                                                onChanged: (v) {
                                                  final n = int.tryParse(v.trim());
                                                  if (n == null || n <= 0) return;
                                                  b.collageOrder = n;
                                                },
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: b.srcCtrl!,
                                        decoration: InputDecoration(
                                          labelText:
                                              'File in assets/${widget.entryKey}/',
                                          hintText: 'e.g. image.png',
                                          border: const OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _ImagePreviewTile(
                                        entryKey: widget.entryKey,
                                        srcController: b.srcCtrl!,
                                      ),
                                    ] else
                                      TextField(
                                        controller: b.textCtrl!,
                                        minLines: b.isLink ? 2 : 3,
                                        maxLines: 8,
                                        decoration: InputDecoration(
                                          labelText: b.isLink
                                              ? 'Link label'
                                              : 'Text',
                                          border: const OutlineInputBorder(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

enum _BlockKind { paragraph, link, image }

class _BlockDraft {
  _BlockDraft._paragraph(this.textCtrl)
      : kind = _BlockKind.paragraph,
        linkKeyCtrl = null,
        srcCtrl = null,
        imgRole = 'content',
        textKind = 'text';

  _BlockDraft._link(this.textCtrl, this.linkKeyCtrl)
      : kind = _BlockKind.link,
        srcCtrl = null,
        imgRole = 'content',
        textKind = 'text';

  _BlockDraft._image(this.srcCtrl, {String role = 'content', this.collageOrder})
      : kind = _BlockKind.image,
        textCtrl = null,
        linkKeyCtrl = null,
        imgRole = (role == 'hero' || role == 'collage') ? role : 'content',
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

  final _BlockKind kind;
  final TextEditingController? textCtrl;
  final TextEditingController? linkKeyCtrl;
  final TextEditingController? srcCtrl;

  /// Solo bloques `img`: `hero` (marco GK), `collage` (pared GK), `content` (solo viewer).
  String imgRole;
  int? collageOrder;
  String textKind;

  bool get isLink => kind == _BlockKind.link;
  bool get isImage => kind == _BlockKind.image;

  void dispose() {
    textCtrl?.dispose();
    linkKeyCtrl?.dispose();
    srcCtrl?.dispose();
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
