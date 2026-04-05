import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import 'library_build.dart';
import 'locus_editor.dart';

const _dbPath = r'C:\Alexandria\data\alexandria.db';
const _openKeyPath = r'C:\Alexandria\data\bridge\open_key.txt';

/// Raíz de assets por entry (ORM #365a: `assets/<key>/hero.*` o imágenes en body).
const _kAssetsRoot = r'C:\Alexandria\data\assets';

/// Etiquetas solo para UI (Cambio 351 — sin lógica de negocio).
const _kCognitiveRoleLabels = <String, String>{
  'realm': 'Realm',
  'parcour': 'Parcour',
  'room': 'Room',
  'object': 'Object',
};

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
      title: 'Realm Library',
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

  /// Firma context+focus para no repetir `runLibraryBuild()` cada 2s (ORM-15V3 dual bridge).
  String? _lastProcessedBridgeSig;

  /// Evita solapar `runLibraryBuild()` si dura más que el intervalo del timer.
  bool _libraryBuildRunning = false;

  @override
  void initState() {
    super.initState();
    _openDbAndSchema();
    ensureDualBridgeBootstrapFromOpenKey();
    _syncParentFromBridgeContext();
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
    ensureLibrarySchema(d);
  }

  void _syncParentFromBridgeContext() {
    try {
      final k = readContextKeyWithFallback();
      if (k.isNotEmpty) {
        _currentParentKey = k;
      }
    } catch (_) {}
  }

  /// Cuando cambia bridge (context o focus), alinea UI y ejecuta `runLibraryBuild()`.
  void _checkAndRunLibraryBuild() {
    if (_libraryBuildRunning) return;
    try {
      ensureDualBridgeBootstrapFromOpenKey();
      final contextKey = readContextKeyWithFallback();
      final focusKey = readFocusKeyWithFallback();
      if (contextKey.isEmpty) return;

      if (contextKey != _currentParentKey) {
        setState(() {
          _currentParentKey = contextKey;
        });
        _loadChildren();
      }

      final sig = '$contextKey\x1e$focusKey';
      if (sig == _lastProcessedBridgeSig) return;

      _libraryBuildRunning = true;
      try {
        runLibraryBuild();
        _lastProcessedBridgeSig = sig;
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
      'SELECT key, seq, title, cognitiveRole, body_text, last_reviewed_at FROM entries WHERE parentKey = ? ORDER BY seq ASC',
      [_currentParentKey],
    );

    setState(() {
      _rows = result
          .map((row) => {
                'key': row['key'],
                'seq': row['seq'],
                'title': row['title'],
                'cognitiveRole': row['cognitiveRole'],
                'body_text': row['body_text'],
                'last_reviewed_at': row['last_reviewed_at'],
              })
          .toList();
    });
  }

  String _displayLabel(Map<String, Object?> row) {
    final t = row['title']?.toString().trim();
    if (t != null && t.isNotEmpty) return t;
    return row['key']?.toString() ?? '';
  }

  String _roleBadgeLabel(Object? roleRaw) {
    final r = normalizeCognitiveRole(roleRaw);
    const emoji = <String, String>{
      'realm': '📁',
      'parcour': '🔄',
      'room': '🏠',
      'object': '📄',
    };
    final e = emoji[r] ?? '📄';
    final name = _kCognitiveRoleLabels[r] ?? r;
    return '$e $name';
  }

  /// ISO 8601 nullable → "nunca" / "hoy" / "ayer" / "hace N días"…
  String _formatLastReviewedAt(String? iso) {
    if (iso == null || iso.trim().isEmpty) return 'nunca';
    final dt = DateTime.tryParse(iso.trim());
    if (dt == null) return 'nunca';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff < 0) return 'próximo';
    if (diff == 0) return 'hoy';
    if (diff == 1) return 'ayer';
    if (diff < 7) return 'hace $diff días';
    if (diff < 30) return 'hace ${diff ~/ 7} sem.';
    if (diff < 365) return 'hace ${diff ~/ 30} meses';
    return 'hace ${diff ~/ 365} años';
  }

  /// Hero: `assets/<key>/hero.(png|jpg|jpeg|webp)`; si no, primera `img` en body_text.
  String? _resolveMicroHeroPath(String entryKey, String? bodyText) {
    final sep = Platform.pathSeparator;
    final baseDir = Directory('$_kAssetsRoot$sep$entryKey');
    for (final name in ['hero.png', 'hero.jpg', 'hero.jpeg', 'hero.webp']) {
      final f = File('${baseDir.path}$sep$name');
      if (f.existsSync()) return f.path;
    }
    final blocks = parseBody(bodyText);
    for (final b in blocks) {
      if (b['type'] != 'img') continue;
      final src = (b['src'] ?? '').toString().trim();
      if (src.isEmpty) continue;
      final direct = File(src);
      if (direct.existsSync()) return src;
      final underKey = File('${baseDir.path}$sep$src');
      if (underKey.existsSync()) return underKey.path;
      final underRoot = File('$_kAssetsRoot$sep$src');
      if (underRoot.existsSync()) return underRoot.path;
    }
    return null;
  }

  Widget _microHeroLeading(String entryKey, String? bodyText, String roleKey) {
    final path = _resolveMicroHeroPath(entryKey, bodyText);
    if (path != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(path),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _microHeroPlaceholder(roleKey),
        ),
      );
    }
    return _microHeroPlaceholder(roleKey);
  }

  Widget _microHeroPlaceholder(String roleKey) {
    const emoji = <String, IconData>{
      'realm': Icons.folder_outlined,
      'parcour': Icons.route,
      'room': Icons.home_outlined,
      'object': Icons.article_outlined,
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        emoji[roleKey] ?? Icons.description_outlined,
        size: 22,
      ),
    );
  }

  Future<void> _openLocusEditor(BuildContext context, String key) async {
    final d = _db;
    if (d == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (ctx) => LocusEditorPage(
          db: d,
          entryKey: key,
        ),
      ),
    );
    if (saved == true && mounted) {
      _loadChildren();
    }
  }

  void _createEntry() {
    final d = _db;
    if (d == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    // [#357] OBJECT no tiene hijos en el modelo (solo body); GK no lee esto — solo UI LB.
    final parentRows = d.select(
      'SELECT cognitiveRole FROM entries WHERE key = ? LIMIT 1',
      [_currentParentKey],
    );
    if (parentRows.isNotEmpty) {
      final roleRaw = parentRows.first['cognitiveRole'];
      if (normalizeCognitiveRole(roleRaw) == 'object') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pueden crear hijos bajo una entry con rol Object (solo contenido / body).',
            ),
          ),
        );
        return;
      }
    }

    final countRow = d.select(
      'SELECT COUNT(*) AS c FROM entries WHERE parentKey = ?',
      [_currentParentKey],
    ).first;
    final childCount = countRow['c'] as int;
    if (childCount >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya hay 20 hijos (slots 0–19 llenos).'),
        ),
      );
      return;
    }

    final maxRow = d
        .select(
          'SELECT COALESCE(MAX(seq), -1) AS m FROM entries WHERE parentKey = ?',
          [_currentParentKey],
        )
        .first;
    final nextSeq = (maxRow['m'] as int) + 1;
    if (nextSeq > 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('seq máximo 19 (20 slots por nivel).'),
        ),
      );
      return;
    }

    final newKey =
        'LB_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';

    final parentRoleRaw =
        parentRows.isEmpty ? null : parentRows.first['cognitiveRole'];
    final newRole = defaultChildCognitiveRoleForParent(parentRoleRaw);

    d.execute(
      'INSERT INTO entries (key, parentKey, seq, title, cognitiveRole) VALUES (?, ?, ?, ?, ?)',
      [newKey, _currentParentKey, nextSeq, title, newRole],
    );

    _titleController.clear();
    _loadChildren();
  }

  void _navigateInto(String childKey) {
    setState(() {
      _currentParentKey = childKey;
    });
    // open_key solo desde GateKeeper (clic en frame); LB no debe pisar el bridge al navegar.
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
      final ctx = readContextKeyWithFallback();
      final foc = readFocusKeyWithFallback();
      _lastProcessedBridgeSig = '$ctx\x1e$foc';
    } catch (_) {}
    _loadChildren();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Realm Library'),
            Text(
              _currentParentKey,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        leading: _currentParentKey == 'ROOT'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerar snapshot / lista',
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva entrada (título)',
                      hintText: 'Índice — no edita contenido aquí',
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
            child: _rows.isEmpty
                ? Center(
                    child: Text(
                      'Sin entradas en este nivel.\nCrea una o vuelve atrás.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final row = _rows[i];
                      final key = row['key'] as String;
                      final roleKey = normalizeCognitiveRole(row['cognitiveRole']);
                      final reviewed = _formatLastReviewedAt(
                        row['last_reviewed_at'] as String?,
                      );
                      return Material(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _navigateInto(key),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Tooltip(
                                  message: 'Rol (solo LB; GK no lo lee)',
                                  child: _microHeroLeading(
                                    key,
                                    row['body_text'] as String?,
                                    roleKey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _displayLabel(row),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            _roleBadgeLabel(row['cognitiveRole']),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                          Text(
                                            '·  Última revisión: $reviewed',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'key=$key  ·  seq=${row['seq']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontFamily: 'monospace',
                                              fontSize: 10,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _openLocusEditor(context, key),
                                  child: const Text('Editar'),
                                ),
                              ],
                            ),
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
