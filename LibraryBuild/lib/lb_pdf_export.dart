import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import 'library_build.dart';
import 'node_card_reader_page.dart';

enum _NodeReaderPickKind { object, parcour }

/// Claves `parentKey` distintas de los object, ordenadas; `''` al final = sin padre.
List<String> _sortedObjectParentKeys(List<sql.Row> objects) {
  final parents = <String>{};
  var hasOrphans = false;
  for (final r in objects) {
    final p = r['parentKey']?.toString().trim() ?? '';
    if (p.isEmpty) {
      hasOrphans = true;
    } else {
      parents.add(p);
    }
  }
  final out = parents.toList()..sort();
  if (hasOrphans) {
    out.add('');
  }
  return out;
}

List<sql.Row> _objectsUnderParent(List<sql.Row> all, String parent) {
  return all.where((r) {
    final p = r['parentKey']?.toString().trim() ?? '';
    if (parent.isEmpty) {
      return p.isEmpty;
    }
    return p == parent;
  }).toList();
}

/// Etiqueta para el paso 1 (parcour / nivel LN).
String _parentStepLabel(sql.Database db, String parentKey) {
  if (parentKey.isEmpty) {
    return '(sin parentKey)';
  }
  final rows = db.select(
    'SELECT title FROM entries WHERE key = ? LIMIT 1',
    [parentKey],
  );
  if (rows.isEmpty) {
    return parentKey;
  }
  final title = (rows.first['title'] as String?)?.trim();
  if (title != null && title.isNotEmpty) {
    return '$parentKey — $title';
  }
  return parentKey;
}

Map<String, String> _parentLabelsForKeys(sql.Database db, List<String> keys) {
  final m = <String, String>{};
  for (final pk in keys) {
    if (pk.isEmpty) {
      m[''] = '(sin parentKey)';
    } else {
      m[pk] = _parentStepLabel(db, pk);
    }
  }
  return m;
}

/// Exporta un PDF vía diálogo de impresión / “Guardar como PDF” (Windows).
class LbPdfExport {
  LbPdfExport._();

  static Future<void> previewObjectPdf(sql.Database db, String entryKey) async {
    ensureLibrarySchema(db);
    final rows = db.select(
      'SELECT key, parentKey, seq, title, cognitiveRole, body_text, '
      'last_reviewed_at, next_review_at, memory_strength, stability_days, recall_score, '
      'review_count, success_count, failure_count, spatial_turn FROM entries WHERE key = ?',
      [entryKey],
    );
    if (rows.isEmpty) {
      throw StateError('No existe la clave: $entryKey');
    }
    final r = rows.first;
    final title = (r['title'] as String?)?.trim().isNotEmpty == true
        ? (r['title'] as String).trim()
        : entryKey;
    final meta = _metaLines(r);
    final bodyPlain = _flattenBody(r['body_text'] as String?);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text(title)),
          pw.Text('key: $entryKey', style: pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 8),
          pw.Text(meta, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 16),
          pw.Text(bodyPlain, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static Future<void> previewParcourPdf(sql.Database db, String parcourKey) async {
    ensureLibrarySchema(db);
    final head = db.select(
      'SELECT key, title, cognitiveRole FROM entries WHERE key = ?',
      [parcourKey],
    );
    if (head.isEmpty) {
      throw StateError('No existe parcour: $parcourKey');
    }
    final role = normalizeCognitiveRole(head.first['cognitiveRole']);
    if (role != 'parcour') {
      throw StateError('La clave no es un parcour: $parcourKey');
    }

    final title = (head.first['title'] as String?)?.trim().isNotEmpty == true
        ? (head.first['title'] as String).trim()
        : parcourKey;

    final objects = db.select('''
WITH RECURSIVE sub AS (
  SELECT key, parentKey, title, body_text, seq, cognitiveRole, 1 AS depth
  FROM entries WHERE key = ?
  UNION ALL
  SELECT e.key, e.parentKey, e.title, e.body_text, e.seq, e.cognitiveRole, sub.depth + 1
  FROM entries e INNER JOIN sub ON e.parentKey = sub.key
)
SELECT key, title, body_text, seq FROM sub WHERE cognitiveRole = 'object'
ORDER BY seq ASC, key ASC
''', [parcourKey]);

    final buf = StringBuffer();
    for (var i = 0; i < objects.length; i++) {
      final o = objects[i];
      final k = o['key'] as String;
      final ot = (o['title'] as String?)?.trim().isNotEmpty == true
          ? (o['title'] as String).trim()
          : k;
      buf.writeln('${i + 1}. $ot');
      buf.writeln('   key: $k');
      buf.writeln(_flattenBody(o['body_text'] as String?));
      buf.writeln();
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Parcour: $title')),
          pw.Text('key: $parcourKey', style: pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 8),
          pw.Text(
            'Objetos en el subárbol: ${objects.length}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(buf.toString(), style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static String _metaLines(sql.Row r) {
    final parts = <String>[
      'parentKey: ${r['parentKey']}',
      'seq: ${r['seq']}',
      'cognitiveRole: ${r['cognitiveRole']}',
      'last_reviewed_at: ${r['last_reviewed_at']}',
      'next_review_at: ${r['next_review_at']}',
      'memory_strength: ${r['memory_strength']}',
      'stability_days: ${r['stability_days']}',
      'recall_score: ${r['recall_score']}',
      'review_count: ${r['review_count']}',
      'success_count: ${r['success_count']}',
      'failure_count: ${r['failure_count']}',
      'spatial_turn: ${r['spatial_turn']}',
    ];
    return parts.join('\n');
  }

  static String _flattenBody(String? raw) {
    final blocks = parseBody(raw);
    if (blocks.isEmpty) return raw?.trim().isNotEmpty == true ? raw!.trim() : '—';
    final buf = StringBuffer();
    for (final b in blocks) {
      if (shouldOmitFromLocusReadingExport(b)) continue;
      final t = (b['type'] ?? 'p').toString();
      if (t == 'img') {
        buf.writeln('[imagen: ${b['src']}]');
      } else if (t == 'link') {
        buf.writeln('[enlace: ${b['text']} → ${b['key']}]');
      } else {
        buf.writeln((b['text'] ?? '').toString());
      }
    }
    return buf.toString().trim();
  }

  static Future<void> showObjectPdfDialog(BuildContext context, sql.Database db) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PDF de nodo (objeto u otro)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Clave del nodo',
            hintText: 'ej. L2_O03',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generar PDF')),
        ],
      ),
    );
    final key = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || !context.mounted) return;
    if (key.isEmpty) return;
    try {
      await previewObjectPdf(db, key);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  static Future<void> showParcourPdfDialog(BuildContext context, sql.Database db) async {
    final rows = db.select(
      "SELECT key, title FROM entries WHERE parentKey = 'PARCOUR_MAIN' ORDER BY seq ASC",
    );
    if (rows.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay parcours bajo PARCOUR_MAIN.')),
        );
      }
      return;
    }
    var selected = rows.first['key'] as String;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('PDF de un parcour'),
          content: DropdownButtonFormField<String>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Parcour'),
            items: rows
                .map(
                  (r) => DropdownMenuItem<String>(
                    value: r['key'] as String,
                    child: Text(
                      '${r['key']} — ${((r['title'] as String?)?.trim().isNotEmpty == true) ? (r['title'] as String).trim() : r['key']}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setSt(() => selected = v ?? selected),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generar PDF')),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await previewParcourPdf(db, selected);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  static Future<void> showNodeCardKeyDialog(BuildContext context, sql.Database db) async {
    ensureLibrarySchema(db);
    final parcours = db.select(
      "SELECT key, title, parentKey FROM entries WHERE cognitiveRole = 'parcour' "
      'ORDER BY parentKey, seq, key',
    );
    final objects = db.select(
      "SELECT key, title, parentKey FROM entries WHERE cognitiveRole = 'object' "
      'ORDER BY parentKey, seq, key',
    );

    final objectParentKeys = _sortedObjectParentKeys(objects);
    final parentLabels =
        objectParentKeys.isNotEmpty ? _parentLabelsForKeys(db, objectParentKeys) : <String, String>{};

    var kind = _NodeReaderPickKind.object;
    String? selectedKey;
    var selectedObjectParent = objectParentKeys.isNotEmpty ? objectParentKeys.first : '';

    void syncObjectSelectionFromParent() {
      if (objectParentKeys.isEmpty) {
        selectedKey = null;
        return;
      }
      if (!objectParentKeys.contains(selectedObjectParent)) {
        selectedObjectParent = objectParentKeys.first;
      }
      final sub = _objectsUnderParent(objects, selectedObjectParent);
      if (sub.isEmpty) {
        selectedKey = null;
      } else if (selectedKey == null ||
          !sub.any((r) => r['key']?.toString() == selectedKey)) {
        selectedKey = sub.first['key'] as String;
      }
    }

    if (objects.isNotEmpty) {
      syncObjectSelectionFromParent();
    } else if (parcours.isNotEmpty) {
      kind = _NodeReaderPickKind.parcour;
      selectedKey = parcours.first['key'] as String;
    }

    String objectShortLabel(sql.Row r) {
      final k = r['key']?.toString() ?? '';
      final t = (r['title'] as String?)?.trim();
      final title = (t != null && t.isNotEmpty) ? t : k;
      return '$k · $title';
    }

    String parcourLabel(sql.Row r) {
      final k = r['key']?.toString() ?? '';
      final t = (r['title'] as String?)?.trim();
      final title = (t != null && t.isNotEmpty) ? t : k;
      final p = (r['parentKey'] ?? '—').toString();
      return '$k — $title (parent: $p)';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final list = kind == _NodeReaderPickKind.parcour ? parcours : objects;
          if (kind == _NodeReaderPickKind.parcour) {
            if (list.isEmpty) {
              selectedKey = null;
            } else if (selectedKey == null ||
                !list.any((r) => r['key']?.toString() == selectedKey)) {
              selectedKey = list.first['key'] as String;
            }
          } else {
            syncObjectSelectionFromParent();
          }

          return AlertDialog(
            title: const Text('Lector de nodo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<_NodeReaderPickKind>(
                    segments: const [
                      ButtonSegment<_NodeReaderPickKind>(
                        value: _NodeReaderPickKind.object,
                        label: Text('Object'),
                        icon: Icon(Icons.crop_square_outlined, size: 18),
                      ),
                      ButtonSegment<_NodeReaderPickKind>(
                        value: _NodeReaderPickKind.parcour,
                        label: Text('Parcour'),
                        icon: Icon(Icons.route_outlined, size: 18),
                      ),
                    ],
                    selected: {kind},
                    onSelectionChanged: (s) {
                      setSt(() {
                        kind = s.first;
                        if (kind == _NodeReaderPickKind.parcour) {
                          selectedKey = parcours.isNotEmpty
                              ? parcours.first['key'] as String
                              : null;
                        } else {
                          if (objectParentKeys.isNotEmpty) {
                            selectedObjectParent = objectParentKeys.first;
                          }
                          syncObjectSelectionFromParent();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (kind == _NodeReaderPickKind.object) ...[
                    if (objects.isEmpty)
                      Text(
                        'No hay objetos en la base de datos.',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: objectParentKeys.contains(selectedObjectParent)
                            ? selectedObjectParent
                            : objectParentKeys.first,
                        decoration: const InputDecoration(
                          labelText: '1 · Parcour / nivel (LN)',
                          border: OutlineInputBorder(),
                          helperText: 'Elige el contenedor; luego el objeto.',
                        ),
                        isExpanded: true,
                        items: [
                          for (final pk in objectParentKeys)
                            DropdownMenuItem<String>(
                              value: pk,
                              child: Text(
                                parentLabels[pk] ?? pk,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          setSt(() {
                            selectedObjectParent = v ?? '';
                            syncObjectSelectionFromParent();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      () {
                        final parentVal = objectParentKeys.contains(
                                selectedObjectParent)
                            ? selectedObjectParent
                            : objectParentKeys.first;
                        final sub = _objectsUnderParent(objects, parentVal);
                        if (sub.isEmpty) {
                          return Text(
                            'Ningún objeto bajo este padre.',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(ctx).colorScheme.error,
                                ),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          value: selectedKey != null &&
                                  sub.any(
                                      (r) => r['key']?.toString() == selectedKey)
                              ? selectedKey
                              : sub.first['key'] as String,
                          decoration: const InputDecoration(
                            labelText: '2 · Objeto (Oxx)',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: [
                            for (final r in sub)
                              DropdownMenuItem<String>(
                                value: r['key'] as String,
                                child: Text(
                                  objectShortLabel(r),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => setSt(() => selectedKey = v),
                        );
                      }(),
                    ],
                  ] else ...[
                    if (list.isEmpty)
                      Text(
                        'No hay parcours en la base de datos.',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedKey,
                        decoration: const InputDecoration(
                          labelText: 'Parcour',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: [
                          for (final r in list)
                            DropdownMenuItem<String>(
                              value: r['key'] as String,
                              child: Text(
                                parcourLabel(r),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setSt(() => selectedKey = v),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: selectedKey == null || selectedKey!.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: const Text('Abrir'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !context.mounted) return;
    final key = selectedKey?.trim();
    if (key == null || key.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NodeCardReaderPage(db: db, entryKey: key),
      ),
    );
  }
}
