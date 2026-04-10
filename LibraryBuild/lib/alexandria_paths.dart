import 'dart:io';

/// Valor por defecto si no se encuentra `data/realms/` por env ni por búsqueda (mismo ancla que GateKeeper).
const String kDefaultAlexandriaRepoRoot = r'C:\Alexandria';

const String _activeRealmRelative = r'data/active_realm.txt';

String _pathJoin(String a, String b, [String? c]) {
  final sep = Platform.pathSeparator;
  if (c == null) return '$a$sep$b';
  return '$a$sep$b$sep$c';
}

String _normalizeRepoRoot(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return Directory(kDefaultAlexandriaRepoRoot).absolute.path;
  return Directory(t).absolute.path;
}

bool _hasDataRealms(String repoRoot) {
  final realms = Directory(_pathJoin(_normalizeRepoRoot(repoRoot), 'data', 'realms'));
  return realms.existsSync();
}

String? _findRepoRootWalkingUp(Directory start) {
  var d = start;
  for (var i = 0; i < 32; i++) {
    if (_hasDataRealms(d.path)) {
      return Directory(d.path).absolute.path;
    }
    final p = d.parent;
    if (p.path == d.path) return null;
    d = p;
  }
  return null;
}

/// Hijo directo bajo un prefijo de `data/realms/` (`listImmediateFolderChildren`).
class RealmsFolderChild {
  const RealmsFolderChild({
    required this.segment,
    required this.fullPathId,
    required this.hasAlexandriaDb,
    required this.hasSubdirectories,
  });

  final String segment;
  final String fullPathId;
  final bool hasAlexandriaDb;
  final bool hasSubdirectories;
}

/// Un **realm** = una carpeta bajo `data/realms/<id>/` con su propia DB y artefactos (420 nodos de contenido + techo ROOT en DB; ver ORM).
class AlexandriaPaths {
  AlexandriaPaths._();

  static String? _repoRootCache;

  /// Raíz del repo donde existe `data/realms/`.
  ///
  /// Orden: `ALEXANDRIA_ROOT` → subir desde [Directory.current] (típico al abrir el proyecto) →
  /// subir desde el ejecutable → [kDefaultAlexandriaRepoRoot] solo si ahí existe `data/realms/` →
  /// último recurso [kDefaultAlexandriaRepoRoot].
  ///
  /// Así no se prefiere un `C:\Alexandria` vacío o viejo por encima del repo desde el que corres LB.
  static String get repoRoot {
    return _repoRootCache ??= _resolveRepoRoot();
  }

  static String _resolveRepoRoot() {
    final env = Platform.environment['ALEXANDRIA_ROOT']?.trim();
    if (env != null && env.isNotEmpty && _hasDataRealms(env)) {
      return _normalizeRepoRoot(env);
    }
    final fromCwd = _findRepoRootWalkingUp(Directory.current);
    if (fromCwd != null) return fromCwd;
    try {
      var d = File(Platform.resolvedExecutable).parent;
      for (var i = 0; i < 28; i++) {
        final w = _findRepoRootWalkingUp(d);
        if (w != null) return w;
        final p = d.parent;
        if (p.path == d.path) break;
        d = p;
      }
    } catch (_) {}
    if (_hasDataRealms(kDefaultAlexandriaRepoRoot)) {
      return _normalizeRepoRoot(kDefaultAlexandriaRepoRoot);
    }
    return _normalizeRepoRoot(kDefaultAlexandriaRepoRoot);
  }

  /// Compatibilidad: misma raíz resuelta que [repoRoot].
  static String get kAlexandriaRepoRoot => repoRoot;

  static String get _activeRealmFile =>
      '${repoRoot}/$_activeRealmRelative';

  /// Solo `[a-zA-Z0-9_.-]`; vacío o inválido → `default`.
  static String sanitizeRealmId(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return 'default';
    t = t.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    if (t.isEmpty || t == '.' || t == '..') return 'default';
    return t;
  }

  /// Ruta relativa bajo `data/realms/`, p.ej. `default` o `Trabajo/MemoryOS`.
  /// Cada segmento usa [sanitizeRealmId]; separador `/`.
  static String sanitizeRealmPath(String raw) {
    if (raw.trim().isEmpty) return 'default';
    final norm = raw.replaceAll('\\', '/').trim();
    final parts = norm
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(sanitizeRealmId)
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'default';
    return parts.join('/');
  }

  static String readActiveRealmId() {
    try {
      final f = File(_activeRealmFile);
      if (!f.existsSync()) return 'default';
      final t = f.readAsStringSync().trim();
      return t.isEmpty ? 'default' : sanitizeRealmPath(t);
    } catch (_) {
      return 'default';
    }
  }

  static void writeActiveRealmId(String id) {
    final f = File(_activeRealmFile);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(sanitizeRealmPath(id));
  }

  /// Carpeta de datos del realm activo (o [realmId] si se pasa): `data/realms/<ruta>/`.
  static String realmDataRoot([String? realmId]) {
    final rel = sanitizeRealmPath(realmId ?? readActiveRealmId());
    final parts = rel.split('/').where((s) => s.isNotEmpty).toList();
    var p = _pathJoin(repoRoot, 'data', 'realms');
    for (final seg in parts) {
      p = '$p${Platform.pathSeparator}$seg';
    }
    return p;
  }

  static String get dbPath => '${realmDataRoot()}/alexandria.db';

  /// Servidor Node en repo: `data-transfer/` → `out/`, `handoff/incoming/`.
  static String get dataTransferRoot => '${repoRoot}/data-transfer';

  /// Dataset PAO 00–99 (JSON fijo del repo; import en LB al realm activo).
  static String get paoDatasetDir => '${repoRoot}/data/pao';

  static String get paoTemplate00_99Path =>
      '$paoDatasetDir/pao_00_99.template.json';

  static String get bridgeDir => '${realmDataRoot()}/bridge';
  static String get refreshNowPath => '$bridgeDir/refresh_now.txt';
  static String get bridgeCurrentSeqPath => '$bridgeDir/current_seq.txt';
  static String get bridgeLastPositionPath => '$bridgeDir/last_position.json';
  static String get contextKeyPath => '$bridgeDir/context_key.txt';
  static String get focusKeyPath => '$bridgeDir/focus_key.txt';

  /// Intención de navegación (Explore / Review / Seek / Drift) — lectura en GateKeeper HUD.
  /// Formato: línea 1 = modo; línea 2 opcional = clave del **locus** en foco (`focus_key.txt`):
  /// place / hint / ridiculous story se interpretan sobre el **Hero** de ese mismo objeto.
  static String get navigationIntentPath => '$bridgeDir/navigation_intent.txt';

  /// Resumen de review por parcour (LB escribe; GK puede leer para color / drill-down).
  static String get parcourReviewSummaryPath =>
      '$bridgeDir/parcour_review_summary.json';

  static String get snapshotRoot => '${realmDataRoot()}/snapshot';
  /// Mismo snapshot que consume GK (`Spawner`) tras migración por-realm.
  static String get snapshotCurrentJsonPath => '${realmDataRoot()}/snapshot/current.json';

  static String get viewerRoot => '${realmDataRoot()}/viewer';
  static String get wallManifestRoot => '${realmDataRoot()}/manifests/wall';
  static String get assetsRoot => '${realmDataRoot()}/assets';
  static String get navigationRoot => '${realmDataRoot()}/navigation';
  static String get navigationTmpRoot => '${realmDataRoot()}/navigation.tmp';

  static Directory get realmsParentDir => Directory(_pathJoin(repoRoot, 'data', 'realms'));

  /// Lista realms: cualquier subcarpeta de `data/realms/` que contenga `alexandria.db`.
  /// Claves = ruta relativa con `/` (p.ej. `default`, `Lab/experimento_1`).
  static List<String> listRealmIds() {
    final p = realmsParentDir;
    if (!p.existsSync()) {
      return [readActiveRealmId()];
    }
    final out = <String>[];
    void walk(Directory d, String relativePosix) {
      final db = File('${d.path}${Platform.pathSeparator}alexandria.db');
      if (db.existsSync()) {
        out.add(sanitizeRealmPath(relativePosix.replaceAll('\\', '/')));
      }
      for (final e in d.listSync()) {
        if (e is! Directory) continue;
        final name = e.path.split(Platform.pathSeparator).last;
        if (name.isEmpty) continue;
        final nextRel =
            relativePosix.isEmpty ? name : '$relativePosix/$name';
        walk(e, nextRel);
      }
    }

    walk(p, '');
    out.sort();
    return out.isEmpty ? ['default'] : out;
  }

  /// Ruta absoluta del directorio `data/realms/` o `data/realms/<prefix>/`.
  static String realmsPrefixAbsolutePath(String prefix) {
    final s = prefix.trim().isEmpty ? '' : sanitizeRealmPath(prefix);
    if (s.isEmpty) return realmsParentDir.path;
    return realmDataRoot(s);
  }

  /// Listado inmediato (sin recursión): subcarpetas de [prefix] con banderas de DB y subcarpetas.
  static List<RealmsFolderChild> listImmediateFolderChildren(String prefix) {
    final sanitizedPrefix = prefix.trim().isEmpty ? '' : sanitizeRealmPath(prefix);
    final dir = sanitizedPrefix.isEmpty
        ? realmsParentDir
        : Directory(realmDataRoot(sanitizedPrefix));
    if (!dir.existsSync()) return [];
    final out = <RealmsFolderChild>[];
    for (final e in dir.listSync(followLinks: false)) {
      if (e is! Directory) continue;
      final name = e.path.split(Platform.pathSeparator).last;
      if (name.isEmpty || name == '.' || name == '..') continue;
      final fullId = sanitizedPrefix.isEmpty
          ? sanitizeRealmPath(name)
          : sanitizeRealmPath('$sanitizedPrefix/$name');
      final db = File('${e.path}${Platform.pathSeparator}alexandria.db');
      final hasDb = db.existsSync();
      var hasSub = false;
      for (final c in e.listSync(followLinks: false)) {
        if (c is Directory) {
          hasSub = true;
          break;
        }
      }
      out.add(
        RealmsFolderChild(
          segment: name,
          fullPathId: fullId,
          hasAlexandriaDb: hasDb,
          hasSubdirectories: hasSub,
        ),
      );
    }
    out.sort(
      (a, b) => a.segment.toLowerCase().compareTo(b.segment.toLowerCase()),
    );
    return out;
  }

  /// Abre un directorio existente en el gestor de archivos del SO (Windows / macOS / Linux).
  /// Devuelve `false` si la ruta no existe.
  static Future<bool> openDirectoryInFileManager(String absolutePath) async {
    final d = Directory(absolutePath);
    if (!d.existsSync()) return false;
    final path = d.absolute.path;
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
    return true;
  }

  /// Crea una carpeta vacía bajo `data/realms/<prefijo>/<segmento>/` sin `alexandria.db` (solo organización).
  /// Devuelve `false` si el destino ya es un realm (existe DB) o el nombre es inválido.
  static bool createRealmsSubfolderOnly({
    required String parentPrefix,
    required String segment,
  }) {
    final seg = sanitizeRealmId(segment);
    if (seg.isEmpty) return false;
    final parent = parentPrefix.trim().isEmpty ? '' : sanitizeRealmPath(parentPrefix);
    final fullId = parent.isEmpty ? seg : '$parent/$seg';
    final dir = Directory(realmDataRoot(fullId));
    if (dir.existsSync()) {
      final db = File('${dir.path}${Platform.pathSeparator}alexandria.db');
      if (db.existsSync()) return false;
      return true;
    }
    try {
      dir.createSync(recursive: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Si `data/alexandria.db` existe y `data/realms/default/alexandria.db` no, copia DB y subcarpetas conocidas al realm `default`. Crea `active_realm.txt`.
  static void ensureMigratedToRealmLayout() {
    final defaultRealm = Directory(realmDataRoot('default'));
    defaultRealm.createSync(recursive: true);

    final active = File(_activeRealmFile);
    if (!active.existsSync()) {
      writeActiveRealmId('default');
    }

    final legacyDb = File('${repoRoot}/data/alexandria.db');
    final targetDb = File('${defaultRealm.path}/alexandria.db');
    if (targetDb.existsSync()) return;
    if (!legacyDb.existsSync()) return;

    try {
      legacyDb.copySync(targetDb.path);
      _copyDirIfExists(
        Directory('${repoRoot}/data/bridge'),
        Directory('${defaultRealm.path}/bridge'),
      );
      _copyDirIfExists(
        Directory('${repoRoot}/data/snapshot'),
        Directory('${defaultRealm.path}/snapshot'),
      );
      _copyDirIfExists(
        Directory('${repoRoot}/data/viewer'),
        Directory('${defaultRealm.path}/viewer'),
      );
      _copyDirIfExists(
        Directory('${repoRoot}/data/assets'),
        Directory('${defaultRealm.path}/assets'),
      );
      _copyDirIfExists(
        Directory('${repoRoot}/data/navigation'),
        Directory('${defaultRealm.path}/navigation'),
      );
      _copyDirIfExists(
        Directory('${repoRoot}/data/manifests'),
        Directory('${defaultRealm.path}/manifests'),
      );
      final legacySnapCurrent = File('${repoRoot}/snapshot/current.json');
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

  /// Nuevo realm: copia plantilla a [newId] (ruta relativa, p.ej. `Copia/foo`).
  static bool duplicateRealm({required String newId, String templateRealmId = 'default'}) {
    final id = sanitizeRealmPath(newId);
    final templ = sanitizeRealmPath(templateRealmId);
    if (id == templ) return false;
    final srcRoot = Directory(realmDataRoot(templ));
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
