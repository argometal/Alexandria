import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'alexandria_paths.dart';

/// Log de app en [AlexandriaPaths.appDiagnosticsFilePath] (mismo sitio que `launcher.log`).
class AlexandriaAppLog {
  AlexandriaAppLog._();

  static const int _maxBytes = 500000;
  static String _fileName = 'library_build.log';
  static bool _initialized = false;

  static void init({String fileName = 'library_build.log'}) {
    if (_initialized) return;
    _initialized = true;
    _fileName = fileName;

    FlutterError.onError = (details) {
      try {
        _write('ERROR', 'flutter', details.exceptionAsString(), details.stack);
      } catch (_) {}
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      try {
        _write('ERROR', 'async', error.toString(), stack);
      } catch (_) {}
      return false;
    };

    try {
      _write(
        'INFO',
        'session',
        'start ${DateTime.now().toUtc().toIso8601String()}',
        null,
      );
    } catch (_) {}
  }

  static String get logFilePath =>
      AlexandriaPaths.appDiagnosticsFilePath(_fileName);

  static void error(String tag, Object message, [StackTrace? stack]) {
    try {
      _write('ERROR', tag, message.toString(), stack);
    } catch (_) {}
  }

  static void info(String tag, String message) {
    if (!kDebugMode) return;
    try {
      _write('INFO', tag, message, null);
    } catch (_) {}
  }

  /// Siempre escribe en `library_build.log` (release), p. ej. resolución de [AlexandriaPaths.repoRoot].
  static void traceAlways(String tag, String message) {
    try {
      _write('INFO', tag, message, null);
    } catch (_) {}
  }

  static void _write(
    String level,
    String tag,
    String message,
    StackTrace? stack,
  ) {
    final path = AlexandriaPaths.appDiagnosticsFilePath(_fileName);
    File(path).parent.createSync(recursive: true);
    final ts = DateTime.now().toUtc().toIso8601String();
    final oneLine = StringBuffer()
      ..write(ts)
      ..write('\t')
      ..write(level)
      ..write('\t')
      ..write(tag)
      ..write('\t')
      ..write(message.replaceAll('\r', ' ').replaceAll('\n', ' | '));
    if (stack != null) {
      oneLine
        ..write(' | ')
        ..write(stack.toString().replaceAll('\r', ' ').replaceAll('\n', ' | '));
    }
    oneLine.writeln();
    _appendWithTrim(File(path), oneLine.toString());
  }

  static void _appendWithTrim(File f, String line) {
    f.writeAsStringSync(line, mode: FileMode.append, flush: true);
    final len = f.lengthSync();
    if (len <= _maxBytes) return;
    const keep = 240000;
    final start = len > keep ? len - keep : 0;
    final toRead = len - start;
    final raf = f.openSync(mode: FileMode.read);
    try {
      raf.setPositionSync(start);
      final bytes = raf.readSync(toRead);
      f.writeAsBytesSync(utf8.encode('[... log truncado ...]\n') + bytes, flush: true);
    } catch (_) {
      // ignorar
    } finally {
      try {
        raf.closeSync();
      } catch (_) {}
    }
  }
}
