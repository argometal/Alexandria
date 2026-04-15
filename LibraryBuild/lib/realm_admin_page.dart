import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'usage_tier_l10n.dart';
import 'alexandria_paths.dart';
import 'library_build.dart';
import 'realm_shelf.dart';

/// Un **realm** = `data/realms/<ruta>/` (p.ej. `default` o `Lab/experimento`) con `alexandria.db` y artefactos (~420 nodos + ROOT en DB; ORM).
class RealmAdminPage extends StatefulWidget {
  const RealmAdminPage({
    super.key,
    required this.onRealmChanged,
    required this.onNuclearDataReset,
    required this.onRegenerateRealmSeed,
    this.onReleaseDatabase,
  });

  final VoidCallback onRealmChanged;

  /// Cerrar SQLite antes de mover/renombrar carpetas bajo `data/realms/` (obligatorio para integridad).
  final VoidCallback? onReleaseDatabase;

  /// Padre cierra la DB, ejecuta [performAlexandriaNuclearDataResetSync] y reabre.
  final Future<void> Function() onNuclearDataReset;

  /// Padre cierra la DB, ejecuta [regenerateRealmSeedFromActiveRealmSync] y reabre.
  final Future<void> Function() onRegenerateRealmSeed;

  @override
  State<RealmAdminPage> createState() => _RealmAdminPageState();
}

class _RealmAdminPageState extends State<RealmAdminPage>
    with SingleTickerProviderStateMixin {
  /// `null` = todos los estantes.
  RealmShelfTier? _tierFilter;

  /// Prefijo sanitizado bajo `data/realms/` (`''` = raíz). Solo pestaña Carpetas.
  String _navPrefix = '';

  late TabController _tabController;

  void _reloadShelf() {
    final ids = AlexandriaPaths.listRealmIds();
    RealmShelfStore.reconcile(ids, AlexandriaPaths.readActiveRealmId());
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (mounted) setState(() {});
    });
    _reloadShelf();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _realmsForTier(Map<String, RealmShelfTier> shelf, RealmShelfTier t) {
    return shelf.entries.where((e) => e.value == t).map((e) => e.key).toList()
      ..sort();
  }

  String? _topFolder(String path) {
    final p = path.split('/').where((s) => s.isNotEmpty).toList();
    if (p.length <= 1) return null;
    return p.first;
  }

  String _leafName(String path) {
    final p = path.split('/').where((s) => s.isNotEmpty).toList();
    return p.isEmpty ? path : p.last;
  }

  List<MapEntry<String?, List<String>>> _groupByFolder(List<String> paths) {
    final map = <String?, List<String>>{};
    for (final p in paths) {
      map.putIfAbsent(_topFolder(p), () => []).add(p);
    }
    for (final list in map.values) {
      list.sort();
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return -1;
        if (b == null) return 1;
        return a.compareTo(b);
      });
    return [for (final k in keys) MapEntry(k, map[k]!)];
  }

  bool _tierVisible(String realmId, Map<String, RealmShelfTier> shelf) {
    if (_tierFilter == null) return true;
    return (shelf[realmId] ?? RealmShelfTier.seek) == _tierFilter;
  }

  void _popNavPrefix() {
    final parts = _navPrefix.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return;
    parts.removeLast();
    setState(() {
      _navPrefix = parts.join('/');
    });
  }

  Future<void> _openExplorerForContext() async {
    final l = AppLocalizations.of(context)!;
    final prefix = _tabController.index == 0 ? _navPrefix : '';
    final path = AlexandriaPaths.realmsPrefixAbsolutePath(prefix);
    try {
      final ok = await AlexandriaPaths.openDirectoryInFileManager(path);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l.realmAdminExplorerMissingFolder(AlexandriaPaths.repoRoot, path),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.realmAdminExplorerError(e.toString(), path))),
      );
    }
  }

  Future<void> _openExplorerForRealmPath(String fullPathId) async {
    final l = AppLocalizations.of(context)!;
    final path = AlexandriaPaths.realmsPrefixAbsolutePath(fullPathId);
    try {
      final ok = await AlexandriaPaths.openDirectoryInFileManager(path);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.realmAdminFolderMissing(path))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.realmAdminOpenFailed(e.toString()))),
      );
    }
  }

  Future<void> _onCreateEmptySubfolder(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final dl = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(dl.realmAdminEmptyFolderDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dl.realmAdminEmptyFolderBody(
                    AlexandriaPaths.realmsPrefixAbsolutePath(_navPrefix),
                  ),
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: dl.realmAdminEmptyFolderNameLabel,
                    hintText: dl.realmAdminEmptyFolderNameHint,
                    helperText: dl.realmAdminEmptyFolderNameHelper,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(dl.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(dl.realmDialogCreate),
              ),
            ],
          );
        },
      );
      if (ok != true || !context.mounted) return;
      final name = ctrl.text.trim();
      if (name.isEmpty) return;
      if (RegExp(r'[/\\]').hasMatch(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.realmAdminSnackbarSingleSegment)),
        );
        return;
      }
      final created = AlexandriaPaths.createRealmsSubfolderOnly(
        parentPrefix: _navPrefix,
        segment: name,
      );
      if (!created) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.realmAdminSnackbarSubfolderCreateFailed)),
        );
        return;
      }
      _reloadShelf();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.realmAdminSnackbarFolderCreated)),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _promptMoveRealm(BuildContext context, String realmId) async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: realmId);
    final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.realmAdminMoveRealmTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.realmAdminMoveRealmBody,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l.realmAdminMoveRealmTargetLabel,
                    ),
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
                child: Text(l.realmAdminMoveRealmButton),
              ),
            ],
          ),
        ) ??
        false;
    final raw = ctrl.text.trim();
    ctrl.dispose();
    if (!proceed || !context.mounted) return;
    final to = AlexandriaPaths.sanitizeRealmPath(raw);
    if (to.isEmpty || to == realmId) return;

    widget.onReleaseDatabase?.call();
    var moved = false;
    try {
      moved = AlexandriaPaths.moveRealmDataDirectory(realmId, to);
      if (moved) {
        RealmShelfStore.renameRealmKey(realmId, to);
        if (AlexandriaPaths.readActiveRealmId() == realmId) {
          AlexandriaPaths.writeActiveRealmId(to);
        }
      }
    } catch (_) {
      moved = false;
    } finally {
      widget.onRealmChanged();
    }
    if (!context.mounted) return;
    if (moved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.realmAdminMoveRealmOk(to))),
      );
      _reloadShelf();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.realmAdminMoveRealmFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = AlexandriaPaths.readActiveRealmId();
    final ids = AlexandriaPaths.listRealmIds();
    RealmShelfStore.reconcile(ids, current);
    final shelf = RealmShelfStore.read();
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final folderMode = _tabController.index == 0;
    final showNavBack = folderMode && _navPrefix.isNotEmpty;

    Widget tierHeader(RealmShelfTier t, String subtitle) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            Icon(
              switch (t) {
                RealmShelfTier.core => Icons.bolt_outlined,
                RealmShelfTier.active => Icons.autorenew,
                RealmShelfTier.seek => Icons.travel_explore_outlined,
              },
              size: 20,
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10nRealmShelfTierShort(l, t),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    Widget realmTile(String id) {
      final isActive = id == current;
      return ListTile(
        title: Text(_leafName(id)),
        subtitle: id.contains('/')
            ? Text(
                id,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              tooltip: l.realmAdminTooltipMoveRealm,
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'move',
                  child: Text(l.realmAdminMoveRealmMenu),
                ),
              ],
              onSelected: (v) {
                if (v == 'move') _promptMoveRealm(context, id);
              },
            ),
            if (isActive) Icon(Icons.check_circle, color: cs.primary),
            IconButton(
              tooltip: l.realmAdminTooltipOpenRealmFolder,
              icon: const Icon(Icons.folder_open, size: 22),
              onPressed: () => _openExplorerForRealmPath(id),
            ),
            PopupMenuButton<RealmShelfTier>(
              tooltip: l.realmAdminTooltipMoveShelf,
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: RealmShelfTier.core,
                  child: Text(l10nRealmShelfPopup(l, RealmShelfTier.core)),
                ),
                PopupMenuItem(
                  value: RealmShelfTier.active,
                  child: Text(l10nRealmShelfPopup(l, RealmShelfTier.active)),
                ),
                PopupMenuItem(
                  value: RealmShelfTier.seek,
                  child: Text(l10nRealmShelfPopup(l, RealmShelfTier.seek)),
                ),
              ],
              onSelected: (tier) {
                RealmShelfStore.setTier(id, tier);
                setState(() {});
              },
            ),
          ],
        ),
        onTap: () {
          AlexandriaPaths.writeActiveRealmId(id);
          widget.onRealmChanged();
          Navigator.of(context).pop();
        },
      );
    }

    final tiersToShow = _tierFilter == null
        ? RealmShelfTier.values.toList()
        : [_tierFilter!];

    final shelfChildren = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          l.realmAdminShelvesIntro,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SegmentedButton<RealmShelfTier?>(
          multiSelectionEnabled: false,
          segments: [
            ButtonSegment<RealmShelfTier?>(
              value: null,
              label: Text(l.usageBandAll),
              icon: const Icon(Icons.view_agenda_outlined, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.core,
              label: Text(l.usageBandCore),
              icon: const Icon(Icons.bolt_outlined, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.active,
              label: Text(l.usageBandActive),
              icon: const Icon(Icons.autorenew, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.seek,
              label: Text(l.usageBandSeek),
              icon: const Icon(Icons.travel_explore_outlined, size: 18),
            ),
          ],
          selected: {_tierFilter},
          emptySelectionAllowed: true,
          onSelectionChanged: (s) {
            setState(() {
              _tierFilter = s.isEmpty ? null : s.first;
            });
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          l.realmAdminActiveLine(current),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ];

    for (final t in tiersToShow) {
      final list = _realmsForTier(shelf, t);
      if (list.isEmpty && _tierFilter != null) continue;
      shelfChildren.add(
        tierHeader(
          t,
          switch (t) {
            RealmShelfTier.core => l.realmAdminTierHeaderCore,
            RealmShelfTier.active => l.realmAdminTierHeaderActive,
            RealmShelfTier.seek => l.realmAdminTierHeaderSeek,
          },
        ),
      );
      if (list.isEmpty) {
        shelfChildren.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              l.realmAdminEmptyTier,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.outline,
                  ),
            ),
          ),
        );
      } else {
        final groups = _groupByFolder(list);
        for (final g in groups) {
          final folder = g.key;
          final items = g.value;
          if (folder != null) {
            shelfChildren.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 18, color: cs.secondary),
                    const SizedBox(width: 8),
                    Text(
                      folder,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            );
          } else if (groups.length > 1) {
            shelfChildren.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.folder_open_outlined, size: 18, color: cs.outline),
                    const SizedBox(width: 8),
                    Text(
                      l.realmAdminRootGroupLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }
          for (final id in items) {
            shelfChildren.add(realmTile(id));
          }
        }
      }
    }

    final folderChildren = AlexandriaPaths.listImmediateFolderChildren(_navPrefix);
    final folderBody = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          l.realmAdminFolderIntro,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.realmAdminRepoRootCaption,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              AlexandriaPaths.repoRoot,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l.realmAdminRealmsFolderCaption,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            SelectableText(
              AlexandriaPaths.realmsParentDir.path,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Builder(
          builder: (context) {
            final crumbs = <Widget>[
              ActionChip(
                avatar: const Icon(Icons.home, size: 18),
                label: Text(l.realmAdminDataRealmsChip),
                onPressed: () => setState(() => _navPrefix = ''),
              ),
            ];
            final parts = _navPrefix.split('/').where((s) => s.isNotEmpty).toList();
            var acc = '';
            for (final seg in parts) {
              acc = acc.isEmpty ? seg : '$acc/$seg';
              final prefix = acc;
              crumbs.add(const Icon(Icons.chevron_right, size: 18));
              crumbs.add(
                ActionChip(
                  label: Text(seg),
                  onPressed: () => setState(() => _navPrefix = prefix),
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: crumbs),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SegmentedButton<RealmShelfTier?>(
          multiSelectionEnabled: false,
          segments: [
            ButtonSegment<RealmShelfTier?>(
              value: null,
              label: Text(l.usageBandAll),
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.core,
              label: Text(l.usageBandCore),
              icon: const Icon(Icons.bolt_outlined, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.active,
              label: Text(l.usageBandActive),
              icon: const Icon(Icons.autorenew, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.seek,
              label: Text(l.usageBandSeek),
              icon: const Icon(Icons.travel_explore_outlined, size: 18),
            ),
          ],
          selected: {_tierFilter},
          emptySelectionAllowed: true,
          onSelectionChanged: (s) {
            setState(() {
              _tierFilter = s.isEmpty ? null : s.first;
            });
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          l.realmAdminActiveLine(current),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    ];

    if (folderChildren.isEmpty) {
      folderBody.add(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.realmAdminFolderEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
          ),
        ),
      );
    }

    for (final c in folderChildren) {
      final tier = shelf[c.fullPathId];
      final tierLabel =
          tier == null ? '—' : l10nRealmShelfTierShort(l, tier);

      if (c.hasAlexandriaDb && !_tierVisible(c.fullPathId, shelf)) {
        continue;
      }

      if (!c.hasAlexandriaDb && c.hasSubdirectories) {
        folderBody.add(
          ListTile(
            leading: Icon(Icons.folder_outlined, color: cs.secondary),
            title: Text(c.segment),
            subtitle: Text(
              c.fullPathId,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
            onTap: () => setState(() => _navPrefix = c.fullPathId),
          ),
        );
        continue;
      }

      if (c.hasAlexandriaDb) {
        final isActive = c.fullPathId == current;
        folderBody.add(
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
              child: Icon(
                Icons.storage_outlined,
                color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                size: 22,
              ),
            ),
            title: Text(c.segment),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.fullPathId,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.realmAdminShelfLabel(tierLabel),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.hasSubdirectories)
                  IconButton(
                    tooltip: l.realmAdminTooltipEnterSubfolders,
                    icon: const Icon(Icons.drive_file_move_rtl),
                    onPressed: () => setState(() => _navPrefix = c.fullPathId),
                  ),
                PopupMenuButton<String>(
                  tooltip: l.realmAdminTooltipMoveRealm,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'move',
                      child: Text(l.realmAdminMoveRealmMenu),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'move') _promptMoveRealm(context, c.fullPathId);
                  },
                ),
                if (isActive) Icon(Icons.check_circle, color: cs.primary),
                IconButton(
                  tooltip: l.realmAdminTooltipOpenRealmFolder,
                  icon: const Icon(Icons.folder_open, size: 22),
                  onPressed: () => _openExplorerForRealmPath(c.fullPathId),
                ),
                PopupMenuButton<RealmShelfTier>(
                  tooltip: l.realmAdminTooltipShelfMenu,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: RealmShelfTier.core,
                      child: Text(l.usageBandCore),
                    ),
                    PopupMenuItem(
                      value: RealmShelfTier.active,
                      child: Text(l.usageBandActive),
                    ),
                    PopupMenuItem(
                      value: RealmShelfTier.seek,
                      child: Text(l.usageBandSeek),
                    ),
                  ],
                  onSelected: (tier) {
                    RealmShelfStore.setTier(c.fullPathId, tier);
                    setState(() {});
                  },
                ),
              ],
            ),
            onTap: () {
              AlexandriaPaths.writeActiveRealmId(c.fullPathId);
              widget.onRealmChanged();
              Navigator.of(context).pop();
            },
          ),
        );
        continue;
      }

      if (!c.hasAlexandriaDb && !c.hasSubdirectories) {
        folderBody.add(
          ListTile(
            leading: Icon(Icons.folder_off_outlined, color: cs.outline),
            title: Text(c.segment),
            subtitle: Text(l.realmAdminLeafFolderWithoutDb),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.realmsTitle),
        leading: showNavBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _popNavPrefix,
              )
            : null,
        automaticallyImplyLeading: !showNavBack,
        actions: [
          if (folderMode)
            IconButton(
              tooltip: l.realmAdminTooltipEmptySubfolder,
              icon: const Icon(Icons.create_new_folder_outlined),
              onPressed: () => _onCreateEmptySubfolder(context),
            ),
          IconButton(
            tooltip: l.realmAdminTooltipRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _reloadShelf,
          ),
          IconButton(
            tooltip: l.realmAdminTooltipOpenExplorer,
            icon: const Icon(Icons.open_in_new),
            onPressed: _openExplorerForContext,
          ),
          IconButton(
            tooltip: l.realmAdminTooltipCreateSeed,
            icon: const Icon(Icons.layers_outlined),
            onPressed: () => _onRegenerateRealmSeed(context),
          ),
          IconButton(
            tooltip: l.realmAdminTooltipNuclear,
            icon: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            onPressed: () => _onNuclearDeleteAllData(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.folder_outlined), text: l.realmAdminTabFolders),
            Tab(icon: const Icon(Icons.view_agenda_outlined), text: l.realmAdminTabShelves),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: folderBody,
          ),
          ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: shelfChildren,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onNewRealm(context),
        icon: const Icon(Icons.add),
        label: Text(l.realmAdminFabCreate),
      ),
    );
  }

  Future<void> _onNewRealm(BuildContext context) async {
    final folderCtrl = TextEditingController(text: _navPrefix);
    final idCtrl = TextEditingController();
    try {
      var empty = false;
      var templateId = _firstTemplateId();

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            final dl = AppLocalizations.of(ctx)!;
            final templates = AlexandriaPaths.listRealmIds();
            final tList = templates.isEmpty ? <String>['default'] : templates;
            if (!tList.contains(templateId)) {
              templateId = tList.first;
            }

            return AlertDialog(
              title: Text(dl.realmDialogNewTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: folderCtrl,
                      decoration: InputDecoration(
                        labelText: dl.realmDialogFolderOptionalLabel,
                        hintText: dl.realmDialogFolderHint,
                        helperText: dl.realmDialogFolderHelper,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: idCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: dl.realmDialogIdLabel,
                        hintText: dl.realmDialogIdHint,
                        helperText: dl.realmDialogIdHelper,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<bool>(
                      title: Text(dl.realmDialogTemplateCopyTitle),
                      subtitle: Text(dl.realmDialogTemplateCopySubtitle),
                      value: false,
                      groupValue: empty,
                      onChanged: (_) =>
                          setDialogState(() => empty = false),
                    ),
                    RadioListTile<bool>(
                      title: Text(dl.realmDialogEmptyTitle),
                      subtitle: Text(dl.realmDialogEmptySubtitle),
                      value: true,
                      groupValue: empty,
                      onChanged: (_) => setDialogState(() => empty = true),
                    ),
                    if (!empty) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: templateId,
                        decoration: InputDecoration(
                          labelText: dl.realmDialogTemplateLabel,
                        ),
                        items: tList
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => templateId = v ?? templateId),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(dl.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(dl.realmDialogCreate),
                ),
              ],
            );
          },
        ),
      );

      if (ok != true || !context.mounted) return;
      final loc = AppLocalizations.of(context)!;
      final leaf = idCtrl.text.trim();
      final folderRaw = folderCtrl.text.trim();
      if (leaf.isEmpty) return;
      if (RegExp(r'[/\\]').hasMatch(leaf)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.realmDialogIdInvalidChars)),
        );
        return;
      }
      final combined = folderRaw.isEmpty
          ? leaf
          : '$folderRaw/$leaf';
      final realmPath = AlexandriaPaths.sanitizeRealmPath(combined);

      final created = empty
          ? createEmptyRealm(realmPath)
          : AlexandriaPaths.duplicateRealm(
              newId: realmPath,
              templateRealmId: templateId,
            );

      if (!created) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              empty
                  ? loc.realmSnackbarCreateEmptyFailed
                  : loc.realmSnackbarDuplicateFailed,
            ),
          ),
        );
        return;
      }
      RealmShelfStore.setTier(realmPath, RealmShelfTier.seek);
      AlexandriaPaths.writeActiveRealmId(realmPath);
      widget.onRealmChanged();
      try {
        runLibraryBuild();
      } catch (_) {}
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.realmSnackbarActiveRealm(AlexandriaPaths.readActiveRealmId()),
            ),
          ),
        );
      }
    } finally {
      folderCtrl.dispose();
      idCtrl.dispose();
    }
  }

  String _firstTemplateId() {
    final l = AlexandriaPaths.listRealmIds();
    if (l.isEmpty) return 'default';
    return l.first;
  }

  Future<void> _onNuclearDeleteAllData(BuildContext context) async {
    final ctrl = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final dl = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(dl.realmAdminNuclearTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dl.realmAdminNuclearDialogIntro,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    kAlexandriaNuclearDeletePhrase,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: dl.realmAdminConfirmLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(dl.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () {
                  if (ctrl.text == kAlexandriaNuclearDeletePhrase) {
                    Navigator.pop(ctx, true);
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(dl.realmAdminPhraseMismatch)),
                    );
                  }
                },
                child: Text(dl.realmAdminNuclearButton),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !context.mounted) return;
      await widget.onNuclearDataReset();
      if (!context.mounted) return;
      _reloadShelf();
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.realmAdminNuclearSuccessSnackbar)),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _onRegenerateRealmSeed(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(dl.realmSeedDialogTitle),
          content: Text(
            dl.realmSeedDialogBody(AlexandriaPaths.readActiveRealmId()),
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dl.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dl.realmSeedConfirm),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    final loc = AppLocalizations.of(context)!;
    try {
      await widget.onRegenerateRealmSeed();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.realmSeedSavedSnackbar)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.realmSeedErrorPrefix} $e')),
      );
    }
  }
}
