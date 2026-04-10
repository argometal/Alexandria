import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../library_build.dart';
import 'study_utils.dart';

const double _kMinTouch = 44;

/// Estudio por parcour: solo bloques `hint` / `ridiculous_story`; objetos sin esos bloques se omiten.
class ParcourStudyPage extends StatefulWidget {
  const ParcourStudyPage({
    super.key,
    required this.db,
    required this.parcourKey,
  });

  final Database db;
  final String parcourKey;

  @override
  State<ParcourStudyPage> createState() => _ParcourStudyPageState();
}

class _ObjectStudyRow {
  _ObjectStudyRow({
    required this.key,
    required this.title,
    required this.bodyText,
  });

  final String key;
  final String title;
  final String? bodyText;
  List<bool> recalled = [];
}

class _ParcourStudyPageState extends State<ParcourStudyPage> {
  List<_ObjectStudyRow>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      ensureLibrarySchema(widget.db);
      final r = widget.db.select(
        'SELECT key, seq, title, body_text FROM entries WHERE parentKey = ? AND cognitiveRole = ? ORDER BY seq ASC',
        [widget.parcourKey, 'object'],
      );
      final list = <_ObjectStudyRow>[];
      for (final row in r) {
        final k = row['key']?.toString() ?? '';
        final body = row['body_text'] as String?;
        if (countEvaluableBlocks(body) == 0) continue;
        final title = (row['title'] as String?)?.trim();
        list.add(
          _ObjectStudyRow(
            key: k,
            title: (title != null && title.isNotEmpty) ? title : k,
            bodyText: body,
          ),
        );
      }
      for (final o in list) {
        final n = countEvaluableBlocks(o.bodyText);
        o.recalled = List<bool>.filled(n, false);
      }
      setState(() {
        _rows = list;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _rows = null;
      });
    }
  }

  List<Map<String, dynamic>> _evaluableBlocksParsed(String? body) {
    final blocks = parseBody(body);
    final out = <Map<String, dynamic>>[];
    for (final b in blocks) {
      if (b['type'] != 'p') continue;
      final tk = b['textKind']?.toString().toLowerCase().trim() ?? '';
      if (tk != 'hint' && tk != 'ridiculous_story') continue;
      out.add(b);
    }
    return out;
  }

  Future<void> _save(BuildContext context) async {
    final rows = _rows;
    if (rows == null || rows.isEmpty) return;

    ensureLibrarySchema(widget.db);
    final now = DateTime.now();
    var n = 0;
    for (final o in rows) {
      final idx = <int>[];
      for (var i = 0; i < o.recalled.length; i++) {
        if (o.recalled[i]) idx.add(i);
      }
      final total = countEvaluableBlocks(o.bodyText);
      if (total == 0) continue;
      final pct = computeRecallPct(o.bodyText, idx);
      applyLocusReviewOutcome(
        db: widget.db,
        locusKey: o.key,
        pct: pct,
        totalEvaluableBlocks: total,
        now: now,
      );
      n++;
    }

    try {
      runLibraryBuild();
    } catch (_) {}

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Guardado: $n locus actualizados')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study')),
        body: Center(child: Text(_error!)),
      );
    }

    final rows = _rows;
    if (rows == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (rows.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Ningún objeto bajo este parcour tiene bloques hint o ridiculous story.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Study · ${widget.parcourKey}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: rows.length,
              itemBuilder: (context, oi) {
                final o = rows[oi];
                final evalBlocks = _evaluableBlocksParsed(o.bodyText);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            o.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            o.key,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ),
                        for (var bi = 0; bi < evalBlocks.length; bi++)
                          CheckboxListTile(
                            value: o.recalled[bi],
                            onChanged: (v) {
                              setState(() => o.recalled[bi] = v ?? false);
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              (evalBlocks[bi]['text'] ?? '').toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              evalBlocks[bi]['textKind']?.toString() ?? '',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: _kMinTouch + 8,
                child: FilledButton(
                  onPressed: () => _save(context),
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
