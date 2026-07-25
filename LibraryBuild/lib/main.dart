import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import 'alexandria_help_page.dart';
import 'alexandria_lb_theme.dart';
import 'alexandria_app_log.dart';
import 'alexandria_paths.dart';
import 'alexandria_sibling_apps.dart';
import 'app_locale_preferences.dart';
import 'l10n/app_localizations.dart';
import 'library_build.dart';
import 'locus_editor.dart';
import 'data_transfer_page.dart';
import 'metrics_recall_page.dart';
import 'realm_admin_page.dart';
import 'study/parcour_study_page.dart';
import 'object_search_page.dart';
import 'lb_pdf_export.dart';
import 'node_card_reader_page.dart';
import 'pao/pao_individual_drill_page.dart';
import 'pao/pao_standard_page.dart';
import 'go_game/go_game_page.dart';
import 'match_cards/match_cards_page.dart';
import 'poker_memory/poker_memory_page.dart';
import 'parcour_fib_timeline.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AlexandriaAppLog.init();
  AlexandriaPaths.writeRuntimeRootMarkerForGateKeeper();
  runApp(const LbMinimalApp());
}

class LbMinimalApp extends StatefulWidget {
  const LbMinimalApp({super.key});

  @override
  State<LbMinimalApp> createState() => _LbMinimalAppState();
}

class _LbMinimalAppState extends State<LbMinimalApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    AppLocalePreferences.loadSavedLanguageCode().then((code) {
      if (!mounted) return;
      setState(() {
        _locale = AppLocalePreferences.localeFromCode(code);
      });
      writeGkUiLangBridge(code);
    });
  }

  void _setLocale(Locale? locale) {
    setState(() => _locale = locale);
    AppLocalePreferences.saveLanguageCode(locale?.languageCode);
    writeGkUiLangBridge(locale?.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)?.appTitle ?? 'Realm Library',
      theme: AlexandriaLbTheme.theme,
      home: LbHome(
        onLocaleChanged: _setLocale,
        appLocale: _locale,
      ),
    );
  }
}

class LbHome extends StatefulWidget {
  const LbHome({
    super.key,
    required this.onLocaleChanged,
    required this.appLocale,
  });

  final ValueChanged<Locale?> onLocaleChanged;

  /// Locale fijado por el usuario; `null` = seguir dispositivo.
  final Locale? appLocale;

  @override
  State<LbHome> createState() => _LbHomeState();
}

/// Superficie principal de [LbHome]: árbol del realm activo vs editor Match cards (misma base).
enum _LbMainShell { realmTree, matchCards }

class _LbHomeState extends State<LbHome> {
  Database? _db;
  _LbMainShell _mainShell = _LbMainShell.realmTree;
  String _currentParentKey = 'ROOT';
  List<Map<String, Object?>> _rows = [];
  /// Último rating Parcour Review por locus cuando el padre actual es un parcour (semáforo LB).
  Map<String, String>? _parcourRatingByLocus;
  static const List<String> _kNavIntents = [
    'explore',
    'review',
    'seek',
    'drift',
    'place_recall',
  ];
  int _intentIndex = 0;

  /// Un solo interruptor para todo el realm: `bridge/place_recall_enabled.txt` (GateKeeper lee `1`).
  bool _placeRecallGloballyEnabled = false;

  /// `bridge/memory_athlete_mode.txt`: `1` = umbral 100% en métricas; `0` = estándar 80%.
  bool _memoryAthleteMetricsEnabled = true;

  /// Leading de lista: base 40px; factor **4×** (160) para parcour/objeto/realm en la misma lista.
  static const double _kListHeroSize = 160;

  @override
  void initState() {
    super.initState();
    AlexandriaPaths.ensureMigratedToRealmLayout();
    _openDbAndSchema();
    ensureDualBridgeDefaults();
    syncGkUiLangBridgeFromPreference();
    ensureGatekeeperSnapshotArtifactsSync();
    _syncNavigationIntentIndexFromDisk();
    _syncMemoryAthleteFromDisk();
    _syncPlaceRecallFromDisk();
    _syncParentFromBridgeContext();
    _loadChildren();
    _syncIntentBridgeAnchorWithFocus();
  }

  void _syncPlaceRecallFromDisk() {
    try {
      var fromFile = false;
      final fPr = File(AlexandriaPaths.placeRecallEnabledPath);
      if (fPr.existsSync()) {
        final t = fPr.readAsStringSync().trim();
        fromFile = t == '1' ||
            t.toLowerCase() == 'true' ||
            t.toLowerCase() == 'yes';
      }
      var fromIntent = false;
      final fIntent = File(AlexandriaPaths.navigationIntentPath);
      if (fIntent.existsSync()) {
        final line = fIntent
            .readAsStringSync()
            .split(RegExp(r'\r?\n'))
            .first
            .trim()
            .toLowerCase();
        fromIntent = line == 'place_recall';
      }
      if (mounted) {
        setState(() => _placeRecallGloballyEnabled = fromFile || fromIntent);
      }
    } catch (_) {
      if (mounted) setState(() => _placeRecallGloballyEnabled = false);
    }
  }

  void _setPlaceRecallGloballyEnabled(bool value) {
    try {
      final f = File(AlexandriaPaths.placeRecallEnabledPath);
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(value ? '1' : '0');

      if (value) {
        try {
          final fi = File(AlexandriaPaths.navigationIntentPath);
          fi.parent.createSync(recursive: true);
          final focus = readFocusKeyWithFallback().trim();
          const mode = 'place_recall';
          if (focus.isNotEmpty) {
            fi.writeAsStringSync('$mode\n$focus');
          } else {
            fi.writeAsStringSync(mode);
          }
          _syncNavigationIntentIndexFromDisk();
        } catch (_) {}
      } else {
        try {
          final fi = File(AlexandriaPaths.navigationIntentPath);
          if (fi.existsSync()) {
            final lines = fi.readAsStringSync().split(RegExp(r'\r?\n'));
            if (lines.isNotEmpty &&
                lines.first.trim().toLowerCase() == 'place_recall') {
              final rest = lines.length > 1 ? lines.sublist(1) : <String>[];
              const newMode = 'explore';
              fi.writeAsStringSync(
                rest.isEmpty ? newMode : '$newMode\n${rest.join('\n')}',
              );
              _syncNavigationIntentIndexFromDisk();
            }
          }
        } catch (_) {}
      }

      _syncPlaceRecallFromDisk();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
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
    syncGkUiLangBridgeFromPreference();
    ensureGatekeeperSnapshotArtifactsSync();
    _syncNavigationIntentIndexFromDisk();
    _syncMemoryAthleteFromDisk();
    _syncPlaceRecallFromDisk();
    _syncParentFromBridgeContext();
    _loadChildren();
    _syncIntentBridgeAnchorWithFocus();
    if (mounted) {
      setState(() => _mainShell = _LbMainShell.realmTree);
    }
  }

  /// Borrado nuclear: [performAlexandriaNuclearDataResetSync] reconstruye realms; PAO/Match del realm activo se preservan en `default`.
  Future<void> _onNuclearDataResetFromAdmin() async {
    _db?.dispose();
    _db = null;
    try {
      performAlexandriaNuclearDataResetSync();
    } catch (e, st) {
      debugPrint('$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarNuclearError(e.toString()),
          ),
        ),
      );
      _openDbAndSchema();
      ensureDualBridgeDefaults();
      syncGkUiLangBridgeFromPreference();
      ensureGatekeeperSnapshotArtifactsSync();
      _syncNavigationIntentIndexFromDisk();
      _syncMemoryAthleteFromDisk();
      _syncPlaceRecallFromDisk();
      _syncParentFromBridgeContext();
      _loadChildren();
      return;
    }
    if (!mounted) return;
    _openDbAndSchema();
    ensureDualBridgeDefaults();
    syncGkUiLangBridgeFromPreference();
    ensureGatekeeperSnapshotArtifactsSync();
    _syncNavigationIntentIndexFromDisk();
    _syncMemoryAthleteFromDisk();
    _syncPlaceRecallFromDisk();
    setState(() {
      _currentParentKey = 'ROOT';
    });
    _syncParentFromBridgeContext();
    _loadChildren();
    _syncIntentBridgeAnchorWithFocus();
  }

  Future<void> _onPaoDataCleanupFromAdmin() async {
    _db?.dispose();
    _db = null;
    try {
      performPaoLibraryDataCleanupSync();
    } catch (e, st) {
      debugPrint('$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarNuclearError(e.toString()),
          ),
        ),
      );
      _openDbAndSchema();
      ensureDualBridgeDefaults();
      syncGkUiLangBridgeFromPreference();
      ensureGatekeeperSnapshotArtifactsSync();
      _syncNavigationIntentIndexFromDisk();
      _syncMemoryAthleteFromDisk();
      _syncPlaceRecallFromDisk();
      _syncParentFromBridgeContext();
      _loadChildren();
      return;
    }
    if (!mounted) return;
    _openDbAndSchema();
    ensureDualBridgeDefaults();
    syncGkUiLangBridgeFromPreference();
    ensureGatekeeperSnapshotArtifactsSync();
    _syncNavigationIntentIndexFromDisk();
    _syncMemoryAthleteFromDisk();
    _syncPlaceRecallFromDisk();
    _syncParentFromBridgeContext();
    _loadChildren();
    _syncIntentBridgeAnchorWithFocus();
    try {
      runLibraryBuild();
    } catch (_) {}
  }

  Future<void> _onMatchCardsDataCleanupFromAdmin() async {
    _db?.dispose();
    _db = null;
    try {
      performMatchCardsLibraryDataCleanupSync();
    } catch (e, st) {
      debugPrint('$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarNuclearError(e.toString()),
          ),
        ),
      );
      _openDbAndSchema();
      ensureDualBridgeDefaults();
      syncGkUiLangBridgeFromPreference();
      ensureGatekeeperSnapshotArtifactsSync();
      _syncNavigationIntentIndexFromDisk();
      _syncMemoryAthleteFromDisk();
      _syncPlaceRecallFromDisk();
      _syncParentFromBridgeContext();
      _loadChildren();
      return;
    }
    if (!mounted) return;
    _openDbAndSchema();
    ensureDualBridgeDefaults();
    syncGkUiLangBridgeFromPreference();
    ensureGatekeeperSnapshotArtifactsSync();
    _syncNavigationIntentIndexFromDisk();
    _syncMemoryAthleteFromDisk();
    _syncPlaceRecallFromDisk();
    _syncParentFromBridgeContext();
    _loadChildren();
    _syncIntentBridgeAnchorWithFocus();
    try {
      runLibraryBuild();
    } catch (_) {}
  }

  /// Sanitiza el realm activo, Library build y copia a `data/realm_seed/`. Cierra/reabre la DB.
  Future<void> _onRegenerateRealmSeedFromAdmin() async {
    _db?.dispose();
    _db = null;
    try {
      regenerateRealmSeedFromActiveRealmSync();
    } catch (e, st) {
      debugPrint('$st');
      _openDbAndSchema();
      ensureDualBridgeDefaults();
      syncGkUiLangBridgeFromPreference();
      ensureGatekeeperSnapshotArtifactsSync();
      _syncNavigationIntentIndexFromDisk();
      _syncMemoryAthleteFromDisk();
      _syncPlaceRecallFromDisk();
      _syncParentFromBridgeContext();
      _loadChildren();
      rethrow;
    }
    if (!mounted) return;
    _openDbAndSchema();
    ensureDualBridgeDefaults();
    syncGkUiLangBridgeFromPreference();
    ensureGatekeeperSnapshotArtifactsSync();
    _syncNavigationIntentIndexFromDisk();
    _syncMemoryAthleteFromDisk();
    _syncPlaceRecallFromDisk();
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

  void _syncMemoryAthleteFromDisk() {
    try {
      var on = true;
      final f = File(AlexandriaPaths.memoryAthleteModePath);
      if (f.existsSync()) {
        final t = f.readAsStringSync().trim().toLowerCase();
        if (t == '0' ||
            t == 'false' ||
            t == 'no' ||
            t == 'off' ||
            t == 'normal' ||
            t == 'standard') {
          on = false;
        }
      }
      if (mounted) setState(() => _memoryAthleteMetricsEnabled = on);
    } catch (_) {
      if (mounted) setState(() => _memoryAthleteMetricsEnabled = true);
    }
  }

  void _setMemoryAthleteMetricsEnabled(bool value) {
    try {
      final f = File(AlexandriaPaths.memoryAthleteModePath);
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(value ? '1' : '0');
      if (mounted) setState(() => _memoryAthleteMetricsEnabled = value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  /// Drawer: modo de estudio + marco Hero (línea 2 del bridge), separado del umbral de métricas.
  String _studyNavigationDrawerSubtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    try {
      final f = File(AlexandriaPaths.navigationIntentPath);
      if (!f.existsSync()) {
        return l10n.studyNavigationDetailModeOnly(_kNavIntents[_intentIndex]);
      }
      final lines = f.readAsStringSync().split(RegExp(r'\r?\n'));
      final mode =
          lines.isNotEmpty ? lines.first.trim() : _kNavIntents[_intentIndex];
      if (lines.length >= 2 && lines[1].trim().isNotEmpty) {
        return l10n.studyNavigationDetailWithFrame(mode, lines[1].trim());
      }
      return l10n.studyNavigationDetailModeOnly(mode);
    } catch (_) {
      return l10n.studyNavigationDetailModeOnly(_kNavIntents[_intentIndex]);
    }
  }

  void _cycleNavigationIntent() {
    setState(() => _intentIndex = (_intentIndex + 1) % _kNavIntents.length);
    _syncIntentBridgeAnchorWithFocus();
    _syncPlaceRecallFromDisk();
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    final focus = readFocusKeyWithFallback().trim();
    final frameSuffix = focus.isNotEmpty ? l.intentFrameSuffix(focus) : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l.intentSnackbar(_kNavIntents[_intentIndex], frameSuffix),
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
    ensureDefaultRealmOnDiskFromBundledTemplateSync();
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
    ensureAlexandriaRealmSeededIfEmpty(d);
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
      '''
SELECT e.key, e.seq, e.title, e.cognitiveRole, e.body_text, e.last_reviewed_at,
       e.next_review_at, e.memory_strength, e.stability_days, e.recall_score,
       e.review_count, e.success_count, e.failure_count,
       COALESCE(lrs.fib_index, 0) AS locus_fib_index
FROM entries e
LEFT JOIN locus_review_state lrs ON lrs.entry_key = e.key
WHERE e.parentKey = ?
ORDER BY e.seq ASC
''',
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
                'locus_fib_index': row['locus_fib_index'],
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
    final l = AppLocalizations.of(context)!;
    final label =
        rating == null || rating.isEmpty ? l.parcourReviewNoData : rating;
    return Tooltip(
      message: l.parcourReviewTooltip(label),
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
  String _displayLabel(BuildContext context, Map<String, Object?> row) {
    final l = AppLocalizations.of(context)!;
    final t = row['title']?.toString().trim();
    if (t != null && t.isNotEmpty) return t;
    final k = row['key']?.toString() ?? '';
    if (k == 'ROOT') return l.breadcrumbRoot;
    if (k == 'PARCOUR_MAIN') return l.breadcrumbParcours;
    return k;
  }

  String _parentBreadcrumbLabel(BuildContext context, String parentKey) {
    final l = AppLocalizations.of(context)!;
    if (parentKey == 'ROOT') return l.breadcrumbRoot;
    if (parentKey == 'PARCOUR_MAIN') return l.breadcrumbParcours;
    return parentKey;
  }

  String _roleBadgeLabel(BuildContext context, Object? roleRaw) {
    final l = AppLocalizations.of(context)!;
    final r = normalizeCognitiveRole(roleRaw);
    const emoji = <String, String>{
      'realm': '📁',
      'parcour': '🔄',
      'object': '📄',
    };
    final e = emoji[r] ?? '📄';
    final name = switch (r) {
      'realm' => l.roleRealm,
      'parcour' => l.roleParcour,
      'object' => l.roleObject,
      _ => r,
    };
    return '$e $name';
  }

  /// ISO 8601 nullable -> relative date phrase (localized).
  String _formatLastReviewedAt(AppLocalizations l, String? iso) {
    if (iso == null || iso.trim().isEmpty) return l.timeReviewNever;
    final dt = DateTime.tryParse(iso.trim());
    if (dt == null) return l.timeReviewNever;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff < 0) return l.timeReviewUpcoming;
    if (diff == 0) return l.timeReviewToday;
    if (diff == 1) return l.timeReviewYesterday;
    if (diff < 7) return l.timeReviewDaysAgo(diff);
    if (diff < 30) return l.timeReviewWeeksAgo(diff ~/ 7);
    if (diff < 365) return l.timeReviewMonthsAgo(diff ~/ 30);
    return l.timeReviewYearsAgo(diff ~/ 365);
  }

  String _formatDueTag(AppLocalizations l, String? iso) {
    if (iso == null || iso.trim().isEmpty) return l.dueTagNew;
    final dt = DateTime.tryParse(iso.trim());
    if (dt == null) return l.dueTagNew;
    final now = DateTime.now();
    final diffHours = dt.toLocal().difference(now).inHours;
    if (diffHours <= 0) return l.dueTagDue;
    if (diffHours < 24) return l.dueTagInHours(diffHours);
    final days = (diffHours / 24).floor();
    return l.dueTagInDays(days);
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
    final path = resolveListHeroThumbPath(entryKey, bodyText);
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
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.snackbarNoDestParcour)),
      );
      return;
    }
    var destKey = choices.first['key']!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(l.dialogMoveParcourTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.originLabel(fromKey)),
                  const SizedBox(height: 8),
                  Text(
                    l.moveParcourBodyWarning,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.destinationParcourLabel,
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
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.move),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final result = remapParcourSubtreeToParcourKey(d, fromKey, destKey);
    if (!context.mounted) return;
    if (result.ok) {
      runLibraryBuild();
      _loadChildren();
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.snackbarParcourMoved(fromKey, destKey))),
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
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.snackbarNoParcoursUnderHub)),
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
          final l = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(l.dialogMoveObjectTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.originLabel(objectKey)),
                  const SizedBox(height: 8),
                  Text(
                    l.moveObjectBodyWarning,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.destinationParcourLabel,
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
                      l.slotLabel,
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
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.move),
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
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.snackbarObjectMoved(objectKey, dest))),
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
    final l = AppLocalizations.of(context)!;
    final stats = computeRecallStatsForSubtree(d, _currentParentKey);
    final fib = summarizeLocusScheduleForSubtree(d, _currentParentKey);
    final cs = Theme.of(context).colorScheme;
    final due = stats['due'] ?? 0;
    final n = stats['new'] ?? 0;
    final total = stats['total'] ?? 0;
    return Material(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.statsRecallLine(due, n, total),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              formatLocusScheduleSummaryLine(fib, l),
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
    final l = AppLocalizations.of(context)!;
    final stats = computeRecallStatsForSubtree(d, parcourKey);
    final fib = summarizeLocusScheduleForSubtree(d, parcourKey);
    final review = loadParcourReviewSummary(d, parcourKey);
    final cs = Theme.of(context).colorScheme;
    final due = stats['due'] ?? 0;
    final n = stats['new'] ?? 0;
    final total = stats['total'] ?? 0;
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
            l.parcourRowRecallLine(due, n, total),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            formatLocusScheduleSummaryLine(fib, l),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.tertiary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            formatParcourReviewOneLine(review, l),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.secondary,
                ),
          ),
          const SizedBox(height: 8),
          ParcourFibTimelineStrip(fibIndex: review.fibIndex),
          const SizedBox(height: 4),
          Text(
            _realmCompletionLine(context, d, parcourKey),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                ),
          ),
        ],
      ),
    );
  }

  /// ORM-16-04: último `good` Parcour Review vs activos realm (`ridiculous_story` en hijos directos).
  String _realmCompletionLine(
    BuildContext context,
    Database d,
    String parcourKey,
  ) {
    final l = AppLocalizations.of(context)!;
    final r = computeRealmCompletionForParcour(d, parcourKey);
    if (r.isNA) {
      return l.realmNA;
    }
    final p = ((r.percent ?? 0) * 100).round();
    return l.realmPercent(p, r.goodCount, r.realmActiveCount);
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

  Future<void> _launchSiblingApp(AlexandriaSiblingAppKind kind) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await AlexandriaSiblingApps.launch(kind);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.siblingAppMissingShort)),
      );
    }
  }

  void _openRealmAdmin() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => RealmAdminPage(
          onRealmChanged: () {
            if (!mounted) return;
            setState(_reloadAfterRealmChange);
          },
          onReleaseDatabase: () {
            _db?.dispose();
            _db = null;
          },
          onNuclearDataReset: _onNuclearDataResetFromAdmin,
          onRegenerateRealmSeed: _onRegenerateRealmSeedFromAdmin,
          onPaoDataCleanup: _onPaoDataCleanupFromAdmin,
          onMatchCardsDataCleanup: _onMatchCardsDataCleanupFromAdmin,
          onOpenMatchCards: () {
            Navigator.of(context).pop();
            if (!mounted) return;
            setState(() => _mainShell = _LbMainShell.matchCards);
          },
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final l = AppLocalizations.of(context)!;
    final current = widget.appLocale?.languageCode;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l.languageTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.language,
                  color: current == null ? cs.primary : null,
                ),
                title: Text(l.languageSystem),
                trailing: current == null
                    ? Icon(Icons.check, color: cs.primary)
                    : null,
                onTap: () {
                  widget.onLocaleChanged(null);
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.languageChanged)),
                    );
                  }
                },
              ),
              ListTile(
                title: Text(l.languageEnglish),
                trailing: current == 'en'
                    ? Icon(Icons.check, color: cs.primary)
                    : null,
                onTap: () {
                  widget.onLocaleChanged(const Locale('en'));
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.languageChanged)),
                    );
                  }
                },
              ),
              ListTile(
                title: Text(l.languageSpanish),
                trailing: current == 'es'
                    ? Icon(Icons.check, color: cs.primary)
                    : null,
                onTap: () {
                  widget.onLocaleChanged(const Locale('es'));
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.languageChanged)),
                    );
                  }
                },
              ),
              ListTile(
                title: Text(l.languagePortuguese),
                trailing: current == 'pt'
                    ? Icon(Icons.check, color: cs.primary)
                    : null,
                onTap: () {
                  widget.onLocaleChanged(const Locale('pt'));
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.languageChanged)),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _drawerHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = AlexandriaPaths.readActiveRealmId();
    final l = AppLocalizations.of(context)!;
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
              l.appTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l.activeRealmLabel(active),
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

  String _currentLanguageChoiceSubtitle(AppLocalizations l) {
    final c = widget.appLocale?.languageCode;
    if (c == null) return l.languageSystem;
    switch (c) {
      case 'en':
        return l.languageEnglish;
      case 'es':
        return l.languageSpanish;
      case 'pt':
        return l.languagePortuguese;
      default:
        return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _db;
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _drawerHeader(context),
            _drawerSection(context, loc.sectionPao),
            ListTile(
              leading: const Icon(Icons.face_retouching_natural_outlined),
              title: Text(loc.paoEditorTitle),
              subtitle: Text(loc.paoEditorSubtitle),
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
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(loc.paoPracticeTitle),
              subtitle: Text(loc.paoPracticeSubtitle),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PaoIndividualDrillPage(db: d),
                  ),
                );
              },
            ),
            _drawerSection(context, loc.sectionMatchCards),
            ListTile(
              leading: const Icon(Icons.style_outlined),
              title: Text(loc.matchCardsTitle),
              subtitle: Text(loc.matchCardsSubtitle),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                setState(() => _mainShell = _LbMainShell.matchCards);
              },
            ),
            ListTile(
              leading: const Icon(Icons.numbers_outlined),
              title: Text(loc.pokerMemoryTitle),
              subtitle: Text(loc.pokerMemoryDrawerSubtitle),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PokerMemoryPage(db: d),
                  ),
                );
              },
            ),
            _drawerSection(context, loc.sectionGo),
            ListTile(
              leading: const Icon(Icons.grid_on_outlined),
              title: Text(loc.goGameTitle),
              subtitle: Text(loc.goGameSubtitle),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => GoGamePage(db: d),
                  ),
                );
              },
            ),
            _drawerSection(context, loc.sectionMetrics),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(loc.metricsRecallTitle),
              subtitle: Text(loc.metricsRecallSubtitle),
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
            _drawerSection(context, loc.sectionLanguage),
            ListTile(
              leading: const Icon(Icons.translate_outlined),
              title: Text(loc.languageTitle),
              subtitle: Text(_currentLanguageChoiceSubtitle(loc)),
              onTap: () {
                Navigator.pop(context);
                _showLanguagePicker();
              },
            ),
            _drawerSection(context, loc.sectionSystem),
            _drawerSection(context, loc.sectionAlexandriaApps),
            ListTile(
              leading: const Icon(Icons.view_in_ar_outlined),
              title: Text(loc.siblingOpenGatekeeper),
              subtitle: Text(loc.siblingOpenGatekeeperSubtitle),
              onTap: () {
                Navigator.pop(context);
                _launchSiblingApp(AlexandriaSiblingAppKind.gateKeeper);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(loc.siblingOpenTrainingLab),
              subtitle: Text(loc.siblingOpenTrainingLabSubtitle),
              onTap: () {
                Navigator.pop(context);
                _launchSiblingApp(AlexandriaSiblingAppKind.trainingLab);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(loc.realmsTitle),
              subtitle: Text(loc.realmsSubtitle),
              onTap: () {
                Navigator.pop(context);
                _openRealmAdmin();
              },
            ),
            SwitchListTile(
              secondary: Icon(
                Icons.percent_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(loc.memoryAthleteSwitchTitle),
              subtitle: Text(
                _memoryAthleteMetricsEnabled
                    ? loc.memoryAthleteSwitchSubtitleOn
                    : loc.memoryAthleteSwitchSubtitleOff,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _memoryAthleteMetricsEnabled,
              onChanged: _setMemoryAthleteMetricsEnabled,
            ),
            Tooltip(
              message: loc.studyNavigationTooltip,
              child: ListTile(
                leading: const Icon(Icons.explore_outlined),
                title: Text(loc.studyNavigationTitle),
                subtitle: Text(
                  _studyNavigationDrawerSubtitle(context),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cycleNavigationIntent();
                },
              ),
            ),
            SwitchListTile(
              secondary: Icon(
                Icons.quiz_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(loc.placeRecallDrawerTitle),
              subtitle: Text(
                loc.placeRecallDrawerSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _placeRecallGloballyEnabled,
              onChanged: _setPlaceRecallGloballyEnabled,
            ),
            _drawerSection(context, loc.sectionHelp),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(loc.helpGuideTitle),
              subtitle: Text(
                loc.helpGuideGkHint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const AlexandriaHelpPage(),
                  ),
                );
              },
            ),
            if (Platform.isWindows ||
                Platform.isMacOS ||
                Platform.isLinux)
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(loc.launcherDiagnosticsTitle),
                subtitle: Text(loc.launcherDiagnosticsSubtitle),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  final dir = AlexandriaPaths.sharedDiagnosticsDirectory;
                  try {
                    Directory(dir).createSync(recursive: true);
                  } catch (_) {}
                  final ok = await AlexandriaPaths.openDirectoryInFileManager(
                    dir,
                  );
                  if (!context.mounted) return;
                  if (!ok) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(loc.siblingAppMissingShort)),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(loc.appDiagnosticsLogTitle),
              subtitle: Text(loc.appDiagnosticsLogSubtitle),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                final p = AlexandriaAppLog.logFilePath;
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: p));
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(loc.appDiagnosticsPathCopied)),
                );
              },
            ),
            _drawerSection(context, loc.sectionReading),
            ListTile(
              leading: const Icon(Icons.chrome_reader_mode_outlined),
              title: Text(loc.nodeReaderTitle),
              subtitle: Text(loc.nodeReaderSubtitle),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                LbPdfExport.showNodeCardKeyDialog(context, d);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(loc.pdfNodeTitle),
              subtitle: Text(loc.pdfNodeSubtitle),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                LbPdfExport.showObjectPdfDialog(context, d);
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: Text(loc.pdfParcourTitle),
              subtitle: Text(loc.pdfParcourSubtitle),
              onTap: () {
                Navigator.pop(context);
                if (d == null) return;
                LbPdfExport.showParcourPdfDialog(context, d);
              },
            ),
            _drawerSection(context, loc.sectionImport),
            ListTile(
              leading: const Icon(Icons.sync_alt),
              title: Text(loc.importLocusTitle),
              subtitle: Text(loc.importLocusSubtitle),
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
          ],
        ),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.appTitle),
            Text(
              _mainShell == _LbMainShell.matchCards
                  ? loc.matchCardsTitle
                  : _parentBreadcrumbLabel(context, _currentParentKey),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        leadingWidth: _mainShell == _LbMainShell.matchCards
            ? 56
            : (_currentParentKey == 'ROOT' ? 56 : 112),
        automaticallyImplyLeading: false,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: AppLocalizations.of(ctx)!.menuTooltip,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            if (_mainShell == _LbMainShell.realmTree &&
                _currentParentKey != 'ROOT')
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: AppLocalizations.of(context)!.backTooltip,
                onPressed: _goBack,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: AppLocalizations.of(context)!.searchTooltip,
            onPressed: _openObjectSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context)!.refreshTooltip,
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SegmentedButton<_LbMainShell>(
                segments: [
                  ButtonSegment<_LbMainShell>(
                    value: _LbMainShell.realmTree,
                    label: Text(loc.librarySurfaceRealmTree),
                    icon: const Icon(Icons.account_tree_outlined),
                  ),
                  ButtonSegment<_LbMainShell>(
                    value: _LbMainShell.matchCards,
                    label: Text(loc.matchCardsTitle),
                    icon: const Icon(Icons.style_outlined),
                  ),
                ],
                selected: <_LbMainShell>{_mainShell},
                onSelectionChanged: (Set<_LbMainShell> next) {
                  if (next.isEmpty) return;
                  setState(() => _mainShell = next.first);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_mainShell == _LbMainShell.realmTree) _buildStatsStrip(context),
          Expanded(
            child: _buildHomeMainBody(context, loc),
          ),
        ],
      ),
    );
  }

  /// Contenido principal: carga, árbol del realm o Match cards incrustado (misma DB).
  Widget _buildHomeMainBody(BuildContext context, AppLocalizations loc) {
    final d = _db;
    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_mainShell == _LbMainShell.matchCards) {
      return MatchCardsPage(
        key: const ValueKey<String>('lb_embed_match_cards'),
        db: d,
        embedded: true,
      );
    }
    if (_rows.isEmpty) {
      return Center(
        child: Text(
          loc.emptyLevelMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }
    return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final l = AppLocalizations.of(context)!;
                      final row = _rows[i];
                      final key = row['key'] as String;
                      final roleKey = normalizeCognitiveRole(row['cognitiveRole']);
                      final reviewed = _formatLastReviewedAt(
                        l,
                        row['last_reviewed_at'] as String?,
                      );
                      final ridiculousPreview =
                          _firstRidiculousStoryPreview(row['body_text'] as String?);
                      return Tooltip(
                        message: roleKey == 'object'
                            ? l.tooltipDoubleTapObject
                            : l.tooltipDoubleTapEnter,
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
                                      ? l.tooltipRoleObject
                                      : l.tooltipRoleEnter,
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
                                        _displayLabel(context, row),
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
                                            _roleBadgeLabel(
                                              context,
                                              row['cognitiveRole'],
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                          Text(
                                            l.lastReviewPrefix(reviewed),
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
                                              l.duePrefix(
                                                _formatDueTag(
                                                  l,
                                                  row['next_review_at']
                                                      as String?,
                                                ),
                                              ),
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
                                        const SizedBox(height: 8),
                                        ParcourFibTimelineStrip(
                                          fibIndex: (row['locus_fib_index'] is int)
                                              ? row['locus_fib_index'] as int
                                              : int.tryParse(
                                                      '${row['locus_fib_index']}',
                                                    ) ??
                                                    0,
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        l.keySeqLine(
                                          key,
                                          '${row['seq']}',
                                        ),
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
                                      child: Text(l.edit),
                                    ),
                                    if (roleKey == 'object')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.drive_file_move_outline,
                                        ),
                                        tooltip: l.moveObjectTooltip,
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
                                    tooltip: l.moveParcourTooltip,
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    onPressed: () =>
                                        _promptMoveParcour(context, key),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.school),
                                    tooltip: l.studyTooltip,
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
                                        child: Text(l.reviewAgain),
                                      ),
                                      TextButton(
                                        onPressed: () => _reviewEntry(key, 1),
                                        child: Text(l.reviewHard),
                                      ),
                                      TextButton(
                                        onPressed: () => _reviewEntry(key, 2),
                                        child: Text(l.reviewGood),
                                      ),
                                      TextButton(
                                        onPressed: () => _reviewEntry(key, 3),
                                        child: Text(l.reviewEasy),
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
                  );
  }
}
