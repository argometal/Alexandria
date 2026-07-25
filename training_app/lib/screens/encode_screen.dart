import 'package:flutter/material.dart';

import '../app_state/training_orchestrator.dart';
import '../models/event.dart';
import '../services/session_store.dart';
import 'recall_screen.dart';

class EncodeScreen extends StatefulWidget {
  const EncodeScreen({super.key, required this.session, required this.store});

  final ActiveTrainingSession session;
  final SessionStore store;

  @override
  State<EncodeScreen> createState() => _EncodeScreenState();
}

class _EncodeScreenState extends State<EncodeScreen> {
  int _i = 0;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final c = widget.session.config!;
    final q = widget.session.sequence;
    final wait = Duration(
      milliseconds: (c.targetSpeedSec * 1000).round(),
    );
    for (var j = 0; j < q.length; j++) {
      if (!mounted) {
        return;
      }
      setState(() {
        _i = j;
      });
      final ev = TrainingEvent(
        sessionId: widget.session.sessionId,
        t: DateTime.now().toUtc(),
        phase: 'encode',
        modality: c.modality,
        stimulusId: q[j].id,
        stimulusPosition: q[j].position,
      );
      widget.store.appendEventFrom(ev);
      await Future<void>.delayed(wait);
      if (!mounted) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => _running = false);
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (ctx) => RecallScreen(
          session: widget.session,
          store: widget.store,
          phase: 'recall_immediate',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.session.config;
    if (c == null) {
      return const SizedBox.shrink();
    }
    final seq = widget.session.sequence;
    final t = _running && _i < seq.length ? seq[_i].id : '…';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encode (memoriza)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${_i + 1} / ${seq.length}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Text(
              t,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              c.targetSpeedSec == c.targetSpeedSec.roundToDouble()
                  ? '${c.targetSpeedSec.round()} s / estímulo (ajustas en inicio)'
                  : '${c.targetSpeedSec.toStringAsFixed(1)} s / estímulo (ajustas en inicio)',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
