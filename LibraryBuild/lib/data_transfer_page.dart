import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'package:url_launcher/url_launcher.dart';

import 'alexandria_paths.dart';
import 'library_build.dart';

/// Puerto por defecto del servidor Node en `data-transfer/` (ver `lib/config.js`).
const int kDataTransferPort = 4020;

Uri _dataTransferBaseUri() => Uri.parse('http://127.0.0.1:$kDataTransferPort/');

/// Integración LibraryBuild ↔ `repo/data-transfer`: arranque del servidor, UI web e importación `out/` → locus.
class DataTransferPage extends StatefulWidget {
  const DataTransferPage({super.key, required this.db});

  final Database db;

  @override
  State<DataTransferPage> createState() => _DataTransferPageState();
}

enum _ImportSource { outDir, incomingDir }

class _DataTransferPageState extends State<DataTransferPage> {
  Process? _node;
  bool _serverReachable = false;
  String? _healthSummary;
  List<File> _outFiles = [];
  List<File> _incomingFiles = [];
  List<Map<String, Object?>> _objectRows = [];
  String? _selectedKey;
  String? _selectedFilePath;
  _ImportSource _importSource = _ImportSource.outDir;
  /// `true` = sustituye `body_text`; `false` = concatena bloques al JSON existente.
  bool _replaceBody = true;
  bool _busy = false;

  List<File> get _activeFileList =>
      _importSource == _ImportSource.outDir ? _outFiles : _incomingFiles;

  @override
  void initState() {
    super.initState();
    _reloadLists();
    _tickHealth();
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  void _syncSelectedFileToSource() {
    final list = _activeFileList;
    if (list.isEmpty) {
      _selectedFilePath = null;
      return;
    }
    if (_selectedFilePath != null &&
        list.any((f) => f.path == _selectedFilePath)) {
      return;
    }
    _selectedFilePath = list.first.path;
  }

  void _reloadLists() {
    ensureLibrarySchema(widget.db);
    final objs = widget.db.select(
      "SELECT key, title, parentKey FROM entries WHERE cognitiveRole = 'object' "
      'ORDER BY parentKey, seq, key',
    );
    final out = Directory('${AlexandriaPaths.dataTransferRoot}/out');
    final inc = Directory('${AlexandriaPaths.dataTransferRoot}/handoff/incoming');
    setState(() {
      _objectRows = objs;
      _selectedKey ??= objs.isNotEmpty ? objs.first['key']?.toString() : null;
      _outFiles = _listFilesSorted(out);
      _incomingFiles = _listFilesSorted(inc);
      _syncSelectedFileToSource();
      if (_selectedFilePath == null && _outFiles.isEmpty && _incomingFiles.isNotEmpty) {
        _importSource = _ImportSource.incomingDir;
        _syncSelectedFileToSource();
      }
    });
  }

  List<File> _listFilesSorted(Directory dir) {
    if (!dir.existsSync()) return [];
    final list = <File>[];
    for (final e in dir.listSync()) {
      if (e is File) list.add(e);
    }
    list.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return list;
  }

  Future<void> _tickHealth() async {
    try {
      final r = await http
          .get(Uri.parse('http://127.0.0.1:$kDataTransferPort/health'))
          .timeout(const Duration(seconds: 2));
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() {
          _serverReachable = true;
          _healthSummary = r.body.length > 200
              ? '${r.body.substring(0, 200)}…'
              : r.body;
        });
      } else {
        setState(() {
          _serverReachable = false;
          _healthSummary = 'HTTP ${r.statusCode}';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serverReachable = false;
        _healthSummary = null;
      });
    }
  }

  Future<void> _startServer() async {
    final script = File('${AlexandriaPaths.dataTransferRoot}/server.js');
    if (!script.existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No existe ${script.path}'),
        ),
      );
      return;
    }
    await _stopServer();
    await _tickHealth();
    if (_serverReachable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya hay un servidor en :4020 (externo u otro proceso)')),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      _node = await Process.start(
        'node',
        [script.path],
        workingDirectory: AlexandriaPaths.dataTransferRoot,
        mode: ProcessStartMode.normal,
      );
      _node!.stdout.listen((_) {});
      _node!.stderr.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await _tickHealth();
      if (mounted && !_serverReachable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Proceso node iniciado pero /health no responde. ¿Node en PATH?',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar node: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopServer() async {
    final p = _node;
    _node = null;
    if (p != null) {
      try {
        p.kill();
      } catch (_) {}
    }
    await _tickHealth();
  }

  Future<void> _openWebUi() async {
    final u = _dataTransferBaseUri();
    if (!await launchUrl(u, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir $u')),
      );
    }
  }

  /// Misma semántica que antes: JSON de lista tal cual si empieza por `[` válido; si no, un párrafo.
  String _bodyJsonFromImportedText(String raw) {
    final t = raw.trim();
    if (t.startsWith('[')) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is List) {
          return t;
        }
      } catch (_) {}
    }
    return jsonEncode([
      {'type': 'p', 'text': raw, 'textKind': 'text'},
    ]);
  }

  List<Map<String, dynamic>> _blocksFromImportRaw(String raw) {
    final t = raw.trim();
    if (t.startsWith('[')) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is List) {
          final out = <Map<String, dynamic>>[];
          for (final el in decoded) {
            if (el is Map) {
              out.add(Map<String, dynamic>.from(
                el.map((k, v) => MapEntry(k.toString(), v)),
              ));
            }
          }
          return out;
        }
      } catch (_) {}
    }
    return [
      {'type': 'p', 'text': raw, 'textKind': 'text'},
    ];
  }

  List<Map<String, dynamic>> _existingBlocks(String? bodyText) {
    if (bodyText == null || bodyText.trim().isEmpty) return [];
    try {
      final d = jsonDecode(bodyText);
      if (d is List) {
        final out = <Map<String, dynamic>>[];
        for (final el in d) {
          if (el is Map) {
            out.add(Map<String, dynamic>.from(
              el.map((k, v) => MapEntry(k.toString(), v)),
            ));
          }
        }
        return out;
      }
    } catch (_) {
      return [
        {'type': 'p', 'text': bodyText, 'textKind': 'text'},
      ];
    }
    return [];
  }

  String _mergeAppendBody(String? existingBody, String importedRaw) {
    final head = _existingBlocks(existingBody);
    final tail = _blocksFromImportRaw(importedRaw);
    return jsonEncode([...head, ...tail]);
  }

  Future<void> _importSelectedFile() async {
    final path = _selectedFilePath;
    final key = _selectedKey?.trim();
    if (path == null || key == null || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige archivo y locus destino.')),
      );
      return;
    }
    final f = File(path);
    if (!f.existsSync()) {
      _reloadLists();
      return;
    }
    setState(() => _busy = true);
    try {
      final raw = f.readAsStringSync(encoding: utf8);
      final String bodyText;
      if (_replaceBody) {
        bodyText = _bodyJsonFromImportedText(raw);
      } else {
        final rows = widget.db.select(
          'SELECT body_text FROM entries WHERE key = ?',
          [key],
        );
        final existing =
            rows.isEmpty ? null : rows.first['body_text'] as String?;
        bodyText = _mergeAppendBody(existing, raw);
      }
      widget.db.execute(
        'UPDATE entries SET body_text = ? WHERE key = ?',
        [bodyText, key],
      );
      runLibraryBuild();
      if (!mounted) return;
      final mode = _replaceBody ? 'Reemplazo' : 'Añadido al final';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$mode · $key (${f.uri.pathSegments.last})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  bool get _canImport =>
      !_busy &&
      _objectRows.isNotEmpty &&
      _selectedFilePath != null &&
      _activeFileList.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final srcLabel = _importSource == _ImportSource.outDir
        ? 'out/'
        : 'handoff/incoming/';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data transfer → LibraryBuild'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar archivos y estado',
            onPressed: _busy
                ? null
                : () {
                    _reloadLists();
                    _tickHealth();
                  },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Servidor en repo: ${AlexandriaPaths.dataTransferRoot}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _startServer,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar servidor (node)'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _stopServer,
                icon: const Icon(Icons.stop),
                label: const Text('Detener proceso LB'),
              ),
              FilledButton.tonalIcon(
                onPressed: _openWebUi,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Abrir UI web (:4020)'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _serverReachable ? Icons.check_circle : Icons.cloud_off,
                color: _serverReachable ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _serverReachable
                      ? 'Servidor accesible en http://127.0.0.1:$kDataTransferPort'
                      : 'Sin respuesta en /health (inicia node o usa solo import local)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (_healthSummary != null && _serverReachable) ...[
            const SizedBox(height: 8),
            SelectableText(
              _healthSummary!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const Divider(height: 32),
          Text(
            'Importar archivo a un locus',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Origen: $srcLabel · Si el contenido empieza por [ se interpreta como JSON de bloques; '
            'si no, se crea un único párrafo. Modo «Añadir» concatena bloques al body existente.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (_objectRows.isEmpty)
            Text(
              'No hay entradas object en la DB.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Locus destino (object)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedKey != null &&
                          _objectRows
                              .any((r) => r['key']?.toString() == _selectedKey)
                      ? _selectedKey
                      : null,
                  items: [
                    for (final r in _objectRows)
                      DropdownMenuItem<String>(
                        value: r['key']?.toString(),
                        child: Text(
                          '${r['key']} — ${(r['title'] ?? '').toString().trim()} '
                          '(parent: ${(r['parentKey'] ?? '—').toString()})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _selectedKey = v),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            'Carpeta de archivos',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<_ImportSource>(
            segments: const [
              ButtonSegment<_ImportSource>(
                value: _ImportSource.outDir,
                label: Text('out/'),
                icon: Icon(Icons.outbox_outlined, size: 18),
              ),
              ButtonSegment<_ImportSource>(
                value: _ImportSource.incomingDir,
                label: Text('incoming/'),
                icon: Icon(Icons.move_to_inbox_outlined, size: 18),
              ),
            ],
            selected: {_importSource},
            onSelectionChanged: _busy
                ? null
                : (s) {
                    setState(() {
                      _importSource = s.first;
                      _syncSelectedFileToSource();
                    });
                  },
          ),
          const SizedBox(height: 8),
          Text(
            'out/: ${_outFiles.length} · incoming/: ${_incomingFiles.length}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          if (_activeFileList.isEmpty)
            Text(
              _importSource == _ImportSource.outDir
                  ? 'Carpeta out/ vacía. Usa la UI web, o cambia a incoming/, o copia ficheros en data-transfer/out/.'
                  : 'Carpeta handoff/incoming/ vacía. Copia aquí archivos o usa out/.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Archivo ($srcLabel)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedFilePath != null &&
                          _activeFileList.any((f) => f.path == _selectedFilePath)
                      ? _selectedFilePath
                      : null,
                  items: [
                    for (final f in _activeFileList)
                      DropdownMenuItem<String>(
                        value: f.path,
                        child: Text(
                          f.uri.pathSegments.last,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _selectedFilePath = v),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            'Modo de importación',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: true,
                label: const Text('Reemplazar body'),
                icon: const Icon(Icons.find_replace_outlined, size: 18),
              ),
              ButtonSegment<bool>(
                value: false,
                label: const Text('Añadir al final'),
                icon: const Icon(Icons.playlist_add_outlined, size: 18),
              ),
            ],
            selected: {_replaceBody},
            onSelectionChanged: _busy
                ? null
                : (s) => setState(() => _replaceBody = s.first),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: !_canImport ? null : _importSelectedFile,
            icon: const Icon(Icons.download_done),
            label: const Text('Importar al locus y runLibraryBuild'),
          ),
        ],
      ),
    );
  }
}
