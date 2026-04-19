import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_paths.dart';
import '../library_build.dart';
import '../l10n/app_localizations.dart';
import 'pao_clipboard_image.dart';
import 'pao_exercise_preview.dart';
import 'pao_individual_drill_page.dart';

/// Alexandria PAO — mismo lado (dp) para el tile de lista y las previsualizaciones del editor.
const double _kPaoImagePreviewDp = 120;

File? paoAbsFileForRel(String rel) {
  final t = rel.trim();
  if (t.isEmpty) return null;
  final p =
      '${AlexandriaPaths.assetsRoot}${Platform.pathSeparator}${t.replaceAll('/', Platform.pathSeparator)}';
  final f = File(p);
  return f.existsSync() ? f : null;
}

/// Elimina archivos bajo el realm para las rutas relativas indicadas (p. ej. `pao/pao_08.png`).
void deletePaoRelAssetFiles(Iterable<String> rels) {
  for (final raw in rels) {
    final f = paoAbsFileForRel(raw);
    if (f == null) continue;
    try {
      f.deleteSync();
    } catch (_) {}
  }
}

String? paoCopyPathToSlot(int code, String sourcePath) {
  try {
    final dir = Directory('${AlexandriaPaths.assetsRoot}/pao');
    dir.createSync(recursive: true);
    final base = PaoStandardRow.storageFileStem(code);
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
    final base = PaoStandardRow.storageFileStem(code);
    final rel = 'pao/pao_$base.$e';
    File('${AlexandriaPaths.assetsRoot}/$rel').writeAsBytesSync(bytes, flush: true);
    return rel;
  } catch (_) {
    return null;
  }
}

/// Sufijos: `p1`, `p2` (persona), `o1`, `o2` (objeto) — distinto archivo por ranura.
String? paoCopyPathToSlotSuffix(int code, String sourcePath, String slotKey) {
  try {
    final dir = Directory('${AlexandriaPaths.assetsRoot}/pao');
    dir.createSync(recursive: true);
    final base = PaoStandardRow.storageFileStem(code);
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
    final rel = 'pao/pao_${base}_$slotKey$ext';
    final out = File('${AlexandriaPaths.assetsRoot}/$rel');
    File(sourcePath).copySync(out.path);
    return rel;
  } catch (_) {
    return null;
  }
}

String? paoWriteBytesToSlotSuffix(int code, Uint8List bytes, String ext, String slotKey) {
  var e = ext.toLowerCase();
  if (e.startsWith('.')) e = e.substring(1);
  if (e == 'jpeg') e = 'jpg';
  const ok = {'png', 'jpg', 'webp', 'gif', 'bmp', 'tiff'};
  if (!ok.contains(e)) e = 'png';
  try {
    final dir = Directory('${AlexandriaPaths.assetsRoot}/pao');
    dir.createSync(recursive: true);
    final base = PaoStandardRow.storageFileStem(code);
    final rel = 'pao/pao_${base}_$slotKey.$e';
    File('${AlexandriaPaths.assetsRoot}/$rel').writeAsBytesSync(bytes, flush: true);
    return rel;
  } catch (_) {
    return null;
  }
}

bool _paoUseDesktopDrop() =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

bool _lbFocusInEditableText() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Editor PAO: **claves fonéticas 0–9**, clavijas **0–9**, **00–99**, **000–999**.
class PaoStandardPage extends StatefulWidget {
  const PaoStandardPage({super.key, required this.db});

  final Database db;

  @override
  State<PaoStandardPage> createState() => _PaoStandardPageState();
}

class _PaoStandardPageState extends State<PaoStandardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<PaoStandardRow> _rowsPair = [];
  List<PaoStandardRow> _rowsDigit = [];
  List<PaoStandardRow> _rowsTriple = [];
  List<PaoPhoneticRow> _phonetic = [];
  String _filter = '';
  /// Último código tocado en listas 0–9 / 00–99 / 000–999 (pegado / drop en la página).
  int? _lastTouchedPaoCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _reload();
    if (_paoUseDesktopDrop()) {
      HardwareKeyboard.instance.addHandler(_paoPageHardwareKey);
    }
  }

  @override
  void dispose() {
    if (_paoUseDesktopDrop()) {
      HardwareKeyboard.instance.removeHandler(_paoPageHardwareKey);
    }
    _tabController.dispose();
    super.dispose();
  }

  PaoStandardRow? _rowByCodeInCurrentTab(int code) {
    final ti = _tabController.index;
    final List<PaoStandardRow> rows;
    if (ti == 1) {
      rows = _rowsDigit;
    } else if (ti == 2) {
      rows = _rowsPair;
    } else if (ti == 3) {
      rows = _rowsTriple;
    } else {
      return null;
    }
    for (final r in rows) {
      if (r.code == code) return r;
    }
    return null;
  }

  bool _paoPageHardwareKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    if (e.logicalKey != LogicalKeyboardKey.keyV) return false;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final meta = pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    if (!ctrl && !meta) return false;
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return false;
    if (_lbFocusInEditableText()) return false;
    _pagePasteImageToLastCode();
    return true;
  }

  Future<void> _pagePasteImageToLastCode() async {
    final l10n = AppLocalizations.of(context)!;
    final ti = _tabController.index;
    if (ti == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarPasteImageUseTabs)),
      );
      return;
    }
    final code = _lastTouchedPaoCode;
    if (code == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarTapRowFirst)),
      );
      return;
    }
    final row = _rowByCodeInCurrentTab(code);
    if (row == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarCodeNotInTab)),
      );
      return;
    }
    final got = await readFirstImageFromSystemClipboard();
    if (got == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarClipboardNoImage)),
      );
      return;
    }
    final rel = paoWriteBytesToSlot(row.code, got.bytes, got.ext);
    if (!mounted) return;
    if (rel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarCouldNotSaveImage)),
      );
      return;
    }
    upsertPaoStandard(
      widget.db,
      code: row.code,
      person: row.person,
      action: row.action,
      object: row.object,
      imageRel: rel,
      personImageRel: row.personImageRel,
      personImageRel2: row.personImageRel2,
      objectImageRel: row.objectImageRel,
      objectImageRel2: row.objectImageRel2,
    );
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.paoSnackbarCodeImageUpdated(PaoStandardRow.formatCode(row.code)),
        ),
      ),
    );
  }

  Future<void> _pageDropDone(DropDoneDetails details) async {
    final l10n = AppLocalizations.of(context)!;
    final ti = _tabController.index;
    if (ti == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarDropImageUseTabs)),
      );
      return;
    }
    final code = _lastTouchedPaoCode;
    if (code == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarTapRowFirst)),
      );
      return;
    }
    final row = _rowByCodeInCurrentTab(code);
    if (row == null) return;

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
      final rel = paoCopyPathToSlot(row.code, path);
      if (rel == null) continue;
      if (!mounted) return;
      upsertPaoStandard(
        widget.db,
        code: row.code,
        person: row.person,
        action: row.action,
        object: row.object,
        imageRel: rel,
        personImageRel: row.personImageRel,
        personImageRel2: row.personImageRel2,
        objectImageRel: row.objectImageRel,
        objectImageRel2: row.objectImageRel2,
      );
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.paoSnackbarCodeImageUpdated(PaoStandardRow.formatCode(row.code)),
          ),
        ),
      );
      return;
    }
  }

  void _reload() {
    ensureLibrarySchema(widget.db);
    setState(() {
      _rowsPair = loadPaoStandardMerged(widget.db);
      _rowsDigit = loadPaoDigitMerged(widget.db);
      _rowsTriple = loadPaoTripleMerged(widget.db);
      _phonetic = loadPaoPhoneticMerged(widget.db);
    });
  }

  List<PaoStandardRow> _visibleFor(List<PaoStandardRow> rows) {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) {
      final code = PaoStandardRow.formatCode(r.code).toLowerCase();
      return code.contains(q) ||
          r.person.toLowerCase().contains(q) ||
          r.action.toLowerCase().contains(q) ||
          r.object.toLowerCase().contains(q) ||
          r.imageRel.toLowerCase().contains(q) ||
          r.personImageRel.toLowerCase().contains(q) ||
          r.personImageRel2.toLowerCase().contains(q) ||
          r.objectImageRel.toLowerCase().contains(q) ||
          r.objectImageRel2.toLowerCase().contains(q);
    }).toList();
  }

  int _filledCountFor(List<PaoStandardRow> rows) {
    return rows
        .where((r) {
          return r.person.trim().isNotEmpty ||
              r.action.trim().isNotEmpty ||
              r.object.trim().isNotEmpty ||
              r.imageRel.trim().isNotEmpty ||
              r.personImageRel.trim().isNotEmpty ||
              r.personImageRel2.trim().isNotEmpty ||
              r.objectImageRel.trim().isNotEmpty ||
              r.objectImageRel2.trim().isNotEmpty;
        })
        .length;
  }

  int _tierTotal(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return 10;
      case 2:
        return 100;
      case 3:
        return 1000;
      default:
        return 0;
    }
  }

  static const double _kPaoListLeadingSize = _kPaoImagePreviewDp;

  /// Lista: **código identificador + miniatura** (proporción 2∶3 código∶imagen dentro del tile).
  Widget _leadingTile(PaoStandardRow r, AppLocalizations l10n) {
    final code = PaoStandardRow.formatCode(r.code);
    File? imgFile;
    for (final rel in [
      r.imageRel,
      r.personImageRel,
      r.personImageRel2,
      r.objectImageRel,
      r.objectImageRel2,
    ]) {
      final img = paoAbsFileForRel(rel);
      if (img != null) {
        imgFile = img;
        break;
      }
    }
    final cs = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
        );
    final codeStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        );
    if (imgFile != null) {
      return Container(
        width: _kPaoListLeadingSize,
        height: _kPaoListLeadingSize,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.paoFieldCode, style: labelStyle),
                        Text(code, style: codeStyle),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Image.file(
                imgFile,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: cs.surfaceContainerHigh,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 22,
                    color: cs.outline,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: _kPaoListLeadingSize,
      height: _kPaoListLeadingSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.paoFieldCode, style: labelStyle),
                  Text(code, style: codeStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _writeTemplateToRepo() async {
    final l10n = AppLocalizations.of(context)!;
    final dir = Directory(AlexandriaPaths.paoDatasetDir);
    dir.createSync(recursive: true);
    final path = AlexandriaPaths.paoTemplate00_99Path;
    final f = File(path);
    if (f.existsSync()) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.paoTemplateExistsTitle),
          content: Text(l10n.paoTemplateExistsBody(path)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.paoOverwrite)),
          ],
        ),
      );
      if (ok != true) return;
    }
    const enc = JsonEncoder.withIndent('  ');
    f.writeAsStringSync(enc.convert(emptyPaoStandardJsonMap()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.paoTemplateWritten0099(path))),
    );
  }

  Future<void> _writeTemplateV2ToRepo() async {
    final l10n = AppLocalizations.of(context)!;
    final dir = Directory(AlexandriaPaths.paoDatasetDir);
    dir.createSync(recursive: true);
    final path = '${AlexandriaPaths.paoDatasetDir}/pao_library_v2.template.json';
    final f = File(path);
    if (f.existsSync()) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.paoTemplateExistsTitle),
          content: Text(l10n.paoTemplateExistsBody(path)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.paoOverwrite)),
          ],
        ),
      );
      if (ok != true) return;
    }
    const enc = JsonEncoder.withIndent('  ');
    f.writeAsStringSync(enc.convert(emptyPaoLibraryJsonMapV2()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.paoSnackbarTemplateV2(path))),
    );
  }

  Future<void> _importJsonPick() async {
    final l10n = AppLocalizations.of(context)!;
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (r == null || r.files.isEmpty) return;
    final path = r.files.single.path;
    if (path == null || path.isEmpty) return;
    try {
      final text = File(path).readAsStringSync();
      final err = importPaoJsonAuto(widget.db, text);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red.shade800),
        );
      } else {
        _reload();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paoSnackbarImportOk)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paoErrorGeneric('$e')),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _exportJsonPick() async {
    final l10n = AppLocalizations.of(context)!;
    final text = exportPaoLibraryJsonV2(widget.db);
    final r = await FilePicker.platform.saveFile(
      dialogTitle: l10n.paoExportJsonDialogTitle,
      fileName: 'pao_library_v2.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (r == null) return;
    try {
      File(r).writeAsStringSync(text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSavedToPath(r))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paoErrorGeneric('$e')),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _exportCsvPick() async {
    final l10n = AppLocalizations.of(context)!;
    final text = exportPaoStandardCsv(widget.db);
    final r = await FilePicker.platform.saveFile(
      dialogTitle: l10n.paoExportCsvDialogTitle,
      fileName: 'pao_00_99.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (r == null) return;
    try {
      File(r).writeAsStringSync(text, encoding: utf8);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSavedToPath(r))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paoErrorGeneric('$e')),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _copyJsonToClipboard() async {
    final l10n = AppLocalizations.of(context)!;
    final text = exportPaoLibraryJsonV2(widget.db);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.paoJsonV2CopiedClipboard)),
    );
  }

  Future<void> _editRow(PaoStandardRow row) async {
    final result = await showDialog<Object?>(
      context: context,
      builder: (ctx) => _PaoEditDialog(db: widget.db, row: row),
    );
    if (!mounted) return;
    if (result is _PaoEditPegCleared) {
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.paoEditDeletePegSuccess),
        ),
      );
      return;
    }
    if (result is! _PaoEditResult) return;
    upsertPaoStandard(
      widget.db,
      code: row.code,
      person: result.person,
      action: result.action,
      object: result.object,
      imageRel: result.imageRel,
      personImageRel: result.personImageRel,
      personImageRel2: result.personImageRel2,
      objectImageRel: result.objectImageRel,
      objectImageRel2: result.objectImageRel2,
    );
    _reload();
  }

  Widget _buildPegListView(List<PaoStandardRow> source) {
    final l10n = AppLocalizations.of(context)!;
    final visible = _visibleFor(source);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: visible.length,
      itemBuilder: (ctx, i) {
        final r = visible[i];
        final oneLine = [r.person, r.action, r.object]
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .join(' · ');
        final cs = Theme.of(context).colorScheme;
        final titleStyle = Theme.of(context).textTheme.titleMedium;
        final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            );
        final dash = '\u2014';
        // ListTile dense limita la altura del `leading` y aplasta el tile 120×120 cuando hay imagen.
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _lastTouchedPaoCode = r.code;
              _editRow(r);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _leadingTile(r, l10n),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          oneLine.isEmpty ? l10n.paoListEmptyRow : oneLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.paoListDetailLine(
                            r.person.isEmpty ? dash : r.person,
                            r.action.isEmpty ? dash : r.action,
                            r.object.isEmpty ? dash : r.object,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: subStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final realm = AlexandriaPaths.readActiveRealmId();
    final ti = _tabController.index;
    final String subtitle;
    if (ti == 0) {
      subtitle = l10n.paoPhoneticBoardHint;
    } else {
      final rows = ti == 1
          ? _rowsDigit
          : ti == 2
              ? _rowsPair
              : _rowsTriple;
      subtitle = l10n.paoSubtitleTier(
        _filledCountFor(rows),
        _tierTotal(ti),
        realm,
      );
    }

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ),
        if (_tabController.index > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.paoSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (s) => setState(() => _filter = s),
            ),
          ),
        if (_tabController.index > 0) const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PaoPhoneticBoard(
                db: widget.db,
                rows: _phonetic,
                onRowSaved: () {
                  if (!mounted) return;
                  _reload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.paoPhoneticSaved)),
                  );
                },
                l10n: l10n,
              ),
              _buildPegListView(_rowsDigit),
              _buildPegListView(_rowsPair),
              _buildPegListView(_rowsTriple),
            ],
          ),
        ),
      ],
    );
    if (_paoUseDesktopDrop()) {
      body = DropTarget(
        onDragDone: _pageDropDone,
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paoEditorTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.paoTabPhonetic),
            Tab(text: l10n.paoTabDigit),
            Tab(text: l10n.paoTabPair),
            Tab(text: l10n.paoTabTriple),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Práctica individual (triple drill)',
            icon: const Icon(Icons.school_outlined),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PaoIndividualDrillPage(db: widget.db),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'tpl') {
                await _writeTemplateToRepo();
              } else if (v == 'tpl2') {
                await _writeTemplateV2ToRepo();
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
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'tpl', child: Text(l10n.paoMenuTemplate0099)),
              PopupMenuItem(value: 'tpl2', child: Text(l10n.paoMenuTemplateV2)),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'imp', child: Text(l10n.paoMenuImportJsonAuto)),
              PopupMenuItem(value: 'ej', child: Text(l10n.paoMenuExportJsonV2)),
              PopupMenuItem(value: 'ec', child: Text(l10n.paoMenuExportPairCsv)),
              PopupMenuItem(value: 'clip', child: Text(l10n.paoMenuCopyJsonV2Clipboard)),
            ],
          ),
        ],
      ),
      body: body,
    );
  }
}

class _PaoPhoneticBoard extends StatefulWidget {
  const _PaoPhoneticBoard({
    required this.db,
    required this.rows,
    required this.onRowSaved,
    required this.l10n,
  });

  final Database db;
  final List<PaoPhoneticRow> rows;
  final VoidCallback onRowSaved;
  final AppLocalizations l10n;

  @override
  State<_PaoPhoneticBoard> createState() => _PaoPhoneticBoardState();
}

class _PaoPhoneticBoardState extends State<_PaoPhoneticBoard> {
  late List<TextEditingController> _cons;
  late List<TextEditingController> _vowel;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  void _syncControllers() {
    _cons = List.generate(
      10,
      (i) => TextEditingController(text: widget.rows[i].consonants),
    );
    _vowel = List.generate(
      10,
      (i) => TextEditingController(text: widget.rows[i].vowelNote),
    );
  }

  @override
  void didUpdateWidget(covariant _PaoPhoneticBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      for (var i = 0; i < 10; i++) {
        _cons[i].text = widget.rows[i].consonants;
        _vowel[i].text = widget.rows[i].vowelNote;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _cons) {
      c.dispose();
    }
    for (final c in _vowel) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: 10,
      itemBuilder: (ctx, i) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Text('$i')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${l10n.paoPhoneticConsonantsLabel} · $i',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        upsertPaoPhonetic(
                          widget.db,
                          digit: i,
                          consonants: _cons[i].text,
                          vowelNote: _vowel[i].text,
                        );
                        widget.onRowSaved();
                      },
                      child: Text(l10n.paoPhoneticSaveRow),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cons[i],
                  decoration: InputDecoration(
                    labelText: l10n.paoPhoneticConsonantsLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _vowel[i],
                  decoration: InputDecoration(
                    labelText: l10n.paoPhoneticVowelNoteLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// El diálogo ya vació la clavija en BD y borró archivos; no volver a hacer upsert.
class _PaoEditPegCleared {}

class _PaoEditResult {
  const _PaoEditResult({
    required this.person,
    required this.action,
    required this.object,
    required this.imageRel,
    required this.personImageRel,
    required this.personImageRel2,
    required this.objectImageRel,
    required this.objectImageRel2,
  });
  final String person;
  final String action;
  final String object;
  final String imageRel;
  final String personImageRel;
  final String personImageRel2;
  final String objectImageRel;
  final String objectImageRel2;
}

class _PaoEditDialog extends StatefulWidget {
  const _PaoEditDialog({required this.db, required this.row});

  final Database db;
  final PaoStandardRow row;

  @override
  State<_PaoEditDialog> createState() => _PaoEditDialogState();
}

class _PaoEditDialogState extends State<_PaoEditDialog> {
  late TextEditingController _pCtrl;
  late TextEditingController _aCtrl;
  late TextEditingController _oCtrl;
  late String _imageRel;
  late String _personImageRel;
  late String _personImageRel2;
  late String _objectImageRel;
  late String _objectImageRel2;
  /// Ranura para Ctrl+V / drop global del diálogo: `code`, `p1`, `p2`, `o1`, `o2`.
  String _pasteTargetSlot = 'code';

  @override
  void initState() {
    super.initState();
    _pCtrl = TextEditingController(text: widget.row.person);
    _aCtrl = TextEditingController(text: widget.row.action);
    _oCtrl = TextEditingController(text: widget.row.object);
    _imageRel = widget.row.imageRel;
    _personImageRel = widget.row.personImageRel;
    _personImageRel2 = widget.row.personImageRel2;
    _objectImageRel = widget.row.objectImageRel;
    _objectImageRel2 = widget.row.objectImageRel2;
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

  bool _hardwareKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    if (e.logicalKey != LogicalKeyboardKey.keyV) return false;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final meta = pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    if (!ctrl && !meta) return false;
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return false;
    if (_lbFocusInEditableText()) return false;
    _pasteToSlot(_pasteTargetSlot);
    return true;
  }

  void _applyRelForSlot(String slot, String rel) {
    switch (slot) {
      case 'code':
        _imageRel = rel;
        break;
      case 'p1':
        _personImageRel = rel;
        break;
      case 'p2':
        _personImageRel2 = rel;
        break;
      case 'o1':
        _objectImageRel = rel;
        break;
      case 'o2':
        _objectImageRel2 = rel;
        break;
      default:
        break;
    }
  }

  Future<void> _pasteToSlot(String slot) async {
    final l10n = AppLocalizations.of(context)!;
    final got = await readFirstImageFromSystemClipboard();
    if (got == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarClipboardNoImage)),
      );
      return;
    }
    String? rel;
    if (slot == 'code') {
      rel = paoWriteBytesToSlot(widget.row.code, got.bytes, got.ext);
    } else {
      rel = paoWriteBytesToSlotSuffix(widget.row.code, got.bytes, got.ext, slot);
    }
    if (!mounted) return;
    if (rel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarCouldNotSaveImage)),
      );
      return;
    }
    setState(() => _applyRelForSlot(slot, rel!));
  }

  Future<void> _onDropForSlot(DropDoneDetails details, String slot) async {
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
      String? rel;
      if (slot == 'code') {
        rel = paoCopyPathToSlot(widget.row.code, path);
      } else {
        rel = paoCopyPathToSlotSuffix(widget.row.code, path, slot);
      }
      if (rel != null) {
        if (!mounted) return;
        setState(() => _applyRelForSlot(slot, rel!));
        return;
      }
    }
  }

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context)!;
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
        SnackBar(content: Text(l10n.paoSnackbarCouldNotCopyImage)),
      );
      return;
    }
    setState(() => _imageRel = rel);
  }

  Future<void> _pickSlot(String suffix) async {
    final l10n = AppLocalizations.of(context)!;
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );
    if (r == null || r.files.isEmpty) return;
    final path = r.files.single.path;
    if (path == null || path.isEmpty) return;
    final rel = paoCopyPathToSlotSuffix(widget.row.code, path, suffix);
    if (!mounted) return;
    if (rel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paoSnackbarCouldNotCopyImage)),
      );
      return;
    }
    setState(() {
      switch (suffix) {
        case 'p1':
          _personImageRel = rel;
          break;
        case 'p2':
          _personImageRel2 = rel;
          break;
        case 'o1':
          _objectImageRel = rel;
          break;
        case 'o2':
          _objectImageRel2 = rel;
          break;
      }
    });
  }

  Widget _imageSlot({
    required AppLocalizations l10n,
    required String slotKey,
    required String title,
    required String rel,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final imgFile = paoAbsFileForRel(rel);
    final cs = Theme.of(context).colorScheme;
    Widget col = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() => _pasteTargetSlot = slotKey);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleSmall),
              ),
              if (_pasteTargetSlot == slotKey)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.near_me, size: 16, color: cs.primary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (imgFile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: _kPaoImagePreviewDp,
              height: _kPaoImagePreviewDp,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: Image.file(
                imgFile,
                fit: BoxFit.contain,
                width: _kPaoImagePreviewDp,
                height: _kPaoImagePreviewDp,
                errorBuilder: (context, error, stackTrace) =>
                    Text(l10n.paoEditImageLoadError),
              ),
            ),
          ),
        Text(
          rel.isEmpty ? l10n.paoEditNoImageOptional : 'assets/$rel',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.tonalIcon(
              onPressed: onPick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.paoEditChooseImage),
            ),
            IconButton(
              tooltip: l10n.paoEditPasteImageTooltip,
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() => _pasteTargetSlot = slotKey);
                _pasteToSlot(slotKey);
              },
              icon: const Icon(Icons.content_paste_go_outlined),
            ),
            if (rel.isNotEmpty)
              TextButton(onPressed: onClear, child: Text(l10n.paoEditRemoveImage)),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
    if (_paoUseDesktopDrop()) {
      col = DropTarget(
        onDragDone: (d) => _onDropForSlot(d, slotKey),
        child: col,
      );
    }
    return col;
  }

  void _showExercisePreview() {
    final l10n = AppLocalizations.of(context)!;
    final row = PaoStandardRow(
      code: widget.row.code,
      person: _pCtrl.text,
      action: _aCtrl.text,
      object: _oCtrl.text,
      imageRel: _imageRel,
      personImageRel: _personImageRel,
      personImageRel2: _personImageRel2,
      objectImageRel: _objectImageRel,
      objectImageRel2: _objectImageRel2,
      updatedAt: widget.row.updatedAt,
    );
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.88;
        final maxW = min(560.0, MediaQuery.sizeOf(ctx).width - 32);
        return Dialog(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: maxW,
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.paoEditPreviewExerciseTitle,
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                        tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: PaoExercisePreviewContent(row: row),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletePeg() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.paoEditDeletePegConfirmTitle),
        content: Text(l10n.paoEditDeletePegConfirmBody),
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
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.paoEditDeletePegButton),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    deletePaoRelAssetFiles([
      _imageRel,
      _personImageRel,
      _personImageRel2,
      _objectImageRel,
      _objectImageRel2,
    ]);
    upsertPaoStandard(
      widget.db,
      code: widget.row.code,
      person: '',
      action: '',
      object: '',
      imageRel: '',
      personImageRel: '',
      personImageRel2: '',
      objectImageRel: '',
      objectImageRel2: '',
    );
    if (!mounted) return;
    Navigator.pop(context, _PaoEditPegCleared());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final codeLabel = PaoStandardRow.formatCode(widget.row.code);
    final tier = paoTierForCode(widget.row.code);
    final codeImgHint = switch (tier) {
      PaoCodeTier.digit => l10n.paoEditCodeImageHintDigit,
      PaoCodeTier.triple => l10n.paoEditCodeImageHintTriple,
      _ => l10n.paoEditCodeImageHintPair,
    };
    Widget inner = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            codeImgHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _imageSlot(
            l10n: l10n,
            slotKey: 'code',
            title: l10n.paoFieldCode,
            rel: _imageRel,
            onPick: _pickFile,
            onClear: () => setState(() => _imageRel = ''),
          ),
          TextField(
            controller: _pCtrl,
            decoration: InputDecoration(labelText: l10n.paoFieldPerson),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          _imageSlot(
            l10n: l10n,
            slotKey: 'p1',
            title: l10n.paoEditPersonImage1,
            rel: _personImageRel,
            onPick: () => _pickSlot('p1'),
            onClear: () => setState(() => _personImageRel = ''),
          ),
          _imageSlot(
            l10n: l10n,
            slotKey: 'p2',
            title: l10n.paoEditPersonImage2,
            rel: _personImageRel2,
            onPick: () => _pickSlot('p2'),
            onClear: () => setState(() => _personImageRel2 = ''),
          ),
          TextField(
            controller: _aCtrl,
            decoration: InputDecoration(labelText: l10n.paoFieldAction),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _oCtrl,
            decoration: InputDecoration(labelText: l10n.paoFieldObject),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          _imageSlot(
            l10n: l10n,
            slotKey: 'o1',
            title: l10n.paoEditObjectImage1,
            rel: _objectImageRel,
            onPick: () => _pickSlot('o1'),
            onClear: () => setState(() => _objectImageRel = ''),
          ),
          _imageSlot(
            l10n: l10n,
            slotKey: 'o2',
            title: l10n.paoEditObjectImage2,
            rel: _objectImageRel2,
            onPick: () => _pickSlot('o2'),
            onClear: () => setState(() => _objectImageRel2 = ''),
          ),
        ],
      ),
    );
    Widget dialog = AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l10n.paoEditDialogTitle(codeLabel))),
          IconButton(
            icon: const Icon(Icons.preview_outlined),
            tooltip: l10n.paoEditPreviewExerciseTooltip,
            onPressed: _showExercisePreview,
          ),
        ],
      ),
      content: inner,
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _confirmDeletePeg,
          child: Text(l10n.paoEditDeletePegButton),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
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
                personImageRel: _personImageRel,
                personImageRel2: _personImageRel2,
                objectImageRel: _objectImageRel,
                objectImageRel2: _objectImageRel2,
              ),
            );
          },
          child: Text(l10n.locusEditorSave),
        ),
      ],
    );
    if (_paoUseDesktopDrop()) {
      dialog = DropTarget(
        onDragDone: (d) => _onDropForSlot(d, _pasteTargetSlot),
        child: dialog,
      );
    }
    return dialog;
  }
}
