import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../alexandria_paths.dart';
import '../l10n/app_localizations.dart';
import 'pao_standard_store.dart';

// Mantener alineado con `pao_individual_drill_page.dart` (tamaños del ejercicio).
const double _kDrillAnswersThumb = 72 * 5;
const double _kDrillPersonObjectThumb = 96 * 5;

File? _absFileForRel(String rel) {
  final t = rel.trim();
  if (t.isEmpty) return null;
  final p =
      '${AlexandriaPaths.assetsRoot}${Platform.pathSeparator}${t.replaceAll('/', Platform.pathSeparator)}';
  final f = File(p);
  return f.existsSync() ? f : null;
}

List<File> _filesForRels(Iterable<String> rels) =>
    rels.map(_absFileForRel).whereType<File>().toList();

double _drillImageSide(BuildContext context, double desired) {
  final w = MediaQuery.sizeOf(context).width;
  final maxByScreen = (w - 32).clamp(160.0, 2000.0);
  return math.min(desired, maxByScreen);
}

Widget _drillThumb(BuildContext context, File img, double desired) {
  final side = _drillImageSide(context, desired);
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      img,
      width: side,
      height: side,
      fit: BoxFit.cover,
      errorBuilder: (ctx, error, _) => Container(
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

/// Vista previa del ejercicio PAO individual: mismos estímulos y panel de respuestas que en la práctica.
class PaoExercisePreviewContent extends StatelessWidget {
  const PaoExercisePreviewContent({super.key, required this.row});

  final PaoStandardRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final codeStr = PaoStandardRow.formatCode(row.code);
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final codeStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        );
    final codeImg = _absFileForRel(row.imageRel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.paoEditPreviewExerciseIntro,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.paoDrillModeCodeTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (codeImg != null) ...[
          Card(
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
                    child: _drillThumb(context, codeImg, _kDrillAnswersThumb),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
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
        ),
        const SizedBox(height: 20),
        Text(
          l10n.paoDrillModePersonTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        _stimulusPersonOrObject(
          context,
          subtitle: l10n.paoDrillStimulusPerson,
          title: row.person.trim().isEmpty ? '—' : row.person,
          imageRels: [row.personImageRel, row.personImageRel2],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.paoDrillModeObjectTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        _stimulusPersonOrObject(
          context,
          subtitle: l10n.paoDrillStimulusObject,
          title: row.object.trim().isEmpty ? '—' : row.object,
          imageRels: [row.objectImageRel, row.objectImageRel2],
        ),
        const SizedBox(height: 20),
        _answersPanel(context, l10n),
      ],
    );
  }

  Widget _stimulusPersonOrObject(
    BuildContext context, {
    required String subtitle,
    required String title,
    required List<String> imageRels,
  }) {
    final files = _filesForRels(
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
                    _drillThumb(context, f, _kDrillPersonObjectThumb),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _answersPanel(BuildContext context, AppLocalizations l10n) {
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
              context,
              l10n.paoFieldCode,
              PaoStandardRow.formatCode(row.code),
              [row.imageRel],
            ),
            _answerSection(
              context,
              l10n.paoFieldPerson,
              row.person,
              [row.personImageRel, row.personImageRel2],
            ),
            _answerLine(context, l10n.paoFieldAction, row.action),
            _answerSection(
              context,
              l10n.paoFieldObject,
              row.object,
              [row.objectImageRel, row.objectImageRel2],
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerLine(BuildContext context, String label, String value) {
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

  Widget _answerSection(
    BuildContext context,
    String label,
    String value,
    List<String> imageRels,
  ) {
    final files = _filesForRels(
      imageRels.map((s) => s.trim()).where((s) => s.isNotEmpty),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _answerLine(context, label, value.isEmpty ? '—' : value),
        if (files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final f in files) _drillThumb(context, f, _kDrillAnswersThumb),
              ],
            ),
          ),
      ],
    );
  }
}
