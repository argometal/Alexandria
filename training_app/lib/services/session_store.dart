import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/event.dart';

/// Escribe JSONL bajo [applicationSupportDirectory]/training_app/sessions
/// y metrics/daily.csv (append).
class SessionStore {
  SessionStore._(this.sessionsDir, this.metricsFile);

  final Directory sessionsDir;
  final File metricsFile;

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
}
