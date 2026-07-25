import 'dart:math' show Random;

import 'package:flutter/material.dart';

import '../app_state/training_orchestrator.dart';
import '../models/protocol_config.dart';
import '../models/self_report.dart';
import '../models/stimulus.dart';
import '../services/score_calculator.dart';
import '../services/session_store.dart';
import '../widgets/sequence_input.dart';
import 'delay_screen.dart';
import 'results_screen.dart';

const String _kInputModeReorder = 'reorder';
const String _kInputModeType = 'type';

void _showSequencePeek(
  BuildContext context,
  ActiveTrainingSession session, {
  required void Function() onUsed,
}) {
  onUsed();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Vista rápida (recuerda el orden; esto se registra en el JSONL)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: session.sequence.length,
                  itemBuilder: (context, i) {
                    final s = session.sequence[i];
                    return ListTile(
                      dense: true,
                      leading: Text('${i + 1}'),
                      title: Text(
                        s.id,
                        style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

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
  bool _peekReferenceUsed = false;
  String _selfReport = kSelfReportGood;
  bool _useReorder = true;
  late List<Stimulus> _reorderStimuli;

  @override
  void initState() {
    super.initState();
    _reorderStimuli = List<Stimulus>.from(widget.session.sequence)..shuffle(Random());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _reshuffle() {
    setState(() {
      _reorderStimuli.shuffle(Random());
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final x = _reorderStimuli.removeAt(oldIndex);
      _reorderStimuli.insert(newIndex, x);
    });
  }

  String _syntheticStringFromOrder() {
    final c = widget.session.config!;
    if (c.modality == ProtocolConfig.modalityCards) {
      return _reorderStimuli.map((s) => s.id).join(' | ');
    }
    return _reorderStimuli.map((s) => s.id).join(' ');
  }

  void _syncTypeFieldFromOrder() {
    _ctrl.text = _syntheticStringFromOrder();
  }

  void _setUseReorder(bool v) {
    setState(() {
      _useReorder = v;
      if (!_useReorder) {
        _syncTypeFieldFromOrder();
      }
    });
  }

  String _userInputForSubmit() {
    if (_useReorder) {
      return _syntheticStringFromOrder();
    }
    return _ctrl.text;
  }

  String _recallInputMode() => _useReorder ? _kInputModeReorder : _kInputModeType;

  Future<void> _submit() async {
    if (!_useReorder) {
      final t = _ctrl.text.trim();
      if (t.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe la secuencia o cambia a Ordenar.')),
        );
        return;
      }
    }

    _sw.stop();
    final lms = _sw.elapsedMilliseconds;
    final list = widget.session.buildRecallEvents(
      phase: widget.phase,
      userInput: _userInputForSubmit(),
      totalLatencyMs: lms,
      selfReport: _selfReport,
      recallInputMode: _recallInputMode(),
      peekReferenceUsed: _peekReferenceUsed,
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
          const Text('Cómo te resultó', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -1, vertical: -2)),
            showSelectedIcon: false,
            segments: [
              for (final v in kSelfReportValues)
                ButtonSegment(
                  value: v,
                  label: Text(selfReportLabelEs(v)),
                ),
            ],
            selected: {_selfReport},
            onSelectionChanged: (s) {
              if (s.isEmpty) {
                return;
              }
              setState(() => _selfReport = s.first);
            },
          ),
          const SizedBox(height: 20),
          const Text('Cómo responder', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Ordenar'), icon: Icon(Icons.swap_vert, size: 18)),
              ButtonSegment(value: false, label: Text('Escribir'), icon: Icon(Icons.keyboard, size: 18)),
            ],
            selected: {_useReorder},
            onSelectionChanged: (s) {
              if (s.isEmpty) {
                return;
              }
              _setUseReorder(s.first);
            },
          ),
          const SizedBox(height: 8),
          Text(
            _useReorder
                ? (c.modality == ProtocolConfig.modalityCards
                    ? 'Arrastra los pares al orden que recuerdes. La lista sale barajada; puedes re-barajar. Tras Enviar, en Resultados verás el orden correcto y el tuyo, fila a fila.'
                    : 'Arrastra los números al orden que recuerdes. Tras Enviar, en Resultados verás el orden correcto y el tuyo, fila a fila.')
                : (c.modality == ProtocolConfig.modalityCards
                    ? 'Mismo formato: pares separados por |. En Resultados: tabla de comparación con el encode.'
                    : 'Dígitos 00-99, separados por espacios. En Resultados: comparación con el encode.'),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_useReorder) ...[
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _reshuffle,
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text('Re-barajar posiciones'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: _ReorderStimuliList(
                items: _reorderStimuli,
                onReorder: _onReorder,
              ),
            ),
          ] else ...[
            SequenceInputField(
              modality: c.modality,
              controller: _ctrl,
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              _showSequencePeek(
                context,
                widget.session,
                onUsed: () => setState(() => _peekReferenceUsed = true),
              );
            },
            icon: const Icon(Icons.visibility_outlined, size: 20),
            label: const Text('Vista rápida (ver secuencia)'),
          ),
          if (_peekReferenceUsed) ...[
            const SizedBox(height: 8),
            const Text(
              'Vista rápida usada: contexto con peek_reference_used: true en JSONL',
              style: TextStyle(fontSize: 12, color: Colors.amber),
            ),
          ],
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

class _ReorderStimuliList extends StatelessWidget {
  const _ReorderStimuliList({
    required this.items,
    required this.onReorder,
  });

  final List<Stimulus> items;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: items.length,
        onReorder: onReorder,
        itemBuilder: (context, i) {
          final s = items[i];
          return ListTile(
            key: ValueKey('${s.id}@$i'),
            title: Text(
              s.id,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            trailing: ReorderableDragStartListener(
              index: i,
              child: const Icon(Icons.drag_handle),
            ),
          );
        },
      ),
    );
  }
}
