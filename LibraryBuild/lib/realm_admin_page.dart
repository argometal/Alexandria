import 'package:flutter/material.dart';

import 'alexandria_paths.dart';
import 'library_build.dart';
import 'realm_shelf.dart';

/// Un **realm** = `data/realms/<ruta>/` (p.ej. `default` o `Lab/experimento`) con `alexandria.db` y artefactos (~420 nodos + ROOT en DB; ORM).
class RealmAdminPage extends StatefulWidget {
  const RealmAdminPage({super.key, required this.onRealmChanged});

  final VoidCallback onRealmChanged;

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
    final prefix = _tabController.index == 0 ? _navPrefix : '';
    final path = AlexandriaPaths.realmsPrefixAbsolutePath(prefix);
    try {
      final ok = await AlexandriaPaths.openDirectoryInFileManager(path);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Esa carpeta no existe en disco.\nRaíz resuelta: ${AlexandriaPaths.repoRoot}\nRuta intentada:\n$path',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Explorador: $e\n$path')),
      );
    }
  }

  Future<void> _openExplorerForRealmPath(String fullPathId) async {
    final path = AlexandriaPaths.realmsPrefixAbsolutePath(fullPathId);
    try {
      final ok = await AlexandriaPaths.openDirectoryInFileManager(path);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Carpeta inexistente:\n$path')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir: $e')),
      );
    }
  }

  Future<void> _onCreateEmptySubfolder(BuildContext context) async {
    final ctrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Carpeta vacía'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Solo organización (sin alexandria.db). '
                'Se crea bajo:\n${AlexandriaPaths.realmsPrefixAbsolutePath(_navPrefix)}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre de carpeta',
                  hintText: 'ej. Lab o Clientes_2026',
                  helperText: 'Un segmento; sin /',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      final name = ctrl.text.trim();
      if (name.isEmpty) return;
      if (RegExp(r'[/\\]').hasMatch(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usa un solo nombre sin /')),
        );
        return;
      }
      final created = AlexandriaPaths.createRealmsSubfolderOnly(
        parentPrefix: _navPrefix,
        segment: name,
      );
      if (!created) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo crear (¿ya existe un realm con DB ahí, o nombre inválido?).',
            ),
          ),
        );
        return;
      }
      _reloadShelf();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carpeta creada')),
      );
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = AlexandriaPaths.readActiveRealmId();
    final ids = AlexandriaPaths.listRealmIds();
    RealmShelfStore.reconcile(ids, current);
    final shelf = RealmShelfStore.read();
    final cs = Theme.of(context).colorScheme;
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
              t.label,
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
            if (isActive) Icon(Icons.check_circle, color: cs.primary),
            IconButton(
              tooltip: 'Abrir carpeta en el explorador',
              icon: const Icon(Icons.folder_open, size: 22),
              onPressed: () => _openExplorerForRealmPath(id),
            ),
            PopupMenuButton<RealmShelfTier>(
              tooltip: 'Mover de estante',
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: RealmShelfTier.core, child: Text('Core — núcleo')),
                PopupMenuItem(value: RealmShelfTier.active, child: Text('Active — regular')),
                PopupMenuItem(value: RealmShelfTier.seek, child: Text('Seek — resto')),
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
          'Solo un realm activo a la vez (GK lee `data/active_realm.txt`). '
          'Core / Active / Seek son estantes de prioridad (no son carpetas físicas).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SegmentedButton<RealmShelfTier?>(
          multiSelectionEnabled: false,
          segments: const [
            ButtonSegment<RealmShelfTier?>(
              value: null,
              label: Text('Todos'),
              icon: Icon(Icons.view_agenda_outlined, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.core,
              label: Text('Core'),
              icon: Icon(Icons.bolt_outlined, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.active,
              label: Text('Active'),
              icon: Icon(Icons.autorenew, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.seek,
              label: Text('Seek'),
              icon: Icon(Icons.travel_explore_outlined, size: 18),
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
          'Activo: $current',
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
            RealmShelfTier.core => 'Lo más importante / usado',
            RealmShelfTier.active => 'Realms de trabajo habitual',
            RealmShelfTier.seek => 'Cola larga y experimentación',
          },
        ),
      );
      if (list.isEmpty) {
        shelfChildren.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Vacío',
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
                      'Raíz (sin subcarpeta)',
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
          'Lista lo que hay en disco bajo data/realms/ de la raíz resuelta (no es “inventado”). '
          'Realm = carpeta con alexandria.db. Mover muchas carpetas: mejor con apps cerradas si la DB está en uso.',
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
              'Raíz del repo (env ALEXANDRIA_ROOT, o búsqueda desde el .exe, o C:\\\\Alexandria si tiene data/realms):',
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
              'Carpeta realms (debe coincidir con lo que abre el explorador):',
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
                label: const Text('data/realms'),
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
          segments: const [
            ButtonSegment<RealmShelfTier?>(
              value: null,
              label: Text('Todos'),
              icon: Icon(Icons.filter_alt_off_outlined, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.core,
              label: Text('Core'),
              icon: Icon(Icons.bolt_outlined, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.active,
              label: Text('Active'),
              icon: Icon(Icons.autorenew, size: 18),
            ),
            ButtonSegment<RealmShelfTier?>(
              value: RealmShelfTier.seek,
              label: Text('Seek'),
              icon: Icon(Icons.travel_explore_outlined, size: 18),
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
          'Activo: $current',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    ];

    if (folderChildren.isEmpty) {
      folderBody.add(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Carpeta vacía.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
          ),
        ),
      );
    }

    for (final c in folderChildren) {
      final tier = shelf[c.fullPathId];
      final tierLabel = tier?.label ?? '—';

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
                Text('Estante: $tierLabel', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.hasSubdirectories)
                  IconButton(
                    tooltip: 'Entrar en subcarpetas',
                    icon: const Icon(Icons.drive_file_move_rtl),
                    onPressed: () => setState(() => _navPrefix = c.fullPathId),
                  ),
                if (isActive) Icon(Icons.check_circle, color: cs.primary),
                IconButton(
                  tooltip: 'Abrir carpeta en el explorador',
                  icon: const Icon(Icons.folder_open, size: 22),
                  onPressed: () => _openExplorerForRealmPath(c.fullPathId),
                ),
                PopupMenuButton<RealmShelfTier>(
                  tooltip: 'Estante',
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: RealmShelfTier.core, child: Text('Core')),
                    PopupMenuItem(value: RealmShelfTier.active, child: Text('Active')),
                    PopupMenuItem(value: RealmShelfTier.seek, child: Text('Seek')),
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
            subtitle: const Text('Carpeta sin alexandria.db ni subcarpetas'),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Realms'),
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
              tooltip: 'Carpeta vacía (solo organización, sin realm)',
              icon: const Icon(Icons.create_new_folder_outlined),
              onPressed: () => _onCreateEmptySubfolder(context),
            ),
          IconButton(
            tooltip: 'Actualizar lista',
            icon: const Icon(Icons.refresh),
            onPressed: _reloadShelf,
          ),
          IconButton(
            tooltip: 'Abrir esta carpeta en el explorador',
            icon: const Icon(Icons.open_in_new),
            onPressed: _openExplorerForContext,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.folder_outlined), text: 'Carpetas'),
            Tab(icon: Icon(Icons.view_agenda_outlined), text: 'Estantes'),
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
        label: const Text('Nuevo realm'),
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
            final templates = AlexandriaPaths.listRealmIds();
            final tList = templates.isEmpty ? <String>['default'] : templates;
            if (!tList.contains(templateId)) {
              templateId = tList.first;
            }

            return AlertDialog(
              title: const Text('Nuevo realm'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: folderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Carpeta opcional',
                        hintText: 'ej. Lab o Clientes/2026',
                        helperText: 'Bajo data/realms/; vacío = raíz. En Carpetas se rellena con la vista actual.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: idCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Id del realm',
                        hintText: 'ej. mi_castillo',
                        helperText: 'Un solo nombre; sin /',
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<bool>(
                      title: const Text('Copiar desde plantilla'),
                      subtitle: const Text(
                        'Duplica DB, bridge, snapshot, assets… de otro realm.',
                      ),
                      value: false,
                      groupValue: empty,
                      onChanged: (_) =>
                          setDialogState(() => empty = false),
                    ),
                    RadioListTile<bool>(
                      title: const Text('Vacío (misma arquitectura)'),
                      subtitle: const Text(
                        'Mismo árbol fijo (20 parcours + 400 objetos bajo PARCOUR_MAIN), '
                        'pero sin texto en loci, sin recall/review y assets vacío.',
                      ),
                      value: true,
                      groupValue: empty,
                      onChanged: (_) => setDialogState(() => empty = true),
                    ),
                    if (!empty) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: templateId,
                        decoration: const InputDecoration(
                          labelText: 'Plantilla',
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
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        ),
      );

      if (ok != true || !context.mounted) return;
      final leaf = idCtrl.text.trim();
      final folderRaw = folderCtrl.text.trim();
      if (leaf.isEmpty) return;
      if (RegExp(r'[/\\]').hasMatch(leaf)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El id del realm no puede contener / ni \\.'),
          ),
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
                  ? 'No se pudo crear vacío (¿ruta duplicada o error al escribir?).'
                  : 'No se pudo copiar (¿plantilla inexistente, ruta duplicada?).',
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
              'Realm activo: ${AlexandriaPaths.readActiveRealmId()}',
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
}
