import 'package:flutter/material.dart';

import '../app_state/training_orchestrator.dart';
import '../models/protocol_config.dart';
import '../services/score_calculator.dart';
import '../services/session_store.dart';
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.session,
    required this.store,
    required this.metrics,
  });

  final ActiveTrainingSession session;
  final SessionStore store;
  final ScoreMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = session.config?.modality ?? '-';
    final d = DateTime.now().toUtc();
    final dateStr = d.toIso8601String().substring(0, 10);
    void saveCsv() {
      store.appendDailyCsvLine([
        dateStr,
        session.sessionId,
        m,
        metrics.scoreNorm.toStringAsFixed(4),
        metrics.accuracyImmediate.toStringAsFixed(4),
        metrics.accuracyDelayed.toStringAsFixed(4),
        metrics.retention.toStringAsFixed(4),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('session: ${session.sessionId}', style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 12),
          _row('Acc. inmediata', metrics.accuracyImmediate),
          _row('Latencia media (ms)', metrics.avgLatencyMs),
          _row('score_norm (cap 1)', metrics.scoreNorm),
          _row('Acc. diferida', metrics.accuracyDelayed),
          _row('retention (d/i)', metrics.retention),
          const SizedBox(height: 16),
          Text(_hints(metrics, session.config!)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              saveCsv();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Guardar CSV y volver al inicio'),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, num v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l),
          Text(
            v is double
                ? (l.contains('ms')
                    ? v.round().toString()
                    : v.toStringAsFixed(4))
                : v.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _hints(ScoreMetrics met, ProtocolConfig c) {
    final b = StringBuffer('Sugerencias (tú ajustas parámetros):\n');
    if (met.accuracyImmediate >= 0.85) {
      b.writeln('• Muy buena acc. inmediata — puedes bajar a ~1,5 s en encode (próxima build).');
    }
    if (met.scoreNorm >= 0.7) {
      b.writeln('• score_norm sólido — al estabilizar, probar secuencia más larga o chunk 3 en cartas (no implementado).');
    }
    if (met.retention >= 0.9) {
      b.writeln('• retención alta — candidato a modo inverso o pausa distinta (producto).');
    }
    if (b.length < 50) {
      b.writeln('Más sesiones = métrica más fiable. JSONL: carpeta de soporte de la app (training_app/sessions).');
    }
    return b.toString();
  }
}
