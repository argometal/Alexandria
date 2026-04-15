import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_paths.dart';
import '../library_build.dart';
import 'pao_standard_store.dart';

/// Sprint 1 — PAO individual: triple drill rotativo; recall mental, sin escribir respuestas.
class PaoIndividualDrillPage extends StatefulWidget {
  const PaoIndividualDrillPage({super.key, required this.db});

  final Database db;

  @override
  State<PaoIndividualDrillPage> createState() => _PaoIndividualDrillPageState();
}

enum _PaoDrillMode {
  codeToPao,
  personToRest,
  objectToRest,
}

File? _paoAbsFileForRel(String rel) {
  final t = rel.trim();
  if (t.isEmpty) return null;
  final p =
      '${AlexandriaPaths.assetsRoot}${Platform.pathSeparator}${t.replaceAll('/', Platform.pathSeparator)}';
  final f = File(p);
  return f.existsSync() ? f : null;
}

class _PaoIndividualDrillPageState extends State<PaoIndividualDrillPage> {
  final _rng = math.Random();

  List<PaoStandardRow> _pool = [];
  PaoStandardRow? _row;
  _PaoDrillMode _mode = _PaoDrillMode.codeToPao;
  int _modeOrdinal = 0;

  /// Respuestas visibles tras "Mostrar respuestas".
  bool _answersVisible = false;

  @override
  void initState() {
    super.initState();
    ensureLibrarySchema(widget.db);
    _reloadPoolAndStart();
  }

  void _reloadPoolAndStart() {
    final rows = loadPaoStandardMerged(widget.db);
    _pool = rows
        .where((r) =>
            r.person.trim().isNotEmpty &&
            r.action.trim().isNotEmpty &&
            r.object.trim().isNotEmpty)
        .toList();
    if (_pool.isEmpty) {
      setState(() {
        _row = null;
      });
      return;
    }
    _pickNewRound(rotateMode: false);
  }

  void _pickRandomRow() {
    if (_pool.isEmpty) return;
    if (_pool.length == 1) {
      _row = _pool.first;
      return;
    }
    PaoStandardRow? cur = _row;
    var next = _pool[_rng.nextInt(_pool.length)];
    var guard = 0;
    while (next.code == cur?.code && guard++ < 12) {
      next = _pool[_rng.nextInt(_pool.length)];
    }
    _row = next;
  }

  void _pickNewRound({required bool rotateMode}) {
    setState(() {
      if (rotateMode) {
        _modeOrdinal = (_modeOrdinal + 1) % 3;
        _mode = _PaoDrillMode.values[_modeOrdinal];
      }
      _pickRandomRow();
      _answersVisible = false;
    });
  }

  void _showAnswers() {
    setState(() => _answersVisible = true);
  }

  String _modeTitle() {
    switch (_mode) {
      case _PaoDrillMode.codeToPao:
        return 'Código → persona, acción, objeto (mental)';
      case _PaoDrillMode.personToRest:
        return 'Persona → código, acción, objeto (mental)';
      case _PaoDrillMode.objectToRest:
        return 'Objeto → código, persona, acción (mental)';
    }
  }

  Widget _stimulusCard(PaoStandardRow r) {
    switch (_mode) {
      case _PaoDrillMode.codeToPao:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                PaoStandardRow.formatCode(r.code),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
              ),
            ),
          ),
        );
      case _PaoDrillMode.personToRest:
        return _stimulusWithOptionalImage(
          title: r.person,
          imageRel: r.imageRel,
          subtitle: 'Persona',
        );
      case _PaoDrillMode.objectToRest:
        return _stimulusWithOptionalImage(
          title: r.object,
          imageRel: r.imageRel,
          subtitle: 'Objeto',
        );
    }
  }

  Widget _stimulusWithOptionalImage({
    required String title,
    required String imageRel,
    required String subtitle,
  }) {
    final img = _paoAbsFileForRel(imageRel);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (img != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  img,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (img != null) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
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

  Widget _answersPanel(PaoStandardRow r) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Respuestas',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _answerLine('Código', PaoStandardRow.formatCode(r.code)),
            _answerLine('Persona', r.person),
            _answerLine('Acción', r.action),
            _answerLine('Objeto', r.object),
          ],
        ),
      ),
    );
  }

  Widget _answerLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pool.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('PAO · práctica individual')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'No hay códigos listos para practicar.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Rellena persona, acción y objeto en al menos un código (00–99) en PAO (00–99).',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final r = _row!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PAO · práctica individual'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Recuerda en silencio; no escribas. Luego muestra las respuestas y marca acierto o fallo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: const Icon(Icons.shuffle, size: 18),
                label: Text(_modeTitle()),
              ),
              Text(
                '${_pool.length} códigos · realm ${AlexandriaPaths.readActiveRealmId()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _stimulusCard(r),
          const SizedBox(height: 20),
          if (!_answersVisible) ...[
            FilledButton.icon(
              onPressed: _showAnswers,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Mostrar respuestas'),
            ),
          ] else ...[
            _answersPanel(r),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pickNewRound(rotateMode: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Acierto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pickNewRound(rotateMode: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Fallo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _pickNewRound(rotateMode: true),
              icon: const Icon(Icons.skip_next),
              label: const Text('Siguiente (sin marcar)'),
            ),
          ],
        ],
      ),
    );
  }
}
