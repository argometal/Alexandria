import 'package:flutter/material.dart';

import '../app_state/training_orchestrator.dart';
import '../models/protocol_config.dart';
import '../services/score_calculator.dart';
import '../services/session_store.dart';
import '../widgets/metric_gauge_block.dart';
import '../widgets/session_results_review.dart';

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

    final seq = session.sequence;
    final imm = session.lastImmediate;
    final del = session.lastDelayed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Sesión: ${session.sessionId}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 8),
          EncodeOrderReferenceCard(sequence: seq),
          const SizedBox(height: 12),
          RecallCompareCard(
            title: 'Recall inmediato — comparación',
            events: imm,
          ),
          const SizedBox(height: 12),
          RecallCompareCard(
            title: 'Recall diferido — comparación',
            events: del,
          ),
          const SizedBox(height: 16),
          Text(
            'Métricas (esta sesión)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _NumericSummaryCard(
            m: m,
            metrics: metrics,
          ),
          const SizedBox(height: 8),
          Text(
            'Latencia: tiempo entre abrir el recall y enviar; más baja suele ir con tareas más fáciles o decisión más rápida, no con calidad de memoria sola.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _hints(metrics, session.config!),
            style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              saveCsv();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Guardar en historial (CSV) y volver al inicio'),
          ),
        ],
      ),
    );
  }

  String _hints(ScoreMetrics met, ProtocolConfig c) {
    final b = StringBuffer('Sugerencias (ajustar parámetros tú):\n');
    if (met.accuracyImmediate >= 0.85) {
      b.writeln('• Buena acc. inmediata — probar encode más corto o secuencia más larga (producto).');
    }
    if (met.scoreNorm >= 0.7) {
      b.writeln('• score_norm alto — al estabilizar, subir longitud o cambiar modalidad para seguir creciendo.');
    }
    if (met.retention >= 0.9) {
      b.writeln('• retención fuerte (d vs i) — el diferido acompaña al inmediato.');
    }
    if (b.length < 55) {
      b.writeln('• Sigue acumulando filas en Avance: tendrás tendencia, no un solo dato aislado.');
    }
    return b.toString();
  }
}

class _NumericSummaryCard extends StatelessWidget {
  const _NumericSummaryCard({
    required this.m,
    required this.metrics,
  });

  final String m;
  final ScoreMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final ret = metrics.retention;
    final over = ret > 1.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _chipRow('Modalidad', m),
            const SizedBox(height: 4),
            MetricBar(
              label: 'Acierto inmediato (pos. correcta)',
              valueText: _pct(metrics.accuracyImmediate),
              bar: metrics.accuracyImmediate,
            ),
            MetricBar(
              label: 'Acierto diferido (pos. correcta)',
              valueText: _pct(metrics.accuracyDelayed),
              bar: metrics.accuracyDelayed,
            ),
            MetricBar(
              label: 'Retención d/i (1 = equilibrio, >1 = más aciertos en diferido)',
              valueText: ret.isNaN ? '—' : ret.toStringAsFixed(2),
              bar: over ? 1.0 : (ret > 1 ? 1.0 : ret).clamp(0, 1),
              useBlueFullBar: over,
            ),
            MetricBar(
              label: 'Score normalizado (0–1, combina acc. y rapidez)',
              valueText: _pct(metrics.scoreNorm),
              bar: metrics.scoreNorm,
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Latencia media (toda la respuesta)'),
                Text(
                  '${metrics.avgLatencyMs.round()} ms',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _pct(double v) {
    if (v.isNaN) {
      return '—';
    }
    return '${(v * 100).round()}%';
  }

  Widget _chipRow(String k, String v) {
    return Row(
      children: [
        Text(
          k,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
