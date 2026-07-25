import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../widgets/metric_gauge_block.dart';

import '../models/daily_metric.dart';
import '../services/session_store.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.store});

  final SessionStore store;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<DailyMetricRow>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _error = null;
    });
    try {
      final list = widget.store.readDailyMetrics();
      setState(() {
        _rows = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _rows = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avance (historial)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error al leer el CSV: $_error', textAlign: TextAlign.center),
        ),
      );
    }
    final rows = _rows;
    if (rows == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final dataRoot = widget.store.dataRootPath;
    if (rows.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Aún no hay filas en el historial.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Completa una sesión y, en resultados, pulsa “Guardar CSV y volver al inicio”. Cada guardado añade una fila a metrics/daily.csv.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text('Ruta: $dataRoot', style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      );
    }

    final byDate = List<DailyMetricRow>.of(rows)..sort((a, b) => a.dateUtc.compareTo(b.dateUtc));
    final n = byDate.length;
    double best = byDate.first.scoreNorm;
    for (final r in byDate) {
      if (r.scoreNorm > best) {
        best = r.scoreNorm;
      }
    }
    final last5 = byDate.reversed.take(5).toList();
    final recent = byDate.length <= 20 ? byDate : byDate.sublist(math.max(0, byDate.length - 20));
    final series = recent.map((e) => e.scoreNorm).toList();
    final take = n >= 3 ? 3 : n;
    final avg3 = take == 0
        ? 0.0
        : byDate.sublist(n - take).map((e) => e.scoreNorm).reduce((a, b) => a + b) / take;
    final avgAll = byDate.isEmpty
        ? 0.0
        : byDate.map((e) => e.scoreNorm).reduce((a, b) => a + b) / byDate.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard(
          n: n,
          best: best,
          last: byDate.last,
          avg3: avg3,
          avgAll: avgAll,
        ),
        const SizedBox(height: 16),
        if (series.length >= 2) ...[
          Text(
            'Tendencia: score (últimas ${series.length} en CSV, orden de tiempo →)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '0 = bajo, 1 = tope. Subir o mantener = buena señal a largo plazo (misma modalidad/longitud).',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          _SparklineCard(
            values: series,
            lastLabel: 'Último: ${byDate.last.scoreNorm.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 16),
        ] else
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Guarda al menos 2 sesiones con CSV para ver la línea de tendencia de score.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        MetricBar(
          label: 'Media últimas 3 sesiones (score vs tope 1)',
          valueText: '${(avg3 * 100).round()}%',
          bar: avg3.clamp(0, 1),
        ),
        const SizedBox(height: 4),
        MetricBar(
          label: 'Media global (todas las filas) — score',
          valueText: '${(avgAll * 100).round()}%',
          bar: avgAll.clamp(0, 1),
        ),
        const SizedBox(height: 16),
        Text(
          'Origen: ${p.join(dataRoot, 'metrics', 'daily.csv')}',
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        const SizedBox(height: 16),
        const Text('Detalle: últimas 5 filas (más reciente arriba)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final r in last5) _rowTile(r),
        if (byDate.length > 5) ...[
          const SizedBox(height: 8),
          Text('…y ${byDate.length - 5} sesión(es) en el historial', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _summaryCard({
    required int n,
    required double best,
    required DailyMetricRow last,
    required double avg3,
    required double avgAll,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Resumen visible', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            _kv('Sesiones guardadas', '$n', highlight: n > 0),
            _kv('Mejor score (histórico)', '${(best * 100).round()} % / 1', highlight: true),
            _kv('Última: fecha', last.dateUtc, highlight: false),
            _kv('Última: retención d/i', last.retention.toStringAsFixed(2), highlight: true),
            _kv('Media últ. 3: score', '${(avg3 * 100).round()} %', highlight: true),
            _kv('Media de todas: score', '${(avgAll * 100).round()} %', highlight: false),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {required bool highlight}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(k, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          Text(
            v,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: highlight ? const Color(0xFFE8D4A8) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowTile(DailyMetricRow r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${r.dateUtc} · ${r.modality}'),
        subtitle: Text('score ${r.scoreNorm.toStringAsFixed(2)}  ·  acc. i/d ${(r.accImmediate * 100).round()}% / ${(r.accDelayed * 100).round()}%  ·  ret ${r.retention.toStringAsFixed(2)}'),
        isThreeLine: true,
      ),
    );
  }
}

class _SparklineCard extends StatelessWidget {
  const _SparklineCard({
    required this.values,
    required this.lastLabel,
  });

  final List<double> values;
  final String lastLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter: _ScoreSparklinePainter(
                  values: values,
                  lineColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lastLabel,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSparklinePainter extends CustomPainter {
  _ScoreSparklinePainter({required this.values, required this.lineColor});

  final List<double> values;
  final Color lineColor;

  @override
  void paint(Canvas c, Size s) {
    if (values.isEmpty) {
      return;
    }
    if (values.length == 1) {
      c.drawCircle(Offset(s.width * 0.5, s.height * 0.3), 4, Paint()..color = lineColor);
      return;
    }
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if ((maxV - minV) < 1e-6) {
      minV = 0.0;
      maxV = 1.0;
    }
    final p = 8.0;
    final w = s.width - 2 * p;
    final h = s.height - 2 * p;
    // grid: 0 and 1
    final p0 = Paint()..color = const Color(0x22FFFFFF);
    c.drawLine(Offset(0, p + h), Offset(s.width, p + h), p0);
    c.drawLine(Offset(0, p), Offset(s.width, p), p0);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final t = i / (values.length - 1);
      final x = p + w * t;
      final yNorm = (values[i] - minV) / (maxV - minV);
      final y = p + h * (1.0 - yNorm);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    c.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < values.length; i++) {
      final t = i / (values.length - 1);
      final x = p + w * t;
      final yNorm = (values[i] - minV) / (maxV - minV);
      final y = p + h * (1.0 - yNorm);
      c.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreSparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
