import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import 'library_build.dart';

const _dbPath = r'C:\Alexandria\data\alexandria.db';
const _openKeyPath = r'C:\Alexandria\data\bridge\open_key.txt';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LbMinimalApp());
}

class LbMinimalApp extends StatelessWidget {
  const LbMinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LbHome(),
    );
  }
}

class LbHome extends StatefulWidget {
  const LbHome({super.key});

  @override
  State<LbHome> createState() => _LbHomeState();
}

class _LbHomeState extends State<LbHome> {
  Database? _db;
  String _currentParentKey = 'ROOT';
  final TextEditingController _titleController = TextEditingController();
  List<Map<String, Object?>> _rows = [];
  Timer? _viewerPoll;

  /// Última key para la que ya se ejecutó `runLibraryBuild()` (evita rebuild cada 2s).
  String? _lastProcessedOpenKey;

  /// Evita solapar `runLibraryBuild()` si dura más que el intervalo del timer.
  bool _libraryBuildRunning = false;

  /// Entry cuyo `body_text` se edita (icono notas en la fila).
  String? _bodyEditKey;
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _linkKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _openDbAndSchema();
    _syncParentFromOpenKey();
    _loadChildren();
    _viewerPoll = Timer.periodic(const Duration(seconds: 2), (_) {
      syncViewerFromOpenKey();
      _checkAndRunLibraryBuild();
    });
  }

  @override
  void dispose() {
    _viewerPoll?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    _linkKeyController.dispose();
    _db?.dispose();
    super.dispose();
  }

  void _openDbAndSchema() {
    _db = sqlite3.open(_dbPath);
    final d = _db!;

    d.execute('''
CREATE TABLE IF NOT EXISTS entries (
  key TEXT PRIMARY KEY,
  parentKey TEXT,
  seq INTEGER
)
''');

    final info = d.select('PRAGMA table_info(entries)');
    final names = info.map((r) => r['name'] as String).toList();
    if (!names.contains('title')) {
      d.execute('ALTER TABLE entries ADD COLUMN title TEXT');
    }
    if (!names.contains('body_text')) {
      d.execute('ALTER TABLE entries ADD COLUMN body_text TEXT');
    }
  }

  void _syncParentFromOpenKey() {
    try {
      final f = File(_openKeyPath);
      if (!f.existsSync()) return;
      final k = f.readAsStringSync().trim();
      if (k.isNotEmpty) {
        _currentParentKey = k;
      }
    } catch (_) {}
  }

  /// Cuando GK (u otro proceso) cambia `open_key.txt`, regenera snapshot + refresh para GateKeeper.
  void _checkAndRunLibraryBuild() {
    if (_libraryBuildRunning) return;
    try {
      final f = File(_openKeyPath);
      if (!f.existsSync()) return;
      final key = f.readAsStringSync().trim();
      if (key.isEmpty) return;
      if (key == _lastProcessedOpenKey) return;

      _libraryBuildRunning = true;
      try {
        runLibraryBuild();
        _lastProcessedOpenKey = key;
      } finally {
        _libraryBuildRunning = false;
      }
    } catch (_) {
      _libraryBuildRunning = false;
    }
  }

  void _writeOpenKey(String key) {
    final f = File(_openKeyPath);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(key);
  }

  void _loadChildren() {
    final d = _db;
    if (d == null) return;

    final result = d.select(
      'SELECT key, seq, title FROM entries WHERE parentKey = ? ORDER BY seq ASC',
      [_currentParentKey],
    );

    setState(() {
      _rows = result
          .map((row) => {
                'key': row['key'],
                'seq': row['seq'],
                'title': row['title'],
              })
          .toList();
    });
  }

  String _displayLabel(Map<String, Object?> row) {
    final t = row['title']?.toString().trim();
    if (t != null && t.isNotEmpty) return t;
    return row['key']?.toString() ?? '';
  }

  /// Convierte JSON de bloques guardado en DB a texto plano para el TextField.
  String _plainBodyFromStored(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return raw;
      final parts = <String>[];
      for (final el in decoded) {
        if (el is Map) {
          final t = el['text'] ?? el['t'];
          if (t != null) parts.add(t.toString());
        }
      }
      return parts.isEmpty ? raw : parts.join('\n');
    } catch (_) {
      return raw;
    }
  }

  void _selectBodyEditor(String key) {
    final d = _db;
    if (d == null) return;
    final rows = d.select(
      'SELECT body_text FROM entries WHERE key = ? LIMIT 1',
      [key],
    );
    final raw = rows.isEmpty ? null : rows.first['body_text'] as String?;
    setState(() {
      _bodyEditKey = key;
      _loadBodyFromStoredIntoEditors(raw);
    });
  }

  /// Carga un solo bloque `p` o `link`; listas más largas se aplastan a texto plano.
  void _loadBodyFromStoredIntoEditors(String? raw) {
    _linkKeyController.clear();
    _bodyController.clear();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) {
        _bodyController.text = raw;
        return;
      }
      if (decoded.length == 1 && decoded.first is Map) {
        final m = Map<String, dynamic>.from(
          (decoded.first as Map).map((k, v) => MapEntry(k.toString(), v)),
        );
        final t = (m['t'] ?? m['type'] ?? 'p').toString();
        if (t == 'link') {
          _linkKeyController.text = (m['key'] ?? '').toString();
          _bodyController.text = (m['text'] ?? '').toString();
          return;
        }
        if (t == 'img') {
          return;
        }
        _bodyController.text = (m['text'] ?? '').toString();
        return;
      }
      _bodyController.text = _plainBodyFromStored(raw);
    } catch (_) {
      _bodyController.text = raw;
    }
  }

  void _saveBody() {
    final key = _bodyEditKey;
    final d = _db;
    if (key == null || key.isEmpty || d == null) return;

    final text = _bodyController.text;
    final linkDest = _linkKeyController.text.trim();

    if (linkDest.isNotEmpty && text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Con Link Key hace falta texto visible en Body.',
          ),
        ),
      );
      return;
    }

    final String blocks;
    if (linkDest.isNotEmpty) {
      blocks = jsonEncode([
        {'type': 'link', 'key': linkDest, 'text': text},
      ]);
    } else {
      blocks = jsonEncode([
        {'type': 'p', 'text': text},
      ]);
    }

    d.execute(
      'UPDATE entries SET body_text = ? WHERE key = ?',
      [blocks, key],
    );

    try {
      final f = File(_openKeyPath);
      if (f.existsSync()) {
        final openKey = f.readAsStringSync().trim();
        if (openKey.isNotEmpty && openKey == key) {
          ensureLibrarySchema(d);
          writeViewerCurrentJson(d, key);
        }
      }
    } catch (_) {}

    print('[LB][BODY_SAVE] key=$key link=${linkDest.isNotEmpty}');
  }

  void _createEntry() {
    final d = _db;
    if (d == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final key =
        'LB_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';

    final maxRow = d
        .select(
          'SELECT COALESCE(MAX(seq), -1) AS m FROM entries WHERE parentKey = ?',
          [_currentParentKey],
        )
        .first;
    final nextSeq = (maxRow['m'] as int) + 1;

    d.execute(
      'INSERT INTO entries (key, parentKey, seq, title) VALUES (?, ?, ?, ?)',
      [key, _currentParentKey, nextSeq, title],
    );

    _titleController.clear();
    _loadChildren();
  }

  void _navigateInto(String childKey) {
    setState(() {
      _currentParentKey = childKey;
    });
    _writeOpenKey(childKey);
    _loadChildren();
  }

  void _goBack() {
    final d = _db;
    if (d == null) return;
    if (_currentParentKey == 'ROOT') return;

    final r = d.select(
      'SELECT parentKey FROM entries WHERE key = ?',
      [_currentParentKey],
    );
    if (r.isEmpty) return;

    final pk = r.first['parentKey'] as String?;
    final next = (pk == null || pk.isEmpty) ? 'ROOT' : pk;

    setState(() {
      _currentParentKey = next;
    });
    _writeOpenKey(_currentParentKey);
    _loadChildren();
  }

  void _onRefresh() {
    runLibraryBuild();
    try {
      final f = File(_openKeyPath);
      if (f.existsSync()) {
        final k = f.readAsStringSync().trim();
        if (k.isNotEmpty) _lastProcessedOpenKey = k;
      }
    } catch (_) {}
    _loadChildren();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LB · $_currentParentKey'),
        leading: _currentParentKey == 'ROOT'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'REFRESH',
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título (nuevo entry)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _createEntry(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _createEntry,
                  child: const Text('Crear'),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, i) {
                final row = _rows[i];
                final key = row['key'] as String;
                final selected = _bodyEditKey == key;
                return ListTile(
                  title: Text(_displayLabel(row)),
                  subtitle: Text('key=$key · seq=${row['seq']}'),
                  selected: selected,
                  trailing: IconButton(
                    icon: const Icon(Icons.notes_outlined),
                    tooltip: 'Editar body',
                    onPressed: () => _selectBodyEditor(key),
                  ),
                  onTap: () => _navigateInto(key),
                );
              },
            ),
          ),
          Material(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _bodyEditKey == null
                        ? 'Body — pulsa el icono de notas en una fila'
                        : 'Body · $_bodyEditKey',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _linkKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Link Key (opcional)',
                      hintText: 'KEY destino si este body es un enlace',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _bodyEditKey != null,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyController,
                    minLines: 4,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'Body (texto visible)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    enabled: _bodyEditKey != null,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _bodyEditKey == null ? null : _saveBody,
                    child: const Text('SAVE BODY'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
