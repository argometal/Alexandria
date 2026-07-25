import 'package:flutter/material.dart';

import '../alexandria_sibling_apps.dart';
import '../app_state/training_orchestrator.dart';
import '../models/daily_metric.dart';
import '../models/protocol_config.dart';
import '../services/session_store.dart';
import '../widgets/metric_gauge_block.dart';
import 'encode_screen.dart';
import 'methodology_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _modality = ProtocolConfig.modalityCards;
  int _length = 4; // 4 pares = prueba rápida; subir a 10 en producción
  /// Segundos por estímulo en encode (ajustable; por defecto más lento que 2s para principiantes).
  double _encodeSecPerStimulus = 3.0;
  int _interRecallSec = 60; // pausa inmediato → diferido
  int _sessionN = 1;
  List<DailyMetricRow> _csv = const [];

  @override
  void initState() {
    super.initState();
    _refreshCsv();
  }

  void _refreshCsv() {
    setState(() {
      _csv = widget.sessionStore.readDailyMetrics();
    });
  }

  Future<void> _launchSibling(AlexandriaSiblingAppKind kind) async {
    try {
      await AlexandriaSiblingApps.launch(kind);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró el ejecutable (compila GK/LB o usa el bundle).',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training lab'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.apps_outlined),
            tooltip: 'Alexandria',
            itemBuilder: (ctx) => [
              PopupMenuItem<void>(
                onTap: () {
                  Future.microtask(
                    () => _launchSibling(AlexandriaSiblingAppKind.gateKeeper),
                  );
                },
                child: const Text('Abrir GateKeeper'),
              ),
              PopupMenuItem<void>(
                onTap: () {
                  Future.microtask(
                    () => _launchSibling(AlexandriaSiblingAppKind.libraryBuild),
                  );
                },
                child: const Text('Abrir Library Build'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Metodología',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (ctx) => MethodologyScreen(store: widget.sessionStore),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            tooltip: 'Avance',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (ctx) => ProgressScreen(store: widget.sessionStore),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_csv.isNotEmpty) ...[
            _lastSessionCard(),
            const SizedBox(height: 20),
          ] else ...[
            const Card(
              child: ListTile(
                title: Text('Aún no hay avance en CSV', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Tras un ejercicio, en Resultados pulsa “Guardar en historial (CSV)” para acumular métricas y ver gráfica en Avance.',
                  style: TextStyle(height: 1.3),
                ),
                isThreeLine: true,
                leading: Icon(Icons.insights_outlined, size: 32, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            'Motor de entrenamiento (cartas y números, JSONL). Tercer motor — sin Alexandria/LB.\n[ACUERDO_CHAT_DEEP]',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text('Modalidad', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: ProtocolConfig.modalityCards,
                label: Text('Cartas'),
                icon: Icon(Icons.style),
              ),
              ButtonSegment(
                value: ProtocolConfig.modalityDigits,
                label: Text('Números'),
                icon: Icon(Icons.pin),
              ),
            ],
            selected: {_modality},
            onSelectionChanged: (s) {
              if (s.isEmpty) return;
              setState(() => _modality = s.first);
            },
          ),
          const SizedBox(height: 20),
          Text('Longitud de la secuencia: $_length'),
          Slider(
            value: _length.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '$_length',
            onChanged: (v) {
              setState(() => _length = v.round());
            },
          ),
          const Text(
            'Ritmo encode (memorizar)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Tiempo que dura en pantalla cada estímulo. Más lento = más fácil al principio (p. ej. 4–6 s).',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _encodeSecPerStimulus == _encodeSecPerStimulus.roundToDouble()
                ? '${_encodeSecPerStimulus.round()} s / estímulo'
                : '${_encodeSecPerStimulus.toStringAsFixed(1)} s / estímulo',
            style: const TextStyle(
              color: Color(0xFFCFA870),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Slider(
            value: _encodeSecPerStimulus,
            min: 1.0,
            max: 10.0,
            divisions: 18, // 0,5 s entre 1 y 10
            label: '${_encodeSecPerStimulus.toStringAsFixed(1)} s',
            onChanged: (v) {
              setState(() => _encodeSecPerStimulus = v);
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 s (rápido)', style: TextStyle(fontSize: 11, color: Colors.white54)),
              Text('10 s (lento)', style: TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Pausa entre inmediato y recall diferido',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Mayor = más descanso antes de volver a acordarte (p. ej. 90 s si vas empezando). Sigue pudiendo usar Skip en la pausa.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_interRecallSec s de espera (cuenta atrás en pantalla)',
            style: const TextStyle(
              color: Color(0xFF9EC9E0),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Slider(
            value: _interRecallSec.toDouble(),
            min: 20,
            max: 180,
            divisions: 32, // 5 s por paso (20, 25, …, 180)
            label: '$_interRecallSec s',
            onChanged: (v) {
              setState(() => _interRecallSec = v.round());
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('20 s', style: TextStyle(fontSize: 11, color: Colors.white54)),
              Text('180 s (3 min)', style: TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  void _start() {
    final c = ProtocolConfig(
      modality: _modality,
      chunkSize: 2,
      sequenceLength: _length,
      targetSpeedSec: _encodeSecPerStimulus,
      interRecallDelaySec: _interRecallSec,
      sessionNumber: _sessionN,
    );
    setState(() => _sessionN++);
    final s = ActiveTrainingSession()..newRun(c);
    if (!mounted) {
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (ctx) => EncodeScreen(
              session: s,
              store: widget.sessionStore,
            ),
          ),
        )
        .then((_) {
          if (mounted) {
            _refreshCsv();
          }
        });
  }

  Widget _lastSessionCard() {
    final byDate = List<DailyMetricRow>.of(_csv)..sort((a, b) => a.dateUtc.compareTo(b.dateUtc));
    final last = byDate.last;
    return Card(
      color: const Color(0xFF1E2A1E),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Avance (última fila en CSV)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFFCFD4C0),
                  ),
                ),
                Text('${byDate.length} en historial', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            MetricBar(
              label: 'Score (tope 1) · ${last.dateUtc}',
              valueText: '${(last.scoreNorm * 100).round()}%',
              bar: last.scoreNorm.clamp(0, 1),
            ),
            MetricBar(
              label: 'Acierto inm. / dif. (última guardada)',
              valueText: '${(last.accImmediate * 100).round()}% · ${(last.accDelayed * 100).round()}%',
              bar: (last.accImmediate + last.accDelayed) / 2,
            ),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (ctx) => ProgressScreen(store: widget.sessionStore)),
                );
              },
              child: const Text('Ver gráfica y resumen de historial'),
            ),
          ],
        ),
      ),
    );
  }
}
