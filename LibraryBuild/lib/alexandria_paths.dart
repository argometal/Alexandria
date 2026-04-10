import 'dart:io';

/// Raíz del repo en Windows (mismo contrato que GateKeeper).
const String kAlexandriaRepoRoot = r'C:\Alexandria';

const String _activeRealmRelative = r'data/active_realm.txt';

/// Un **realm** = una carpeta bajo `data/realms/<id>/` con su propia DB y artefactos (420 nodos de contenido + techo ROOT en DB; ver ORM).
class AlexandriaPaths {
  AlexandriaPaths._();

  static String get _activeRealmFile =>
      '$kAlexandriaRepoRoot/$_activeRealmRelative';

  /// Solo `[a-zA-Z0-9_.-]`; vacío o inválido → `default`.
  static String sanitizeRealmId(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return 'default';
    t = t.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    if (t.isEmpty || t == '.' || t == '..') return 'default';
    return t;
  }

  static String readActiveRealmId() {
    try {
      final f = File(_activeRealmFile);
      if (!f.existsSync()) return 'default';
      final t = f.readAsStringSync().trim();
      return t.isEmpty ? 'default' : sanitizeRealmId(t);
    } catch (_) {
      return 'default';
    }
  }

  static void writeActiveRealmId(String id) {
    final f = File(_activeRealmFile);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(sanitizeRealmId(id));
  }

  /// Carpeta de datos del realm activo (o [realmId] si se pasa): `data/realms/<id>/`.
  static String realmDataRoot([String? realmId]) {
    final id = sanitizeRealmId(realmId ?? readActiveRealmId());
    return '$kAlexandriaRepoRoot/data/realms/$id';
  }

  static String get dbPath => '${realmDataRoot()}/alexandria.db';

  static String get bridgeDir => '${realmDataRoot()}/bridge';
  static String get refreshNowPath => '$bridgeDir/refresh_now.txt';
  static String get bridgeCurrentSeqPath => '$bridgeDir/current_seq.txt';
  static String get bridgeLastPositionPath => '$bridgeDir/last_position.json';
  static String get contextKeyPath => '$bridgeDir/context_key.txt';
  static String get focusKeyPath => '$bridgeDir/focus_key.txt';

  static String get snapshotRoot => '${realmDataRoot()}/snapshot';
  /// Mismo snapshot que consume GK (`Spawner`) tras migración por-realm.
  static String get snapshotCurrentJsonPath => '${realmDataRoot()}/snapshot/current.json';

  static String get viewerRoot => '${realmDataRoot()}/viewer';
  static String get wallManifestRoot => '${realmDataRoot()}/manifests/wall';
  static String get assetsRoot => '${realmDataRoot()}/assets';
  static String get navigationRoot => '${realmDataRoot()}/navigation';
  static String get navigationTmpRoot => '${realmDataRoot()}/navigation.tmp';

  static Directory get realmsParentDir => Directory('$kAlexandriaRepoRoot/data/realms');

  /// Lista carpetas en `data/realms/` (ids saneados existentes).
  static List<String> listRealmIds() {
    final p = realmsParentDir;
    if (!p.existsSync()) {
      return [readActiveRealmId()];
    }
    final out = <String>[];
    for (final e in p.listSync()) {
      if (e is! Directory) continue;
      final norm = e.path.replaceAll('\\', '/');
      final name = norm.contains('/') ? norm.split('/').last : norm;
      if (name.isEmpty) continue;
      out.add(name);
    }
    out.sort();
    return out.isEmpty ? ['default'] : out;
  }

  /// Si `data/alexandria.db` existe y `data/realms/default/alexandria.db` no, copia DB y subcarpetas conocidas al realm `default`. Crea `active_realm.txt`.
  static void ensureMigratedToRealmLayout() {
    final defaultRealm = Directory(realmDataRoot('default'));
    defaultRealm.createSync(recursive: true);

    final active = File(_activeRealmFile);
    if (!active.existsSync()) {
      writeActiveRealmId('default');
    }

    final legacyDb = File('$kAlexandriaRepoRoot/data/alexandria.db');
    final targetDb = File('${defaultRealm.path}/alexandria.db');
    if (targetDb.existsSync()) return;
    if (!legacyDb.existsSync()) return;

    try {
      legacyDb.copySync(targetDb.path);
      _copyDirIfExists(
        Directory('$kAlexandriaRepoRoot/data/bridge'),
        Directory('${defaultRealm.path}/bridge'),
      );
      _copyDirIfExists(
        Directory('$kAlexandriaRepoRoot/data/snapshot'),
        Directory('${defaultRealm.path}/snapshot'),
      );
      _copyDirIfExists(
        Directory('$kAlexandriaRepoRoot/data/viewer'),
        Directory('${defaultRealm.path}/viewer'),
      );
      _copyDirIfExists(
        Directory('$kAlexandriaRepoRoot/data/assets'),
        Directory('${defaultRealm.path}/assets'),
      );
      _copyDirIfExists(
        Directory('$kAlexandriaRepoRoot/data/navigation'),
        Directory('${defaultRealm.path}/navigation'),
      );
      _copyDirIfExists(
        Directory('$kAlexandriaRepoRoot/data/manifests'),
        Directory('${defaultRealm.path}/manifests'),
      );
      final legacySnapCurrent = File('$kAlexandriaRepoRoot/snapshot/current.json');
      if (legacySnapCurrent.existsSync()) {
        final dst = File('${defaultRealm.path}/snapshot/current.json');
        dst.parent.createSync(recursive: true);
        legacySnapCurrent.copySync(dst.path);
      }
      // ignore: avoid_print
      print('[LB][MIGRATE] flat data/ → data/realms/default/');
    } catch (e, st) {
      // ignore: avoid_print
      print('[LB][MIGRATE_ERR] $e\n$st');
    }
  }

  static void _copyDirIfExists(Directory src, Directory dst) {
    if (!src.existsSync()) return;
    dst.createSync(recursive: true);
    for (final entity in src.listSync(recursive: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      if (entity is Directory) {
        _copyDirIfExists(entity, Directory('${dst.path}/$name'));
      } else if (entity is File) {
        entity.copySync('${dst.path}/$name');
      }
    }
  }

  /// Nuevo realm: copia [templateRealmId] (p.ej. `default`) a [newId] si existe plantilla.
  static bool duplicateRealm({required String newId, String templateRealmId = 'default'}) {
    final id = sanitizeRealmId(newId);
    if (id == sanitizeRealmId(templateRealmId)) return false;
    final srcRoot = Directory(realmDataRoot(templateRealmId));
    final dstRoot = Directory(realmDataRoot(id));
    if (!srcRoot.existsSync()) return false;
    if (dstRoot.existsSync()) return false;
    try {
      _copyDirIfExists(srcRoot, dstRoot);
      // ignore: avoid_print
      print('[LB][REALM_DUP] $templateRealmId → $id');
      return true;
    } catch (e, st) {
      // ignore: avoid_print
      print('[LB][REALM_DUP_ERR] $e\n$st');
      return false;
    }
  }
}
