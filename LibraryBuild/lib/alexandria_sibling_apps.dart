import 'dart:io';

import 'alexandria_paths.dart';

/// Localiza y lanza GateKeeper, LibraryBuild y Training Lab en el mismo “bundle” o repo de desarrollo.
enum AlexandriaSiblingAppKind {
  gateKeeper,
  libraryBuild,
  trainingLab,
}

/// Resolución de rutas a los tres ejecutables (layout [CREAR-APP] o `flutter`/`godot` build en repo).
class AlexandriaSiblingApps {
  AlexandriaSiblingApps._();

  static String _j(String a, String b, [String? c, String? d]) {
    final s = Platform.pathSeparator;
    if (d != null) return '$a$s$b$s$c$s$d';
    if (c != null) return '$a$s$b$s$c';
    return '$a$s$b';
  }

  static String _jp(List<String> parts) => parts.join(Platform.pathSeparator);

  static Map<AlexandriaSiblingAppKind, String?> resolveAll() {
    // Misma raíz que PAO / Match / realms ([AlexandriaPaths.repoRoot]), no solo subir desde el .exe.
    try {
      final r = AlexandriaPaths.repoRoot;
      if (Directory(_j(r, 'data', 'realms')).existsSync()) {
        final map = _devPathsFromRepoRoot(r);
        if (map.values.any((p) => p != null)) {
          return map;
        }
      }
    } catch (_) {}

    var dir = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 22; i++) {
      final root = dir.absolute.path;

      final bundleLb = File(_j(root, 'LibraryBuild', 'library_build.exe'));
      final bundleGk = File(_j(root, 'GateKeeper', 'Gatekeeper.exe'));
      final bundleLab = File(_j(root, 'TrainingLab', 'training_app.exe'));
      if (bundleLb.existsSync() &&
          bundleGk.existsSync() &&
          bundleLab.existsSync()) {
        return {
          AlexandriaSiblingAppKind.libraryBuild: bundleLb.path,
          AlexandriaSiblingAppKind.gateKeeper: bundleGk.path,
          AlexandriaSiblingAppKind.trainingLab: bundleLab.path,
        };
      }

      if (Directory(_j(root, 'data', 'realms')).existsSync()) {
        final map = _devPathsFromRepoRoot(root);
        if (map.values.any((p) => p != null)) {
          return map;
        }
      }

      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return {
      AlexandriaSiblingAppKind.gateKeeper: null,
      AlexandriaSiblingAppKind.libraryBuild: null,
      AlexandriaSiblingAppKind.trainingLab: null,
    };
  }

  static Map<AlexandriaSiblingAppKind, String?> _devPathsFromRepoRoot(
    String root,
  ) {
    String? gk;
    final gkExport = _j(root, 'GateKeeper', 'export', 'Gatekeeper.exe');
    final gkPlain = _j(root, 'GateKeeper', 'Gatekeeper.exe');
    if (File(gkExport).existsSync()) {
      gk = gkExport;
    } else if (File(gkPlain).existsSync()) {
      gk = gkPlain;
    }
    final lb = _jp([
      root,
      'LibraryBuild',
      'build',
      'windows',
      'x64',
      'runner',
      'Release',
      'library_build.exe',
    ]);
    final lab = _jp([
      root,
      'training_app',
      'build',
      'windows',
      'x64',
      'runner',
      'Release',
      'training_app.exe',
    ]);
    return {
      AlexandriaSiblingAppKind.gateKeeper: gk,
      AlexandriaSiblingAppKind.libraryBuild:
          File(lb).existsSync() ? lb : null,
      AlexandriaSiblingAppKind.trainingLab:
          File(lab).existsSync() ? lab : null,
    };
  }

  /// Lanza el hermano indicado (solo Windows en esta suite).
  static Future<void> launch(AlexandriaSiblingAppKind kind) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('AlexandriaSiblingApps: solo Windows');
    }
    final p = resolveAll()[kind];
    if (p == null || !File(p).existsSync()) {
      throw StateError('missing $kind');
    }
    final wd = File(p).parent.path;
    await Process.start(
      p,
      const <String>[],
      workingDirectory: wd,
      mode: ProcessStartMode.detached,
    );
  }
}
