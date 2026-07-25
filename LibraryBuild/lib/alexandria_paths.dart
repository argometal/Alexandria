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

bool _looksLikeAlexandriaRepoRoot(String root) {
  final n = _normalizeRepoRoot(root);
  final gk = Directory(_pathJoin(n, 'GateKeeper'));
  final lb = Directory(_pathJoin(n, 'LibraryBuild'));
  return gk.existsSync() && lb.existsSync();
}

String? _findRepoRootBySiblingFolders(Directory start) {
  var d = start;
  for (var i = 0; i < 36; i++) {
    if (_looksLikeAlexandriaRepoRoot(d.path)) {
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

  /// Log a `library_build.log` sin depender de [AlexandriaAppLog] (evita import circular con resolución de rutas).
  static void _pathResolutionTrace(String tag, String message) {
    try {
      final f = File(appDiagnosticsFilePath('library_build.log'));
      f.parent.createSync(recursive: true);
      final ts = DateTime.now().toUtc().toIso8601String();
      final one = message.replaceAll('\r', ' ').replaceAll('\n', ' | ');
      f.writeAsStringSync('$ts\tINFO\t$tag\t$one\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  /// Raíz del repo (`data/realms/` **o** carpeta con `GateKeeper/` + `LibraryBuild/`).
  ///
  /// Orden: `ALEXANDRIA_ROOT` si tiene `data/realms/` → subir desde cwd → por ejecutable →
  /// mismo criterio por carpetas hermanas (sin necesitar `data/realms` aún) →
  /// `C:\Alexandria` solo si tiene `data/realms/` → último recurso `C:\Alexandria` (warning si vacío).
  static String get repoRoot {
    return _repoRootCache ??= _resolveRepoRoot();
  }

  static String _resolveRepoRoot() {
    _pathResolutionTrace(
      'PATH._resolveRepoRoot',
      'BEGIN cwd=${Directory.current.path} exe=${Platform.resolvedExecutable}',
    );
    final env = Platform.environment['ALEXANDRIA_ROOT']?.trim();
    if (env != null && env.isNotEmpty) {
      final envHasRealms = _hasDataRealms(env);
      final envLooks = _looksLikeAlexandriaRepoRoot(env);
      _pathResolutionTrace(
        'PATH._resolveRepoRoot',
        'ALEXANDRIA_ROOT="$env" _hasDataRealms=$envHasRealms _looksLikeAlexandriaRepoRoot=$envLooks',
      );
      if (envHasRealms) {
        final r = _normalizeRepoRoot(env);
        _pathResolutionTrace('PATH._resolveRepoRoot', 'CHOSEN=ALEXANDRIA_ROOT(hasRealms) -> $r');
        return r;
      }
      if (envLooks) {
        final r = _normalizeRepoRoot(env);
        _pathResolutionTrace('PATH._resolveRepoRoot', 'CHOSEN=ALEXANDRIA_ROOT(looksLikeRepo) -> $r');
        return r;
      }
      _pathResolutionTrace(
        'PATH._resolveRepoRoot',
        'ALEXANDRIA_ROOT set but rejected (no data/realms and not GateKeeper+LibraryBuild siblings)',
      );
    } else {
      _pathResolutionTrace('PATH._resolveRepoRoot', 'ALEXANDRIA_ROOT unset or empty');
    }
    // Antes que walkUp(cwd): si el .exe está en un bundle (LB+GK+…), la raíz es el extracto, no
    // `.../LibraryBuild` cuando ahí hay un `data/realms` embebido (desincroniza LB vs GK; ver gatekeeper.log PATH vs LB).
    final bundleFromExe =
        findBundleTripletInstallRoot() ?? findBundleRootByLibraryBuildOnly();
    if (bundleFromExe != null) {
      final br = _normalizeRepoRoot(bundleFromExe);
      if (_hasDataRealms(br)) {
        _pathResolutionTrace(
          'PATH._resolveRepoRoot',
          'CHOSEN=bundleFromExe(has data/realms) -> $br',
        );
        return br;
      }
      if (_looksLikeAlexandriaRepoRoot(br)) {
        _pathResolutionTrace(
          'PATH._resolveRepoRoot',
          'CHOSEN=bundleFromExe(GateKeeper+LibraryBuild) -> $br',
        );
        return br;
      }
      _pathResolutionTrace(
        'PATH._resolveRepoRoot',
        'bundleFromExe=$br skipped (no data/realms at bundle root and not full repo layout)',
      );
    }
    final fromCwd = _findRepoRootWalkingUp(Directory.current);
    if (fromCwd != null) {
      _pathResolutionTrace('PATH._resolveRepoRoot', 'CHOSEN=walkUp(cwd has data/realms) -> $fromCwd');
      return fromCwd;
    }
    final fromCwdSib = _findRepoRootBySiblingFolders(Directory.current);
    if (fromCwdSib != null) {
      _pathResolutionTrace(
        'PATH._resolveRepoRoot',
        'CHOSEN=siblingsFrom(cwd GateKeeper+LibraryBuild) -> $fromCwdSib',
      );
      return fromCwdSib;
    }
    _pathResolutionTrace(
      'PATH._resolveRepoRoot',
      'cwd walk: no data/realms upward; no sibling repo from cwd',
    );
    try {
      var d = File(Platform.resolvedExecutable).parent;
      for (var i = 0; i < 28; i++) {
        final w = _findRepoRootWalkingUp(d);
        if (w != null) {
          _pathResolutionTrace(
            'PATH._resolveRepoRoot',
            'CHOSEN=walkUp(exeDir i=$i has data/realms) -> $w',
          );
          return w;
        }
        final ws = _findRepoRootBySiblingFolders(d);
        if (ws != null) {
          _pathResolutionTrace(
            'PATH._resolveRepoRoot',
            'CHOSEN=siblingsFrom(exeDir i=$i) -> $ws',
          );
          return ws;
        }
        final p = d.parent;
        if (p.path == d.path) break;
        d = p;
      }
      _pathResolutionTrace('PATH._resolveRepoRoot', 'exe walk: exhausted parents without match');
    } catch (e, st) {
      _pathResolutionTrace('PATH._resolveRepoRoot', 'exe walk exception: $e | $st');
    }
    if (_hasDataRealms(kDefaultAlexandriaRepoRoot)) {
      final r = _normalizeRepoRoot(kDefaultAlexandriaRepoRoot);
      _pathResolutionTrace(
        'PATH._resolveRepoRoot',
        'CHOSEN=fallbackDefault(has data/realms at default) -> $r',
      );
      return r;
    }
    if (!_hasDataRealms(kDefaultAlexandriaRepoRoot)) {
      // ignore: avoid_print
      print(
        '[AlexandriaPaths] Sin data/realms ni repo GateKeeper+LibraryBuild; fallback '
        '${kDefaultAlexandriaRepoRoot}. Define ALEXANDRIA_ROOT para alinear con GateKeeper.',
      );
    }
    final last = _normalizeRepoRoot(kDefaultAlexandriaRepoRoot);
    _pathResolutionTrace(
      'PATH._resolveRepoRoot',
      'CHOSEN=fallbackDefault(last resort, may be empty on this machine) -> $last',
    );
    return last;
  }

  /// Compatibilidad: misma raíz resuelta que [repoRoot].
  static String get kAlexandriaRepoRoot => repoRoot;

  /// Archivo en la raíz del repo (al lado de `GateKeeper/`). GateKeeper lo lee para anclar la misma [repoRoot].
  static const String runtimeRootMarkerFileName = 'alexandria_runtime_root.txt';

  /// Escribe la raíz resuelta para que GateKeeper no use otra carpeta que Flutter (p. ej. `C:\\Alexandria` vacío).
  static void writeRuntimeRootMarkerForGateKeeper() {
    try {
      final root = repoRoot;
      final marker = File(_pathJoin(root, runtimeRootMarkerFileName));
      marker.writeAsStringSync('$root\n');
      _pathResolutionTrace(
        'PATH.writeRuntimeRootMarkerForGateKeeper',
        'wrote ${marker.path} firstLine=$root',
      );
    } catch (e, st) {
      _pathResolutionTrace('PATH.writeRuntimeRootMarkerForGateKeeper', 'FAIL $e | $st');
    }
  }

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

  /// Ruta relativa bajo `data/realms/`, p.ej. `default` o `Lab/mi_realm`.
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

  /// Clon repetible del ORM (sin datos de usuario) para plantillas / nuevos realms.
  /// Directorio: `data/realm_seed/`; archivo: [realmSeedDbPath].
  static String get realmSeedDir =>
      _pathJoin(repoRoot, 'data', 'realm_seed');

  static String get realmSeedDbPath =>
      '${realmSeedDir}${Platform.pathSeparator}alexandria.db';

  /// Raíz del instalador embebido (tres .exe hermanos + carpeta `data-transfer/`), si existe.
  static String? findBundleTripletInstallRoot() {
    try {
      var dir = File(Platform.resolvedExecutable).parent;
      for (var i = 0; i < 22; i++) {
        final root = dir.absolute.path;
        final lb = File(_pathJoin(root, 'LibraryBuild', 'library_build.exe'));
        final gk = File(_pathJoin(root, 'GateKeeper', 'Gatekeeper.exe'));
        final lab = File(_pathJoin(root, 'TrainingLab', 'training_app.exe'));
        if (lb.existsSync() && gk.existsSync() && lab.existsSync()) {
          return root;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}
    return null;
  }

  /// Carpeta padre del layout embebido cuando al menos existe `LibraryBuild/library_build.exe`
  /// (no exige GK/Lab: evita caer en `LibraryBuild/data-transfer` si el triplete falla).
  static String? findBundleRootByLibraryBuildOnly() {
    try {
      var dir = File(Platform.resolvedExecutable).parent;
      for (var i = 0; i < 22; i++) {
        final root = dir.absolute.path;
        final lb = File(_pathJoin(root, 'LibraryBuild', 'library_build.exe'));
        if (lb.existsSync()) {
          return root;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}
    return null;
  }

  static String _dataTransferDirForBundleRoot(String bundleRoot) {
    final nested = _pathJoin(bundleRoot, 'data-transfer');
    final pkg = File(_pathJoin(nested, 'DataTransfer.exe'));
    if (pkg.existsSync()) {
      return nested;
    }
    final legacy = File(_pathJoin(bundleRoot, 'DataTransfer.exe'));
    if (legacy.existsSync()) {
      return bundleRoot;
    }
    return nested;
  }

  /// Carpeta donde el launcher de Windows escribe **`launcher.log`** (errores / arranques).
  /// No depende del realm; sirve para soporte entre versiones.
  static String get launcherDiagnosticsFolder {
    if (!Platform.isWindows) return '';
    return sharedDiagnosticsDirectory;
  }

  static String get launcherDiagnosticsLogPath =>
      _pathJoin(launcherDiagnosticsFolder, 'launcher.log');

  /// Carpeta compartida: `…/Alexandria/diagnostics` (Windows) o `~/.alexandria/diagnostics` (otros).
  static String get sharedDiagnosticsDirectory {
    if (Platform.isWindows) {
      final la = Platform.environment['LOCALAPPDATA'];
      if (la != null && la.isNotEmpty) {
        return _pathJoin(la, 'Alexandria', 'diagnostics');
      }
    }
    final h = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (h != null && h.isNotEmpty) {
      return _pathJoin(h, '.alexandria', 'diagnostics');
    }
    return _pathJoin(Directory.systemTemp.path, 'Alexandria_diagnostics');
  }

  /// Ruta de un `.log` bajo [sharedDiagnosticsDirectory].
  static String appDiagnosticsFilePath(String fileName) =>
      _pathJoin(sharedDiagnosticsDirectory, fileName);

  /// `data-transfer/` del repo en desarrollo, o junto al bundle del .exe publicado.
  ///
  /// Prioridad: triplete completo → mismo [bundleRoot] solo con LB → repo `data-transfer`.
  /// Con pkg en `data-transfer/DataTransfer.exe` el directorio es `<bundle>/data-transfer`;
  /// con exe legado en la raíz del extract, el servidor escribe `out/` en `<bundle>/`.
  static String get dataTransferRoot {
    final bundle = findBundleTripletInstallRoot() ?? findBundleRootByLibraryBuildOnly();
    if (bundle != null) {
      return _dataTransferDirForBundleRoot(bundle);
    }
    return '${repoRoot}/data-transfer';
  }

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

  /// GateKeeper: `1` / `0` — single app-wide toggle for place recall drill (written by Library Build drawer).
  static String get placeRecallEnabledPath => '$bridgeDir/place_recall_enabled.txt';

  /// `1` / `true` = umbral atleta (100% en métricas); `0` / `false` = estándar (80%).
  static String get memoryAthleteModePath => '$bridgeDir/memory_athlete_mode.txt';

  /// GateKeeper HUD / F1 help: `en` | `es` | `pt` — written by Library Build from app language; default `en`.
  static String get gkUiLangPath => '$bridgeDir/gk_ui_lang.txt';

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

  /// Plantilla de realm **completa** en disco (DB + `assets/` + snapshot + viewer + …), p. ej. curada en `data/bundled_default_realm/`.
  /// Si existe `alexandria.db` ahí, [ensureDefaultRealmOnDiskFromBundledTemplateSync] y el reset nuclear pueden poblar `data/realms/default/` sin esqueleto vacío.
  static String get bundledDefaultRealmRoot =>
      _pathJoin(repoRoot, 'data', 'bundled_default_realm');

  /// Copia recursiva del contenido de [src] bajo [dst] (equivalente a duplicar un realm en disco).
  static void copyDirectoryTreeContents(Directory src, Directory dst) {
    _copyDirIfExists(src, dst);
  }

  /// Mueve `data/realms/<from>/` → `data/realms/<to>/` (sin sobrescribir destino).
  /// El llamador debe cerrar SQLite del realm afectado antes de invocar esto.
  static bool moveRealmDataDirectory(String fromRealmId, String toRealmId) {
    final from = sanitizeRealmPath(fromRealmId);
    final to = sanitizeRealmPath(toRealmId);
    if (from.isEmpty || to.isEmpty || from == to) return false;
    final src = Directory(realmDataRoot(from));
    final dst = Directory(realmDataRoot(to));
    if (!src.existsSync()) return false;
    if (dst.existsSync()) return false;
    dst.parent.createSync(recursive: true);
    try {
      src.renameSync(dst.path);
      return true;
    } catch (e, st) {
      try {
        copyDirectoryTreeContents(src, dst);
        src.deleteSync(recursive: true);
        return true;
      } catch (e2, st2) {
        try {
          if (dst.existsSync()) dst.deleteSync(recursive: true);
        } catch (_) {}
        // ignore: avoid_print
        print('[LB][REALM_MOVE_ERR] $e2\n$st2 (rename failed: $e)\n$st');
        return false;
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
