import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_paths.dart';
import '../library_build.dart';
import 'pao_clipboard_image.dart';

File? paoAbsFileForRel(String rel) {
  final t = rel.trim();
  if (t.isEmpty) return null;
  final p =
      '${AlexandriaPaths.assetsRoot}${Platform.pathSeparator}${t.replaceAll('/', Platform.pathSeparator)}';
  final f = File(p);
  return f.existsSync() ? f : null;
}

String? paoCopyPathToSlot(int code, String sourcePath) {
  try {
    final dir = Directory('${AlexandriaPaths.assetsRoot}/pao');
    dir.createSync(recursive: true);
    final base = PaoStandardRow.formatCode(code);
    var ext = '.png';
    final lower = sourcePath.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      ext = '.jpg';
    } else if (lower.endsWith('.webp')) {
      ext = '.webp';
    } else if (lower.endsWith('.gif')) {
      ext = '.gif';
    } else if (lower.endsWith('.png')) {
      ext = '.png';
    }
    final rel = 'pao/pao_$base$ext';
    final out = File('${AlexandriaPaths.assetsRoot}/$rel');
    File(sourcePath).copySync(out.path);
    return rel;
  } catch (_) {
    return null;
  }
}

String? paoWriteBytesToSlot(int code, Uint8List bytes, String ext) {
  var e = ext.toLowerCase();
  if (e.startsWith('.')) e = e.substring(1);
  if (e == 'jpeg') e = 'jpg';
  const ok = {'png', 'jpg', 'webp', 'gif', 'bmp', 'tiff'};
  if (!ok.contains(e)) e = 'png';
  try {
    final dir = Directory('${AlexandriaPaths.assetsRoot}/pao');
    dir.createSync(recursive: true);
    final base = PaoStandardRow.formatCode(code);
    final rel = 'pao/pao_$base.$e';
    File('${AlexandriaPaths.assetsRoot}/$rel').writeAsBytesSync(bytes, flush: true);
    return rel;
  } catch (_) {
    return null;
  }
}

bool _paoUseDesktopDrop() =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

/// Editor y carga de **PAO 00–99** (sistema de 2 dígitos) en la DB del realm activo.
class PaoStandardPage extends StatefulWidget {
  const PaoStandardPage({super.key, required this.db});

  final Database db;

  @override
  State<PaoStandardPage> createState() => _PaoStandardPageState();
}

class _PaoStandardPageState extends State<PaoStandardPage> {
  List<PaoStandardRow> _rows = [];
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    ensureLibrarySchema(widget.db);
    setState(() {
      _rows = loadPaoStandardMerged(widget.db);
    });
  }

  List<PaoStandardRow> get _visible {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((r) {
      final code = PaoStandardRow.formatCode(r.code).toLowerCase();
      return code.contains(q) ||
          r.person.toLowerCase().contains(q) ||
          r.action.toLowerCase().contains(q) ||
          r.object.toLowerCase().contains(q) ||
          r.imageRel.toLowerCase().contains(q);
    }).toList();
  }

  int get _filledCount => _rows.where((r) {
        return r.person.trim().isNotEmpty ||
            r.action.trim().isNotEmpty ||
            r.object.trim().isNotEmpty ||
            r.imageRel.trim().isNotEmpty;
      }).length;

  Widget _leadingTile(PaoStandardRow r) {
    final code = PaoStandardRow.formatCode(r.code);
    final img = paoAbsFileForRel(r.imageRel);
    if (img != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          img,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              CircleAvatar(child: Text(code)),
        ),
      );
    }
    return CircleAvatar(child: Text(code));
  }

  Future<void> _writeTemplateToRepo() async {
    final dir = Directory(AlexandriaPaths.paoDatasetDir);
    dir.createSync(recursive: true);
    final path = AlexandriaPaths.paoTemplate00_99Path;
    final f = File(path);
    if (f.existsSync()) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Plantilla ya existe'),
          content: Text('¿Sobrescribir?\n$path'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sobrescribir')),
          ],
        ),
      );
      if (ok != true) return;
    }
    const enc = JsonEncoder.withIndent('  ');
    f.writeAsStringSync(enc.convert(emptyPaoStandardJsonMap()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plantilla escrita: $path')),
    );
  }

  Future<void> _importJsonPick() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (r == null || r.files.isEmpty) return;
    final path = r.files.single.path;
    if (path == null || path.isEmpty) return;
    try {
      final text = File(path).readAsStringSync();
      final err = importPaoStandardFromJsonString(widget.db, text);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red.shade800),
        );
      } else {
        _reload();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Importados 100 códigos PAO')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade800),
      );
    }
  }

  Future<void> _exportJsonPick() async {
    final text = exportPaoStandardJson(widget.db);
    final r = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar PAO JSON',
      fileName: 'pao_00_99.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (r == null) return;
    try {
      File(r).writeAsStringSync(text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guardado: $r')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade800),
      );
    }
  }

  Future<void> _exportCsvPick() async {
    final text = exportPaoStandardCsv(widget.db);
    final r = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar PAO CSV',
      fileName: 'pao_00_99.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (r == null) return;
    try {
      File(r).writeAsStringSync(text, encoding: utf8);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guardado: $r')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade800),
      );
    }
  }

  Future<void> _copyJsonToClipboard() async {
    final text = exportPaoStandardJson(widget.db);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON PAO copiado al portapapeles')),
    );
  }

  Future<void> _editRow(PaoStandardRow row) async {
    final result = await showDialog<_PaoEditResult?>(
      context: context,
      builder: (ctx) => _PaoEditDialog(row: row),
    );
    if (result == null || !mounted) return;
    upsertPaoStandard(
      widget.db,
      code: row.code,
      person: result.person,
      action: result.action,
      object: result.object,
      imageRel: result.imageRel,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle =
        'Sistema de 2 dígitos · $_filledCount / 100 con texto o imagen · realm ${AlexandriaPaths.readActiveRealmId()}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAO (00–99)'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'tpl') {
                await _writeTemplateToRepo();
              } else if (v == 'imp') {
                await _importJsonPick();
              } else if (v == 'ej') {
                await _exportJsonPick();
              } else if (v == 'ec') {
                await _exportCsvPick();
              } else if (v == 'clip') {
                await _copyJsonToClipboard();
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'tpl', child: Text('Crear/sobrescribir plantilla en repo')),
              PopupMenuItem(value: 'imp', child: Text('Importar JSON (100 códigos obligatorios)')),
              PopupMenuItem(value: 'ej', child: Text('Exportar JSON…')),
              PopupMenuItem(value: 'ec', child: Text('Exportar CSV…')),
              PopupMenuItem(value: 'clip', child: Text('Copiar JSON al portapapeles')),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por código, persona, acción, objeto o ruta imagen',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (s) => setState(() => _filter = s),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _visible.length,
              itemBuilder: (ctx, i) {
                final r = _visible[i];
                final oneLine = [r.person, r.action, r.object]
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .join(' · ');
                return ListTile(
                  leading: _leadingTile(r),
                  title: Text(oneLine.isEmpty ? '(vacío)' : oneLine, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    'P: ${r.person.isEmpty ? "—" : r.person}  |  A: ${r.action.isEmpty ? "—" : r.action}  |  O: ${r.object.isEmpty ? "—" : r.object}'
                    '${r.imageRel.isEmpty ? "" : "\nimg: ${r.imageRel}"}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _editRow(r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaoEditResult {
  const _PaoEditResult({
    required this.person,
    required this.action,
    required this.object,
    required this.imageRel,
  });
  final String person;
  final String action;
  final String object;
  final String imageRel;
}

class _PaoEditDialog extends StatefulWidget {
  const _PaoEditDialog({required this.row});

  final PaoStandardRow row;

  @override
  State<_PaoEditDialog> createState() => _PaoEditDialogState();
}

class _PaoEditDialogState extends State<_PaoEditDialog> {
  late TextEditingController _pCtrl;
  late TextEditingController _aCtrl;
  late TextEditingController _oCtrl;
  late String _imageRel;

  @override
  void initState() {
    super.initState();
    _pCtrl = TextEditingController(text: widget.row.person);
    _aCtrl = TextEditingController(text: widget.row.action);
    _oCtrl = TextEditingController(text: widget.row.object);
    _imageRel = widget.row.imageRel;
    HardwareKeyboard.instance.addHandler(_hardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_hardwareKey);
    _pCtrl.dispose();
    _aCtrl.dispose();
    _oCtrl.dispose();
    super.dispose();
  }

  bool _focusInEditableText() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _hardwareKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    if (e.logicalKey != LogicalKeyboardKey.keyV) return false;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final meta = pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    if (!ctrl && !meta) return false;
    if (_focusInEditableText()) return false;
    _pasteImage();
    return true;
  }

  Future<void> _pasteImage() async {
    final got = await readFirstImageFromSystemClipboard();
    if (got == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Portapapeles: no hay imagen')),
      );
      return;
    }
    final rel = paoWriteBytesToSlot(widget.row.code, got.bytes, got.ext);
    if (!mounted) return;
    if (rel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la imagen')),
      );
      return;
    }
    setState(() => _imageRel = rel);
  }

  Future<void> _onDropDone(DropDoneDetails details) async {
    for (final item in details.files) {
      final path = item.path;
      if (path.isEmpty) continue;
      final low = path.toLowerCase();
      const ok = <String>['.png', '.jpg', '.jpeg', '.webp', '.gif'];
      var allowed = false;
      for (final s in ok) {
        if (low.endsWith(s)) {
          allowed = true;
          break;
        }
      }
      if (!allowed) continue;
      final rel = paoCopyPathToSlot(widget.row.code, path);
      if (rel != null) {
        if (!mounted) return;
        setState(() => _imageRel = rel);
        return;
      }
    }
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );
    if (r == null || r.files.isEmpty) return;
    final path = r.files.single.path;
    if (path == null || path.isEmpty) return;
    final rel = paoCopyPathToSlot(widget.row.code, path);
    if (!mounted) return;
    if (rel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo copiar la imagen')),
      );
      return;
    }
    setState(() => _imageRel = rel);
  }

  @override
  Widget build(BuildContext context) {
    final codeLabel = PaoStandardRow.formatCode(widget.row.code);
    final imgFile = paoAbsFileForRel(_imageRel);
    Widget inner = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Arrastra imagen aquí, o Ctrl+V / Cmd+V con el foco fuera de Persona/Acción/Objeto.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (imgFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imgFile,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('No se puede cargar la imagen'),
                ),
              ),
            ),
          Text(
            _imageRel.isEmpty ? 'Sin imagen (opcional)' : 'assets/$_imageRel',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _pickFile,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Elegir imagen'),
              ),
              if (_imageRel.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _imageRel = ''),
                  child: const Text('Quitar imagen'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pCtrl,
            decoration: const InputDecoration(labelText: 'Persona'),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aCtrl,
            decoration: const InputDecoration(labelText: 'Acción'),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _oCtrl,
            decoration: const InputDecoration(labelText: 'Objeto'),
            maxLines: 2,
          ),
        ],
      ),
    );
    if (_paoUseDesktopDrop()) {
      inner = DropTarget(
        onDragDone: _onDropDone,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: inner,
          ),
        ),
      );
    }
    return AlertDialog(
      title: Text('PAO $codeLabel'),
      content: inner,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _PaoEditResult(
                person: _pCtrl.text,
                action: _aCtrl.text,
                object: _oCtrl.text,
                imageRel: _imageRel,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
