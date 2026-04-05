import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import 'library_build.dart'
    show ensureLibrarySchema, writeViewerCurrentJson, kCognitiveRoles, normalizeCognitiveRole;

const _openKeyPath = r'C:\Alexandria\data\bridge\open_key.txt';

const _kCognitiveRoleLabels = <String, String>{
  'realm': 'Realm',
  'parcour': 'Parcour',
  'room': 'Room',
  'object': 'Object',
};

/// Editor de contenido por locus (bloques `p` y `link`). Reemplaza el panel inferior de main.
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

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  @override
  void dispose() {
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
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

  /// Compatible con legacy: null, texto plano, array JSON (p/link/img → p con marcador).
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
        final t = (m['t'] ?? m['type'] ?? 'p').toString();
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
          out.add(
            _BlockDraft.p(
              text: src.isNotEmpty ? '[img: $src]' : '[img]',
            ),
          );
          continue;
        }
        out.add(_BlockDraft.p(text: (m['text'] ?? '').toString()));
      }
      if (out.isEmpty) {
        return [_BlockDraft.p(text: raw.trim())];
      }
      return out;
    } catch (_) {
      return [_BlockDraft.p(text: raw.trim())];
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

  void _removeAt(int i) {
    setState(() {
      final b = _blocks.removeAt(i);
      b.dispose();
    });
  }

  void _moveUp(int i) {
    if (i <= 0) return;
    setState(() {
      final b = _blocks.removeAt(i);
      _blocks.insert(i - 1, b);
    });
  }

  void _moveDown(int i) {
    if (i >= _blocks.length - 1) return;
    setState(() {
      final b = _blocks.removeAt(i);
      _blocks.insert(i + 1, b);
    });
  }

  Future<void> _save() async {
    final payload = <Map<String, dynamic>>[];
    for (final b in _blocks) {
      if (b.isLink) {
        final k = b.linkKeyCtrl.text.trim();
        final t = b.textCtrl.text.trim();
        if (k.isEmpty) continue;
        payload.add({'type': 'link', 'key': k, 'text': t});
      } else {
        final t = b.textCtrl.text.trim();
        if (t.isEmpty) continue;
        payload.add({'type': 'p', 'text': t});
      }
    }

    final String? stored =
        payload.isEmpty ? null : jsonEncode(payload);

    widget.db.execute(
      'UPDATE entries SET body_text = ?, cognitiveRole = ? WHERE key = ?',
      [stored, _cognitiveRole, widget.entryKey],
    );

    try {
      final f = File(_openKeyPath);
      if (f.existsSync()) {
        final openKey = f.readAsStringSync().trim();
        if (openKey.isNotEmpty && openKey == widget.entryKey) {
          ensureLibrarySchema(widget.db);
          writeViewerCurrentJson(widget.db, widget.entryKey);
        }
      }
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardado')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LocusEditor · ${widget.entryKey}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('GUARDAR'),
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
                labelText: 'Rol cognitivo (solo LB; GK no lee)',
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
                  label: const Text('Párrafo'),
                ),
                OutlinedButton.icon(
                  onPressed: _addLink,
                  icon: const Icon(Icons.link),
                  label: const Text('Enlace'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _blocks.isEmpty
                ? const Center(
                    child: Text(
                      'Sin bloques. Añade párrafo o enlace.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _blocks.length,
                    itemBuilder: (context, i) {
                      final b = _blocks[i];
                      final last = i == _blocks.length - 1;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      b.isLink ? 'link' : 'p',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward),
                                    tooltip: 'Subir',
                                    onPressed:
                                        i == 0 ? null : () => _moveUp(i),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward),
                                    tooltip: 'Bajar',
                                    onPressed:
                                        last ? null : () => _moveDown(i),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Eliminar',
                                    onPressed: () => _removeAt(i),
                                  ),
                                ],
                              ),
                              if (b.isLink) ...[
                                TextField(
                                  controller: b.linkKeyCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'KEY destino',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              TextField(
                                controller: b.textCtrl,
                                minLines: b.isLink ? 2 : 3,
                                maxLines: 8,
                                decoration: InputDecoration(
                                  labelText: b.isLink
                                      ? 'Texto visible del enlace'
                                      : 'Texto',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BlockDraft {
  _BlockDraft._({
    required this.isLink,
    required this.textCtrl,
    TextEditingController? linkKeyCtrl,
  }) : _linkKeyCtrl = linkKeyCtrl;

  factory _BlockDraft.p({String text = ''}) {
    return _BlockDraft._(
      isLink: false,
      textCtrl: TextEditingController(text: text),
      linkKeyCtrl: null,
    );
  }

  factory _BlockDraft.link({String destKey = '', String text = ''}) {
    return _BlockDraft._(
      isLink: true,
      textCtrl: TextEditingController(text: text),
      linkKeyCtrl: TextEditingController(text: destKey),
    );
  }

  final bool isLink;
  final TextEditingController textCtrl;
  final TextEditingController? _linkKeyCtrl;

  TextEditingController get linkKeyCtrl {
    final k = _linkKeyCtrl;
    if (!isLink || k == null) {
      throw StateError('not link');
    }
    return k;
  }

  void dispose() {
    textCtrl.dispose();
    _linkKeyCtrl?.dispose();
  }
}
