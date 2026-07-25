import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/self_report.dart';
import '../models/stimulus.dart';

/// Bloque: orden del encode = referencia de verdad.
class EncodeOrderReferenceCard extends StatelessWidget {
  const EncodeOrderReferenceCard({super.key, required this.sequence});

  final List<Stimulus> sequence;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined, size: 22, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Orden correcto (encode)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Referencia: así salió la secuencia; compara con lo que reordenaste o escribiste en cada fase de recall.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < sequence.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${i + 1}.',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        sequence[i].id,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RecallCompareCard extends StatelessWidget {
  const RecallCompareCard({
    super.key,
    required this.title,
    required this.events,
  });

  final String title;
  final List<TrainingEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }
    final first = events.first;
    final mode = first.recallInputMode;
    final sr = first.selfReport;
    final labelMode = mode == 'reorder'
        ? 'Ordenar (arrastre)'
        : mode == 'type'
            ? 'Escribir (teclado)'
            : mode ?? '—';
    final labelReport = sr != null ? selfReportLabelEs(sr) : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Tu criterio: $labelReport  ·  Entrada: $labelMode',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            _CompareTableHeader(),
            for (var i = 0; i < events.length; i++) _CompareRow(e: events[i], index: i + 1),
          ],
        ),
      ),
    );
  }
}

class _CompareTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const h = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Colors.white60,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: h)),
          Expanded(flex: 2, child: Text('Debería ser (orden correcto)', style: h)),
          Expanded(flex: 2, child: Text('Respondiste (tu orden)', style: h)),
          SizedBox(width: 64, child: Text('Estado', style: h, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.e, required this.index});

  final TrainingEvent e;
  final int index;

  @override
  Widget build(BuildContext context) {
    final u = e.userInput?.trim() ?? '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text('$index', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              e.stimulusId,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              u,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: (e.errorType == null) ? const Color(0xFF7FD196) : Colors.white,
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: _StatusPill(e: e),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.e});

  final TrainingEvent e;

  @override
  Widget build(BuildContext context) {
    final t = e.errorType;
    late Color bg;
    late String label;
    if (t == null) {
      bg = const Color(0xFF1B4D3E);
      label = 'OK';
    } else if (t == 'order') {
      bg = const Color(0xFF5C4A1A);
      label = 'Orden';
    } else if (t == 'omit' || t == 'missing') {
      bg = const Color(0xFF3D3D3D);
      label = 'Falta';
    } else {
      bg = const Color(0xFF4A1A1A);
      label = 'Cambio';
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
