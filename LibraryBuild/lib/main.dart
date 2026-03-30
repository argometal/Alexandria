import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    _openDbAndSchema();
    _syncParentFromOpenKey();
    _loadChildren();
    _viewerPoll = Timer.periodic(const Duration(seconds: 2), (_) {
      syncViewerFromOpenKey();
    });
  }

  @override
  void dispose() {
    _viewerPoll?.cancel();
    _titleController.dispose();
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
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, i) {
                final row = _rows[i];
                final key = row['key'] as String;
                return ListTile(
                  title: Text(_displayLabel(row)),
                  subtitle: Text('key=$key · seq=${row['seq']}'),
                  onTap: () => _navigateInto(key),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
