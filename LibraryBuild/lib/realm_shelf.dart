import 'dart:convert';
import 'dart:io';

import 'alexandria_paths.dart';

/// Estante de realms en LibraryBuild: Core (prioritario), Active (uso regular), Seek (resto).
enum RealmShelfTier {
  core,
  active,
  seek,
}

extension RealmShelfTierLabel on RealmShelfTier {
  String get label => switch (this) {
        RealmShelfTier.core => 'Core',
        RealmShelfTier.active => 'Active',
        RealmShelfTier.seek => 'Seek',
      };
}

/// `data/realm_shelf.json` en la raíz del repo (no por-realm).
class RealmShelfStore {
  RealmShelfStore._();

  static String get _path => '${AlexandriaPaths.repoRoot}/data/realm_shelf.json';

  static Map<String, RealmShelfTier> read() {
    try {
      final f = File(_path);
      if (!f.existsSync()) return {};
      final j = jsonDecode(f.readAsStringSync());
      if (j is! Map) return {};
      final out = <String, RealmShelfTier>{};
      for (final e in j.entries) {
        final k = e.key.toString().trim();
        if (k.isEmpty) continue;
        final v = _parseTier(e.value?.toString());
        if (v != null) out[AlexandriaPaths.sanitizeRealmPath(k)] = v;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static RealmShelfTier? _parseTier(String? s) {
    final t = s?.trim().toLowerCase() ?? '';
    return switch (t) {
      'core' => RealmShelfTier.core,
      'active' => RealmShelfTier.active,
      'seek' => RealmShelfTier.seek,
      _ => null,
    };
  }

  static void write(Map<String, RealmShelfTier> map) {
    final f = File(_path);
    f.parent.createSync(recursive: true);
    final serial = <String, String>{};
    final keys = map.keys.toList()..sort();
    for (final k in keys) {
      serial[k] = switch (map[k]!) {
        RealmShelfTier.core => 'core',
        RealmShelfTier.active => 'active',
        RealmShelfTier.seek => 'seek',
      };
    }
    f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(serial));
  }

  /// Asigna tiers por defecto a realms nuevos; conserva asignaciones existentes.
  static void reconcile(List<String> realmIds, String activeRealmId) {
    final sorted = List<String>.from(realmIds)..sort();
    final cur = read();
    final next = <String, RealmShelfTier>{};
    for (final id in sorted) {
      if (cur.containsKey(id)) {
        next[id] = cur[id]!;
      } else {
        if (id == activeRealmId) {
          next[id] = RealmShelfTier.active;
        } else if (id == 'default') {
          next[id] = RealmShelfTier.core;
        } else {
          next[id] = RealmShelfTier.seek;
        }
      }
    }
    write(next);
  }

  static void setTier(String realmId, RealmShelfTier tier) {
    final id = AlexandriaPaths.sanitizeRealmPath(realmId);
    final m = read();
    m[id] = tier;
    write(m);
  }
}
