import 'package:flutter/material.dart';

import '../app_state/training_orchestrator.dart';
import '../models/protocol_config.dart';
import '../services/score_calculator.dart';
import '../services/session_store.dart';
import '../widgets/confidence_slider.dart';
import '../widgets/sequence_input.dart';
import 'delay_screen.dart';
import 'results_screen.dart';

class RecallScreen extends StatefulWidget {
  const RecallScreen({
    super.key,
    required this.session,
    required this.store,
    required this.phase,
  });

  final ActiveTrainingSession session;
  final SessionStore store;
  final String phase; // recall_immediate | recall_delayed

  @override
  State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen> {
  final _ctrl = TextEditingController();
  final _sw = Stopwatch()..start();
  double _conf = 0.7;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _sw.stop();
    final lms = _sw.elapsedMilliseconds;
    final list = widget.session.buildRecallEvents(
      phase: widget.phase,
      userInput: _ctrl.text,
      totalLatencyMs: lms,
      confidence: _conf,
    );
    for (final e in list) {
      widget.store.appendEventFrom(e);
    }
    if (widget.phase == 'recall_immediate') {
      widget.session.lastImmediate = list;
    } else {
      widget.session.lastDelayed = list;
    }

    if (!mounted) {
      return;
    }
    if (widget.phase == 'recall_immediate') {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (ctx) => DelayScreen(
            session: widget.session,
            store: widget.store,
          ),
        ),
      );
    } else {
      final m = ScoreCalculator.computeFromEvents(
        immediate: widget.session.lastImmediate,
        delayed: widget.session.lastDelayed,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (ctx) => ResultsScreen(
            session: widget.session,
            store: widget.store,
            metrics: m,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.session.config!;
    final t = widget.phase == 'recall_immediate' ? 'Recall inmediato' : 'Recall diferido (tras pausa)';

    return Scaffold(
      appBar: AppBar(
        title: Text(t),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            c.modality == ProtocolConfig.modalityCards
                ? 'Escribe la secuencia (mismo número de pares).'
                : 'Escribe los números en el mismo orden.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          SequenceInputField(
            modality: c.modality,
            controller: _ctrl,
          ),
          const SizedBox(height: 20),
          ConfidenceBlock(
            value: _conf,
            onChanged: (v) => setState(() => _conf = v),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
