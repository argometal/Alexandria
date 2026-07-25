import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Misma semántica que Library Build: log en `Alexandria/diagnostics/training_lab.log`.
class AlexandriaAppLog {
  AlexandriaAppLog._();

  static const int _maxBytes = 500000;
  static const String _fileName = 'training_lab.log';
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;

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

  static String get logFilePath => _filePath;

  static String get _filePath {
    if (Platform.isWindows) {
      final la = Platform.environment['LOCALAPPDATA'];
      if (la != null && la.isNotEmpty) {
        return '$la\\Alexandria\\diagnostics\\$_fileName';
      }
    }
    final h = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (h != null && h.isNotEmpty) {
      return '$h${Platform.pathSeparator}.alexandria${Platform.pathSeparator}diagnostics${Platform.pathSeparator}$_fileName';
    }
    return '${Directory.systemTemp.path}${Platform.pathSeparator}Alexandria_diagnostics${Platform.pathSeparator}$_fileName';
  }

  static void _write(
    String level,
    String tag,
    String message,
    StackTrace? stack,
  ) {
    final path = _filePath;
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
    } finally {
      try {
        raf.closeSync();
      } catch (_) {}
    }
  }
}
