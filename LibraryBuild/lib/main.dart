import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import 'alexandria_paths.dart';
import 'library_build.dart';
import 'locus_editor.dart';
import 'realm_admin_page.dart';
import 'study/parcour_study_page.dart';

/// Etiquetas solo para UI (Cambio 351 — sin lógica de negocio).
const _kCognitiveRoleLabels = <String, String>{
  'realm': 'Realm',
  'parcour': 'Parcour',
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
  List<Map<String, Object?>> _rows = [];

  @override
  void initState() {
    super.initState();
    AlexandriaPaths.ensureMigratedToRealmLayout();
    _openDbAndSchema();
    ensureDualBridgeDefaults();
    _syncParentFromBridgeContext();
    _loadChildren();
  }

  @override
  void dispose() {
    _db?.dispose();
    super.dispose();
  }

  void _reloadAfterRealmChange() {
    _db?.dispose();
    _db = null;
    _openDbAndSchema();
    ensureDualBridgeDefaults();
    _syncParentFromBridgeContext();
    _loadChildren();
  }

  void _openDbAndSchema() {
    Directory(AlexandriaPaths.realmDataRoot()).createSync(recursive: true);
    _db = sqlite3.open(AlexandriaPaths.dbPath);
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

  void _loadChildren() {
    final d = _db;
    if (d == null) return;

    final result = d.select(
      'SELECT key, seq, title, cognitiveRole, body_text, last_reviewed_at, next_review_at, memory_strength, stability_days, recall_score, review_count, success_count, failure_count FROM entries WHERE parentKey = ? ORDER BY seq ASC',
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
                'next_review_at': row['next_review_at'],
                'memory_strength': row['memory_strength'],
                'stability_days': row['stability_days'],
                'recall_score': row['recall_score'],
                'review_count': row['review_count'],
                'success_count': row['success_count'],
                'failure_count': row['failure_count'],
              })
          .toList();
    });
  }

  /// ORM `LAYERS_REALM_PARCOUR_OBJECT.md`: `R1` realm, `P1..P20` parcours; `ROOT` / `PARCOUR_MAIN` son claves operativas con etiqueta ORM.
  String _displayLabel(Map<String, Object?> row) {
    final t = row['title']?.toString().trim();
    if (t != null && t.isNotEmpty) return t;
    final k = row['key']?.toString() ?? '';
    if (k == 'ROOT') return 'R1';
    if (k == 'PARCOUR_MAIN') return 'Parcours (R1)';
    return k;
  }

  String _parentBreadcrumbLabel(String parentKey) {
    if (parentKey == 'ROOT') return 'R1';
    if (parentKey == 'PARCOUR_MAIN') return 'Parcours (R1)';
    return parentKey;
  }

  String _roleBadgeLabel(Object? roleRaw) {
    final r = normalizeCognitiveRole(roleRaw);
    const emoji = <String, String>{
      'realm': '📁',
      'parcour': '🔄',
      'object': '📄',
    };
    final e = emoji[r] ?? '📄';
    final name = _kCognitiveRoleLabels[r] ?? r;
    return '$e $name';
  }

  /// ISO 8601 nullable -> "never" / "today" / "yesterday" / "N days ago"...
  String _formatLastReviewedAt(String? iso) {
    if (iso == null || iso.trim().isEmpty) return 'never';
    final dt = DateTime.tryParse(iso.trim());
    if (dt == null) return 'never';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff < 0) return 'upcoming';
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${diff ~/ 7} weeks ago';
    if (diff < 365) return '${diff ~/ 30} months ago';
    return '${diff ~/ 365} years ago';
  }

  String _formatDueTag(String? iso) {
    if (iso == null || iso.trim().isEmpty) return 'new';
    final dt = DateTime.tryParse(iso.trim());
    if (dt == null) return 'new';
    final now = DateTime.now();
    final diffHours = dt.toLocal().difference(now).inHours;
    if (diffHours <= 0) return 'due';
    if (diffHours < 24) return 'in ${diffHours}h';
    final days = (diffHours / 24).floor();
    return 'in ${days}d';
  }

  void _reviewEntry(String key, int grade) {
    final d = _db;
    if (d == null) return;
    try {
      ensureLibrarySchema(d);
      recordRecallReview(d, key, grade);
      _loadChildren();
      runLibraryBuild();
    } catch (_) {}
  }

  /// Hero: `assets/<key>/hero.(png|jpg|jpeg|webp)`; si no, primera `img` en body_text.
  String? _resolveMicroHeroPath(String entryKey, String? bodyText) {
    final sep = Platform.pathSeparator;
    final baseDir = Directory('${AlexandriaPaths.assetsRoot}$sep$entryKey');
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
      final underRoot = File('${AlexandriaPaths.assetsRoot}$sep$src');
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

  Future<void> _promptMoveParcour(BuildContext context, String fromKey) async {
    final d = _db;
    if (d == null) return;
    final rows = d.select(
      "SELECT key, title FROM entries WHERE parentKey = 'PARCOUR_MAIN' ORDER BY seq ASC",
    );
    final choices = <Map<String, String>>[];
    for (final r in rows) {
      final k = r['key'] as String;
      if (k == fromKey) continue;
      choices.add({
        'key': k,
        'title': (r['title'] as String?)?.trim().isNotEmpty == true
            ? (r['title'] as String).trim()
            : k,
      });
    }
    if (choices.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay otro parcour como destino.')),
      );
      return;
    }
    var destKey = choices.first['key']!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Mover parcour'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Origen: $fromKey'),
                const SizedBox(height: 8),
                const Text(
                  'Se borra el subárbol del destino y se sustituye por el del origen. '
                  'El hueco del origen vuelve al esqueleto vacío (L1…L20).',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Parcour destino',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  isExpanded: true,
                  value: destKey,
                  items: choices
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c['key'],
                          child: Text('${c['key']} — ${c['title']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => destKey = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mover'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final result = remapParcourSubtreeToParcourKey(d, fromKey, destKey);
    if (!context.mounted) return;
    if (result.ok) {
      runLibraryBuild();
      _loadChildren();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parcour movido: $fromKey → $destKey')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _promptMoveObject(BuildContext context, String objectKey) async {
    final d = _db;
    if (d == null) return;
    final parcours = d.select(
      "SELECT key, title FROM entries WHERE parentKey = 'PARCOUR_MAIN' ORDER BY seq ASC",
    );
    if (parcours.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay parcours bajo PARCOUR_MAIN.')),
      );
      return;
    }

    final meta = d.select(
      'SELECT seq, parentKey FROM entries WHERE key = ?',
      [objectKey],
    );
    var destParcourKey = _currentParentKey;
    var slotSeq = 0;
    if (meta.isNotEmpty) {
      final raw = meta.first['seq'];
      final parsed = raw is int
          ? raw
          : int.tryParse(raw?.toString() ?? '');
      slotSeq = (parsed ?? 0).clamp(0, 19);
      final pk = meta.first['parentKey']?.toString().trim();
      if (pk != null && pk.isNotEmpty) {
        destParcourKey = pk;
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Mover objeto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Origen: $objectKey'),
                  const SizedBox(height: 8),
                  const Text(
                    'Si el slot destino ya tiene contenido, se sustituye. '
                    'El hueco en el parcour de origen se rellena con el esqueleto.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Parcour destino',
                      style: Theme.of(ctx).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: destParcourKey,
                    items: parcours
                        .map(
                          (r) => DropdownMenuItem<String>(
                            value: r['key'] as String,
                            child: Text(
                              '${r['key']} — ${((r['title'] as String?)?.trim().isNotEmpty == true) ? (r['title'] as String).trim() : r['key']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => destParcourKey = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Slot (1–20)',
                      style: Theme.of(ctx).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: slotSeq,
                    items: List<DropdownMenuItem<int>>.generate(
                      20,
                      (i) => DropdownMenuItem<int>(
                        value: i,
                        child: Text(
                          '${i + 1} → ${defaultObjectKeyForParcourChild(destParcourKey, i)}',
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => slotSeq = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Mover'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final result =
        moveObjectLocusToParcourSlot(d, objectKey, destParcourKey, slotSeq);
    if (!context.mounted) return;
    if (result.ok) {
      runLibraryBuild();
      _loadChildren();
      if (!context.mounted) return;
      final dest =
          defaultObjectKeyForParcourChild(destParcourKey, slotSeq);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Objeto movido: $objectKey → $dest')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _openParcourStudy(BuildContext context, String parcourKey) async {
    final d = _db;
    if (d == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ParcourStudyPage(db: d, parcourKey: parcourKey),
      ),
    );
    if (mounted) _loadChildren();
  }

  void _navigateInto(String childKey) {
    setState(() {
      _currentParentKey = childKey;
    });
    writeBridgeContextKey(childKey);
    writeBridgeFocusKey(childKey);
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
    writeBridgeContextKey(_currentParentKey);
    writeBridgeFocusKey(_currentParentKey);
    _loadChildren();
  }

  void _onRefresh() {
    runLibraryBuild();
    _loadChildren();
  }

  /// Franja bajo el AppBar: recall (Again/Hard/…) vs Fib (Parcour Study). Mismo subárbol que el padre actual.
  Widget _buildStatsStrip(BuildContext context) {
    final d = _db;
    if (d == null) return const SizedBox.shrink();
    final stats = computeRecallStatsForSubtree(d, _currentParentKey);
    final fib = summarizeLocusScheduleForSubtree(d, _currentParentKey);
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recall (entries) · due ${stats['due'] ?? 0} · new ${stats['new'] ?? 0} · total ${stats['total'] ?? 0}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              formatLocusScheduleSummaryLine(fib),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.tertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Por cada fila parcour (L1, L2, …): agregado del subárbol bajo esa clave (misma lógica que la franja superior).
  Widget _parcourRowStatusBar(BuildContext context, String parcourKey) {
    final d = _db;
    if (d == null) return const SizedBox.shrink();
    final stats = computeRecallStatsForSubtree(d, parcourKey);
    final fib = summarizeLocusScheduleForSubtree(d, parcourKey);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recall · due ${stats['due'] ?? 0} · new ${stats['new'] ?? 0} · total ${stats['total'] ?? 0}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            formatLocusScheduleSummaryLine(fib),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.tertiary,
                ),
          ),
        ],
      ),
    );
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
              _parentBreadcrumbLabel(_currentParentKey),
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
            icon: const Icon(Icons.dns_outlined),
            tooltip: 'Realms (una DB activa)',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (ctx) => RealmAdminPage(
                    onRealmChanged: () {
                      if (!mounted) return;
                      setState(_reloadAfterRealmChange);
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate snapshot / list',
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatsStrip(context),
          Expanded(
            child: _rows.isEmpty
                ? Center(
                    child: Text(
                      'No entries at this level.\nGo back to continue.',
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
                                            '·  Last review: $reviewed',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          if (roleKey == 'object')
                                            Text(
                                              '·  Due: ${_formatDueTag(row['next_review_at'] as String?)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                            ),
                                        ],
                                      ),
                                      if (roleKey == 'parcour')
                                        _parcourRowStatusBar(context, key),
                                      if (roleKey == 'object') ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              'score=${(row['recall_score'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                              style: Theme.of(context).textTheme.labelSmall,
                                            ),
                                            Text(
                                              'S=${(row['stability_days'] as num?)?.toStringAsFixed(1) ?? '0.0'}d',
                                              style: Theme.of(context).textTheme.labelSmall,
                                            ),
                                            Text(
                                              'M=${(row['memory_strength'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                              style: Theme.of(context).textTheme.labelSmall,
                                            ),
                                            Text(
                                              'R=${row['review_count'] ?? 0} ✓${row['success_count'] ?? 0} ✕${row['failure_count'] ?? 0}',
                                              style: Theme.of(context).textTheme.labelSmall,
                                            ),
                                          ],
                                        ),
                                      ],
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _openLocusEditor(context, key),
                                      child: const Text('Edit'),
                                    ),
                                    if (roleKey == 'object')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.drive_file_move_outline,
                                        ),
                                        tooltip:
                                            'Mover a otro parcour / slot (reemplaza destino)',
                                        constraints: const BoxConstraints(
                                          minWidth: 44,
                                          minHeight: 44,
                                        ),
                                        onPressed: () =>
                                            _promptMoveObject(context, key),
                                      ),
                                  ],
                                ),
                                if (roleKey == 'parcour') ...[
                                  IconButton(
                                    icon: const Icon(Icons.drive_file_move_outline),
                                    tooltip: 'Mover a otro parcour (reemplaza destino)',
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    onPressed: () =>
                                        _promptMoveParcour(context, key),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.school),
                                    tooltip: 'Study',
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    onPressed: () =>
                                        _openParcourStudy(context, key),
                                  ),
                                ],
                                if (roleKey == 'object')
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      TextButton(
                                        onPressed: () => _reviewEntry(key, 0),
                                        child: const Text('Again'),
                                      ),
                                      TextButton(
                                        onPressed: () => _reviewEntry(key, 1),
                                        child: const Text('Hard'),
                                      ),
                                      TextButton(
                                        onPressed: () => _reviewEntry(key, 2),
                                        child: const Text('Good'),
                                      ),
                                      TextButton(
                                        onPressed: () => _reviewEntry(key, 3),
                                        child: const Text('Easy'),
                                      ),
                                    ],
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
