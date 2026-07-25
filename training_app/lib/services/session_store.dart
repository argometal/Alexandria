import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/daily_metric.dart';
import '../models/event.dart';

/// Escribe JSONL bajo [applicationSupportDirectory]/training_app/sessions
/// y metrics/daily.csv (append).
class SessionStore {
  SessionStore._(this.sessionsDir, this.metricsFile);

  final Directory sessionsDir;
  final File metricsFile;

  /// Carpeta `.../application_support/training_app` (JSONL en `sessions/`, CSV en `metrics/`).
  String get dataRootPath => sessionsDir.parent.path;

  static Future<SessionStore> create() async {
    final root = await getApplicationSupportDirectory();
    final base = Directory(p.join(root.path, 'training_app'));
    final sessionDir = Directory(p.join(base.path, 'sessions'));
    final metDir = Directory(p.join(base.path, 'metrics'));
    await sessionDir.create(recursive: true);
    await metDir.create(recursive: true);
    return SessionStore._(
      sessionDir,
      File(p.join(metDir.path, 'daily.csv')),
    );
  }

  void appendEvent(String sessionId, Map<String, dynamic> json) {
    final f = File(p.join(sessionsDir.path, 'session_$sessionId.jsonl'));
    f.writeAsStringSync('${jsonEncode(json)}\n', mode: FileMode.append, flush: true);
  }

  void appendEventFrom(TrainingEvent e) {
    appendEvent(e.sessionId, e.toJson());
  }

  void appendDailyCsvLine(List<String> row) {
    final line = row.map((c) {
      if (c.contains(',') || c.contains('"') || c.contains('\n')) {
        return '"${c.replaceAll('"', '""')}"';
      }
      return c;
    }).join(',');
    if (!metricsFile.existsSync() || metricsFile.lengthSync() == 0) {
      metricsFile.writeAsStringSync(
        'date_utc,session_id,modality,score_norm,acc_immediate,acc_delayed,retention\n',
      );
    }
    metricsFile.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }

  /// Filas de historial (orden cronológico del CSV). Sin archivo o solo cabecera: lista vacía.
  List<DailyMetricRow> readDailyMetrics() {
    if (!metricsFile.existsSync()) {
      return [];
    }
    final raw = metricsFile.readAsStringSync();
    final lines = const LineSplitter().convert(raw);
    if (lines.isEmpty) {
      return [];
    }
    final out = <DailyMetricRow>[];
    for (final line0 in lines) {
      final line = line0.trim();
      if (line.isEmpty) {
        continue;
      }
      if (line.startsWith('date_utc,')) {
        continue;
      }
      final p = _splitCsvLine(line);
      if (p.length < 7) {
        continue;
      }
      out.add(
        DailyMetricRow(
          dateUtc: p[0],
          sessionId: p[1],
          modality: p[2],
          scoreNorm: double.tryParse(p[3]) ?? 0,
          accImmediate: double.tryParse(p[4]) ?? 0,
          accDelayed: double.tryParse(p[5]) ?? 0,
          retention: double.tryParse(p[6]) ?? 0,
        ),
      );
    }
    return out;
  }
}

/// Campos con comas o comillas usan comillas; el resto se parten por `,`.
List<String> _splitCsvLine(String line) {
  if (!line.contains('"')) {
    return line.split(',');
  }
  final out = <String>[];
  var i = 0;
  while (i < line.length) {
    if (line[i] == '"') {
      i++;
      final buf = StringBuffer();
      while (i < line.length) {
        if (line[i] == r'"') {
          if (i + 1 < line.length && line[i + 1] == r'"') {
            buf.write(r'"');
            i += 2;
          } else {
            i++;
            break;
          }
        } else {
          buf.write(line[i]);
          i++;
        }
      }
      out.add(buf.toString());
      if (i < line.length && line[i] == ',') {
        i++;
      }
    } else {
      final j = line.indexOf(',', i);
      if (j < 0) {
        out.add(line.substring(i).trim());
        break;
      }
      out.add(line.substring(i, j).trim());
      i = j + 1;
    }
  }
  return out;
}
