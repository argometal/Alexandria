import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import 'alexandria_paths.dart';
import 'library_build.dart';

/// Visor tipo tarjeta con toda la fila `entries` + cuerpo parseado (búsquedas y menú).
class NodeCardReaderPage extends StatelessWidget {
  const NodeCardReaderPage({
    super.key,
    required this.db,
    required this.entryKey,
  });

  final sql.Database db;
  final String entryKey;

  @override
  Widget build(BuildContext context) {
    ensureLibrarySchema(db);
    final rows = db.select(
      'SELECT key, parentKey, seq, title, cognitiveRole, body_text, '
      'last_reviewed_at, next_review_at, memory_strength, stability_days, recall_score, '
      'review_count, success_count, failure_count, last_review_grade, spatial_turn '
      'FROM entries WHERE key = ?',
      [entryKey],
    );
    if (rows.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nodo')),
        body: Center(
          child: Text('No existe la clave: $entryKey'),
        ),
      );
    }
    final r = rows.first;
    final bodyText = r['body_text'] as String?;
    final blocks = parseBody(bodyText);
    final cs = Theme.of(context).colorScheme;
    final titleText = (r['title'] as String?)?.trim().isNotEmpty == true
        ? (r['title'] as String).trim()
        : entryKey;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Metadatos y estadísticas (FSRS)',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        width: math.min(
          380,
          math.max(280.0, MediaQuery.sizeOf(context).width * 0.88),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Entrada · FSRS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  entryKey,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                  children: _metaRows(context, r),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Contenido',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.primary),
          ),
          const SizedBox(height: 8),
          ..._bodyBlocks(context, blocks, entryKey),
        ],
      ),
    );
  }

  List<Widget> _metaRows(BuildContext context, sql.Row r) {
    String v(Object? o) {
      if (o == null) return '—';
      final s = o.toString().trim();
      return s.isEmpty ? '—' : s;
    }

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 132,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return [
      row('key', v(r['key'])),
      row('parentKey', v(r['parentKey'])),
      row('seq', v(r['seq'])),
      row('title', v(r['title'])),
      row('cognitiveRole', v(r['cognitiveRole'])),
      row('last_reviewed_at', v(r['last_reviewed_at'])),
      row('next_review_at', v(r['next_review_at'])),
      row('memory_strength', v(r['memory_strength'])),
      row('stability_days', v(r['stability_days'])),
      row('recall_score', v(r['recall_score'])),
      row('review_count', v(r['review_count'])),
      row('success_count', v(r['success_count'])),
      row('failure_count', v(r['failure_count'])),
      row('last_review_grade', v(r['last_review_grade'])),
      row('spatial_turn', v(r['spatial_turn'])),
    ];
  }

  List<Widget> _bodyBlocks(
    BuildContext context,
    List<Map<String, dynamic>> blocks,
    String key,
  ) {
    if (blocks.isEmpty) {
      return [
        Text(
          'Sin bloques en body_text.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ];
    }
    final out = <Widget>[];
    final sep = Platform.pathSeparator;
    final baseDir = Directory('${AlexandriaPaths.assetsRoot}$sep$key');

    for (final b in blocks) {
      if (shouldOmitFromLocusReadingExport(b)) continue;
      final t = (b['type'] ?? 'p').toString();
      switch (t) {
        case 'img':
          final src = (b['src'] ?? '').toString();
          String? path;
          final direct = File(src);
          if (direct.existsSync()) {
            path = src;
          } else {
            final u = File('${baseDir.path}$sep$src');
            if (u.existsSync()) path = u.path;
          }
          out.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: path != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(path),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Text('[img] $src'),
                      ),
                    )
                  : Text('[img] $src (no encontrada)'),
            ),
          );
          break;
        case 'link':
          out.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('→ ${b['text']}  [${b['key']}]'),
            ),
          );
          break;
        case 'audio':
          out.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('[audio] ${b['src']}'),
            ),
          );
          break;
        case 'warp':
          out.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('[warp] ${b['text']} → ${b['key']}'),
            ),
          );
          break;
        case 'tag':
          out.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Chip(
                label: Text((b['text'] ?? '').toString()),
              ),
            ),
          );
          break;
        default:
          final kind = (b['textKind'] ?? 'text').toString();
          final text = (b['text'] ?? '').toString();
          out.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kind != 'text')
                    Text(
                      kind,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                    ),
                  SelectableText(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          );
      }
    }
    return out;
  }
}
