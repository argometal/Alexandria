import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import 'alexandria_paths.dart';
import 'library_build.dart';
import 'locus_editor.dart';
import 'data_transfer_page.dart';
import 'metrics_recall_page.dart';
import 'realm_admin_page.dart';
import 'study/parcour_study_page.dart';
import 'object_search_page.dart';
import 'lb_pdf_export.dart';
import 'node_card_reader_page.dart';
import 'pao/pao_standard_page.dart';

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
  /// Último rating Parcour Review por locus cuando el padre actual es un parcour (semáforo LB).
  Map<String, String>? _parcourRatingByLocus;
  static const List<String> _kNavIntents = [
    'explore',
    'review',
    'seek',
    'drift',
  ];
  int _intentIndex = 0;

  /// Leading de lista: base 40px; factor **4×** (160) para parcour/objeto/realm en la misma lista.
  static const double _kListHeroSize = 160;

  @override
  void initState() {
    super.initState();
    AlexandriaPaths.ensureMigratedToRealmLayout();
    _openDbAndSchema();
    ensureDualBridgeDefaults();
    _syncNavigationIntentIndexFromDisk();
    _syncParentFromBridgeContext();
    _loadChildren();
    _syncIntentBridgeAnchorWithFocus();
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
    _syncNavigationIntentIndexFromDisk();
    _syncParentFromBridgeContext();
    _loadChildren();
    _syncIntentBridgeAnchorWithFocus();
  }

  void _syncNavigationIntentIndexFromDisk() {
    try {
      final f = File(AlexandriaPaths.navigationIntentPath);
      if (!f.existsSync()) return;
      final firstLine =
          f.readAsStringSync().split(RegExp(r'\r?\n')).first.trim().toLowerCase();
      final i = _kNavIntents.indexOf(firstLine);
      if (i >= 0) {
        _intentIndex = i;
      }
    } catch (_) {}
  }

  /// Texto del drawer: modo + locus en foco (marco Hero = ese objeto).
  String _intentDrawerSubtitle() {
    try {
      final f = File(AlexandriaPaths.navigationIntentPath);
      if (!f.existsSync()) {
        return _kNavIntents[_intentIndex];
      }
      final lines = f.readAsStringSync().split(RegExp(r'\r?\n'));
      final mode =
          lines.isNotEmpty ? lines.first.trim() : _kNavIntents[_intentIndex];
      if (lines.length >= 2 && lines[1].trim().isNotEmpty) {
        return '$mode · marco ${lines[1].trim()}';
      }
      return mode;
    } catch (_) {
      return _kNavIntents[_intentIndex];
    }
  }

  void _cycleNavigationIntent() {
    setState(() => _intentIndex = (_intentIndex + 1) % _kNavIntents.length);
    _syncIntentBridgeAnchorWithFocus();
    if (!mounted) return;
    final focus = readFocusKeyWithFallback().trim();
    final extra = focus.isNotEmpty ? ' · marco $focus' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Intent → ${_kNavIntents[_intentIndex]}$extra (HUD GateKeeper)',
        ),
      ),
    );
  }

  /// Mantiene `navigation_intent.txt` alineado con [readFocusKeyWithFallback]:
  /// modo (línea 1) + clave de locus en foco (línea 2) = marco Hero para place/hint/ridiculous.
  void _syncIntentBridgeAnchorWithFocus() {
    try {
      final f = File(AlexandriaPaths.navigationIntentPath);
      f.parent.createSync(recursive: true);
      final mode = _kNavIntents[_intentIndex];
      final focus = readFocusKeyWithFallback().trim();
      if (focus.isNotEmpty) {
        f.writeAsStringSync('$mode\n$focus');
      } else {
        f.writeAsStringSync(mode);
      }
    } catch (_) {}
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

    final parentMeta = d.select(
      'SELECT cognitiveRole FROM entries WHERE key = ?',
      [_currentParentKey],
    );
    final parentIsParcour = parentMeta.isNotEmpty &&
        normalizeCognitiveRole(parentMeta.first['cognitiveRole']) == 'parcour';

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
      _parcourRatingByLocus = parentIsParcour
          ? latestParcourRatingByLocus(d, _currentParentKey)
          : null;
    });
  }

  Future<void> _openObjectNodeViewer(BuildContext context, String entryKey) async {
    final db = _db;
    if (db == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => NodeCardReaderPage(db: db, entryKey: entryKey),
      ),
    );
    if (mounted) _loadChildren();
  }

  /// Semáforo: último resultado Parcour Review (good / medium / fail).
  Widget _parcourReviewSemaforoDot(BuildContext context, String? rating) {
    final cs = Theme.of(context).colorScheme;
    final Color c;
    switch (rating) {
      case 'good':
        c = const Color(0xFF2E7D32);
        break;
      case 'medium':
        c = const Color(0xFFF9A825);
        break;
      case 'fail':
        c = const Color(0xFFC62828);
        break;
      default:
        c = cs.outlineVariant;
    }
    final label = rating == null || rating.isEmpty ? 'sin dato' : rating;
    return Tooltip(
      message: 'Último Parcour Review: $label',
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
        ),
      ),
    );
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

  /// Primer párrafo `ridiculous_story` en body (preview lista; mismo [parseBody] que el editor).
  String? _firstRidiculousStoryPreview(String? bodyText, {int maxChars = 280}) {
    final blocks = parseBody(bodyText);
    for (final b in blocks) {
      if (b['type'] != 'p') continue;
      final tk = b['textKind']?.toString().toLowerCase().trim() ?? '';
      if (tk != 'ridiculous_story') continue;
      var t = (b['text'] ?? '').toString().trim();
      if (t.isEmpty) continue;
      if (t.length > maxChars) {
        t = '${t.substring(0, maxChars)}…';
      }
      return t;
    }
    return null;
  }

  Widget _microHeroLeading(String entryKey, String? bodyText, String roleKey) {
    final path = _resolveMicroHeroPath(entryKey, bodyText);
    if (path != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: _kListHeroSize,
          height: _kListHeroSize,
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
      width: _kListHeroSize,
      height: _kListHeroSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        emoji[roleKey] ?? Icons.description_outlined,
        size: 40,
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
    _syncIntentBridgeAnchorWithFocus();
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
    _syncIntentBridgeAnchorWithFocus();
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
          const SizedBox(height: 4),
          Text(
            formatParcourReviewOneLine(loadParcourReviewSummary(d, parcourKey)),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.secondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _castleCompletionLine(d, parcourKey),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                ),
          ),
        ],
      ),
    );
  }

  /// ORM-16-04: último `good` Parcour Review vs activos Castle (`ridiculous_story` en hijos directos).
  String _castleCompletionLine(Database d, String parcourKey) {
    final r = computeCastleCompletionForParcour(d, parcourKey);
    if (r.isNA) {
      return 'Castle: N/A';
    }
    final p = ((r.percent ?? 0) * 100).round();
    return 'Castle: $p% (good ${r.goodCount} / active ${r.castleActiveCount})';
  }

  Future<void> _openObjectSearch() async {
    final d = _db;
    if (d == null) return;
    final pick = await Navigator.of(context).push<ObjectSearchPick>(
      MaterialPageRoute<ObjectSearchPick>(
        builder: (_) => ObjectSearchPage(db: d),
      ),
    );
    if (!mounted || pick == null) return;
    setState(() {
      _currentParentKey = pick.parentKey;
    });
    writeBridgeContextKey(pick.parentKey);
    writeBridgeFocusKey(pick.focusKey);
    _syncIntentBridgeAnchorWithFocus();
    _loadChildren();
  }

  void _openRealmAdmin() {
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
  }

  Widget _drawerHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = AlexandriaPaths.readActiveRealmId();
    return DrawerHeader(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(color: cs.primaryContainer),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Realm Library',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Realm activo: $active',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _db;
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _drawerHeader(context),
            _drawerSection(context, 'LECTURA'),
            ListTile(
              leading: const Icon(Icons.chrome_reader_mode_outlined),
              title: const Text('Lector de nodo'),
              subtitle: const Text('Parcour u object (lista)'),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                LbPdfExport.showNodeCardKeyDialog(context, d);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF de nodo'),
              subtitle: const Text('Objeto u otro entry'),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                LbPdfExport.showObjectPdfDialog(context, d);
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('PDF de parcour'),
              subtitle: const Text('Un parcour por exportación'),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                LbPdfExport.showParcourPdfDialog(context, d);
              },
            ),
            _drawerSection(context, 'IMPORTAR'),
            ListTile(
              leading: const Icon(Icons.sync_alt),
              title: const Text('Importar contenido a locus'),
              subtitle: const Text('Desde data-transfer/out/ → body_text'),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => DataTransferPage(db: d),
                  ),
                );
              },
            ),
            _drawerSection(context, 'PAO'),
            ListTile(
              leading: const Icon(Icons.face_retouching_natural_outlined),
              title: const Text('PAO (00–99)'),
              subtitle: const Text('Sistema de 2 dígitos · import / export JSON'),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PaoStandardPage(db: d),
                  ),
                );
              },
            ),
            _drawerSection(context, 'MÉTRICAS'),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Métricas recall'),
              subtitle: const Text('Export CSV'),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => MetricsRecallPage(db: d),
                  ),
                );
              },
            ),
            _drawerSection(context, 'SISTEMA'),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: const Text('Realms'),
              subtitle: const Text('Core / Active / Seek'),
              onTap: () {
                Navigator.pop(context);
                _openRealmAdmin();
              },
            ),
            Tooltip(
              message: 'Modo explore / review / seek / drift. Si hay foco en un '
                  'objeto, se guarda como “marco”: place, hint y ridiculous story '
                  'van ligados al Hero de ese mismo locus.',
              child: ListTile(
                leading: const Icon(Icons.explore_outlined),
                title: const Text('Intent de navegación'),
                subtitle: Text(
                  _intentDrawerSubtitle(),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cycleNavigationIntent();
                },
              ),
            ),
          ],
        ),
      ),
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
        leadingWidth: _currentParentKey == 'ROOT' ? 56 : 112,
        automaticallyImplyLeading: false,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menú',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            if (_currentParentKey != 'ROOT')
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Subir',
                onPressed: _goBack,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar objetos (FTS5) · Core / Active / Seek',
            onPressed: _openObjectSearch,
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
                      final ridiculousPreview =
                          _firstRidiculousStoryPreview(row['body_text'] as String?);
                      return Tooltip(
                        message: roleKey == 'object'
                            ? 'Doble clic: visor de contenido (Node card)'
                            : 'Doble clic para entrar al nivel',
                        child: Material(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onDoubleTap: () {
                              if (roleKey == 'object') {
                                _openObjectNodeViewer(context, key);
                              } else {
                                _navigateInto(key);
                              }
                            },
                            child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (roleKey == 'object' &&
                                    _parcourRatingByLocus != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6, top: 6),
                                    child: _parcourReviewSemaforoDot(
                                      context,
                                      _parcourRatingByLocus![key],
                                    ),
                                  ),
                                ],
                                Tooltip(
                                  message: roleKey == 'object'
                                      ? 'Rol (solo LB). Doble clic: visor de contenido.'
                                      : 'Rol (solo LB; GK no lo lee). Doble clic en la fila para entrar.',
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
                                      if (ridiculousPreview != null &&
                                          ridiculousPreview.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          ridiculousPreview,
                                          maxLines: 5,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
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
