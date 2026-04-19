import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_paths.dart';
import '../library_build.dart';
import '../l10n/app_localizations.dart';

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

List<File> _paoFilesForRels(Iterable<String> rels) =>
    rels.map(_paoAbsFileForRel).whereType<File>().toList();

/// Escala ~5× respecto a las miniaturas originales (~72 / ~96 / ~200); acotado al ancho de pantalla.
double _paoDrillImageSide(BuildContext context, double desired) {
  final w = MediaQuery.sizeOf(context).width;
  final maxByScreen = (w - 32).clamp(160.0, 2000.0);
  return math.min(desired, maxByScreen);
}

class _PaoIndividualDrillPageState extends State<PaoIndividualDrillPage> {
  final _rng = math.Random();

  List<PaoStandardRow> _pool = [];
  PaoStandardRow? _row;
  _PaoDrillMode _mode = _PaoDrillMode.codeToPao;
  int _modeOrdinal = 0;

  /// Respuestas visibles tras "Mostrar respuestas".
  bool _answersVisible = false;

  /// Modo código: en cada ronda solo imagen del código **o** solo número (nunca ambos), si hay imagen.
  bool _codeRoundShowImage = false;

  @override
  void initState() {
    super.initState();
    ensureLibrarySchema(widget.db);
    _reloadPoolAndStart();
  }

  void _reloadPoolAndStart() {
    final pairs = loadPaoStandardMerged(widget.db);
    final digits = loadPaoDigitMerged(widget.db);
    final triples = loadPaoTripleMerged(widget.db);
    _pool = [...pairs, ...digits, ...triples]
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
      _rollCodeStimulusSide();
    });
  }

  void _rollCodeStimulusSide() {
    if (_mode != _PaoDrillMode.codeToPao || _row == null) {
      _codeRoundShowImage = false;
      return;
    }
    final img = _paoAbsFileForRel(_row!.imageRel);
    _codeRoundShowImage = img != null && _rng.nextBool();
  }

  void _showAnswers() {
    setState(() => _answersVisible = true);
  }

  String _modeTitle(AppLocalizations l10n) {
    switch (_mode) {
      case _PaoDrillMode.codeToPao:
        return l10n.paoDrillModeCodeTitle;
      case _PaoDrillMode.personToRest:
        return l10n.paoDrillModePersonTitle;
      case _PaoDrillMode.objectToRest:
        return l10n.paoDrillModeObjectTitle;
    }
  }

  Widget _paoImageThumb(BuildContext context, File img, double desiredSize) {
    final side = _paoDrillImageSide(context, desiredSize);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        img,
        width: side,
        height: side,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => Container(
          width: side,
          height: side,
          color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(ctx).colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _stimulusCard(PaoStandardRow r, AppLocalizations l10n) {
    switch (_mode) {
      case _PaoDrillMode.codeToPao:
        return _stimulusCodeWithOptionalImage(r, l10n);
      case _PaoDrillMode.personToRest:
        return _stimulusWithOptionalImages(
          title: r.person,
          imageRels: [r.personImageRel, r.personImageRel2],
          subtitle: l10n.paoDrillStimulusPerson,
        );
      case _PaoDrillMode.objectToRest:
        return _stimulusWithOptionalImages(
          title: r.object,
          imageRels: [r.objectImageRel, r.objectImageRel2],
          subtitle: l10n.paoDrillStimulusObject,
        );
    }
  }

  /// Persona / objeto (antes ~96 lógico).
  static const double _kPersonObjectStimulusThumbSize = 96 * 5;
  /// Miniaturas en respuestas y en «Recuerda el número» (imagen del código) — mismo tamaño.
  static const double _kAnswersThumbSize = 72 * 5;

  /// Modo código: **solo número** o **solo imagen del código** (aleatorio por ronda si hay imagen).
  Widget _stimulusCodeWithOptionalImage(
    PaoStandardRow r,
    AppLocalizations l10n,
  ) {
    final img = _paoAbsFileForRel(r.imageRel);
    final codeStr = PaoStandardRow.formatCode(r.code);
    final codeStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        );
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    if (img == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.paoDrillStimulusCode, style: labelStyle),
                const SizedBox(height: 12),
                Text(codeStr, style: codeStyle, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    if (_codeRoundShowImage) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.paoDrillStimulusRecallNumber,
                style: labelStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: _paoImageThumb(context, img, _kAnswersThumbSize),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.paoDrillStimulusRecallMnemonic,
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(codeStr, style: codeStyle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Persona u objeto: hasta dos imágenes (`_p1` / `_p2` o `_o1` / `_o2`).
  Widget _stimulusWithOptionalImages({
    required String title,
    required List<String> imageRels,
    required String subtitle,
  }) {
    final files = _paoFilesForRels(
      imageRels.map((s) => s.trim()).where((s) => s.isNotEmpty),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            if (files.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final f in files)
                    _paoImageThumb(context, f, _kPersonObjectStimulusThumbSize),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _answersPanel(PaoStandardRow r, AppLocalizations l10n) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paoDrillAnswersHeading,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _answerSection(
              l10n.paoFieldCode,
              PaoStandardRow.formatCode(r.code),
              [r.imageRel],
            ),
            _answerSection(
              l10n.paoFieldPerson,
              r.person,
              [r.personImageRel, r.personImageRel2],
            ),
            _answerLine(l10n.paoFieldAction, r.action),
            _answerSection(
              l10n.paoFieldObject,
              r.object,
              [r.objectImageRel, r.objectImageRel2],
            ),
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

  Widget _answerSection(String label, String value, List<String> imageRels) {
    final files = _paoFilesForRels(
      imageRels.map((s) => s.trim()).where((s) => s.isNotEmpty),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _answerLine(label, value),
        if (files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final f in files)
                  _paoImageThumb(context, f, _kAnswersThumbSize),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_pool.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.paoPracticeTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.paoDrillEmptyTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.paoDrillEmptyHint,
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
        title: Text(l10n.paoPracticeTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.paoDrillInstruction,
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
                label: Text(_modeTitle(l10n)),
              ),
              Text(
                l10n.paoDrillPoolInfo(
                  _pool.length,
                  AlexandriaPaths.readActiveRealmId(),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.paoDrillPoolAllTiersHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          _stimulusCard(r, l10n),
          const SizedBox(height: 20),
          if (!_answersVisible) ...[
            FilledButton.icon(
              onPressed: _showAnswers,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.paoDrillShowAnswers),
            ),
          ] else ...[
            _answersPanel(r, l10n),
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
                    label: Text(l10n.paoDrillSuccess),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pickNewRound(rotateMode: true),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(l10n.paoDrillFail),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _pickNewRound(rotateMode: true),
              icon: const Icon(Icons.skip_next),
              label: Text(l10n.paoDrillNextUnmarked),
            ),
          ],
        ],
      ),
    );
  }
}
