import 'package:flutter/material.dart';

import 'alexandria_paths.dart';
import 'library_build.dart';

/// Un **realm** = `data/realms/<id>/` con su propia `alexandria.db` y artefactos (~420 nodos de contenido + ROOT; ORM).
class RealmAdminPage extends StatelessWidget {
  const RealmAdminPage({super.key, required this.onRealmChanged});

  final VoidCallback onRealmChanged;

  @override
  Widget build(BuildContext context) {
    final current = AlexandriaPaths.readActiveRealmId();
    final realms = AlexandriaPaths.listRealmIds();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Realms'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Solo un realm activo a la vez (GK lee la misma carpeta vía active_realm). '
              'Cada carpeta ≈ un mundo (tope práctico 420 nodos de contenido bajo ROOT + techo realm en DB).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Activo: $current',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          ...realms.map(
            (id) => ListTile(
              title: Text(id),
              trailing: id == current
                  ? Icon(Icons.check_circle, color: cs.primary)
                  : null,
              onTap: () {
                AlexandriaPaths.writeActiveRealmId(id);
                onRealmChanged();
                Navigator.of(context).pop();
              },
            ),
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
                      controller: idCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Id del realm',
                        hintText: 'ej. mi_castillo',
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
      final name = idCtrl.text.trim();
      if (name.isEmpty) return;

      final created = empty
          ? createEmptyRealm(name)
          : AlexandriaPaths.duplicateRealm(
              newId: name,
              templateRealmId: templateId,
            );

      if (!created) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              empty
                  ? 'No se pudo crear vacío (¿id duplicado o error al escribir?).'
                  : 'No se pudo copiar (¿plantilla inexistente, id duplicado?).',
            ),
          ),
        );
        return;
      }
      AlexandriaPaths.writeActiveRealmId(name);
      onRealmChanged();
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
      idCtrl.dispose();
    }
  }

  String _firstTemplateId() {
    final l = AlexandriaPaths.listRealmIds();
    if (l.isEmpty) return 'default';
    return l.first;
  }
}
