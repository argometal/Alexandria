import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../alexandria_paths.dart';
import '../library_build.dart';

const double _kMinTouch = 44;

/// Hero del locus: misma resolución que la lista principal LB.
String? _resolveHeroPath(String entryKey, String? bodyText) {
  final sep = Platform.pathSeparator;
  final baseDir = Directory('${AlexandriaPaths.assetsRoot}$sep$entryKey');
  for (final name in ['hero.png', 'hero.jpg', 'hero.jpeg', 'hero.webp']) {
    final f = File('${baseDir.path}$sep$name');
    if (f.existsSync()) return f.path;
  }
  final blocks = parseBody(bodyText);
  for (final b in blocks) {
    if (b['type'] != 'img') continue;
    final src = (b['src'] ?? '').toString().trim();
    if (src.isEmpty) continue;
    final direct = File(src);
    if (direct.existsSync()) return src;
    final underKey = File('${baseDir.path}$sep$src');
    if (underKey.existsSync()) return underKey.path;
    final underRoot = File('${AlexandriaPaths.assetsRoot}$sep$src');
    if (underRoot.existsSync()) return underRoot.path;
  }
  return null;
}

String? _firstParagraphByKind(String? bodyText, String textKind) {
  final blocks = parseBody(bodyText);
  for (final b in blocks) {
    if (b['type'] != 'p') continue;
    final tk = b['textKind']?.toString().toLowerCase().trim() ?? '';
    if (tk != textKind) continue;
    final t = (b['text'] ?? '').toString().trim();
    if (t.isNotEmpty) return t;
  }
  return null;
}

/// Paso de estudio por locus: **place** obligatorio (ancla con hero); hint/ridiculous opcionales.
class _StudyLocus {
  _StudyLocus({
    required this.key,
    required this.title,
    required this.bodyText,
    required this.placeText,
    this.hintText,
    this.ridiculousText,
    this.heroPath,
  });

  final String key;
  final String title;
  final String? bodyText;
  final String placeText;
  final String? hintText;
  final String? ridiculousText;
  final String? heroPath;
}

enum _StudyPhase { placeHero, ridiculousFlash, finished }

/// Parcour Study: **place + hero** → good/medium/fail; hint opcional (tope **medium** si pulsas good);
/// luego **ridiculous story** (Continuar) y siguiente locus.
class ParcourStudyPage extends StatefulWidget {
  const ParcourStudyPage({
    super.key,
    required this.db,
    required this.parcourKey,
  });

  final Database db;
  final String parcourKey;

  @override
  State<ParcourStudyPage> createState() => _ParcourStudyPageState();
}

class _ParcourStudyPageState extends State<ParcourStudyPage> {
  List<_StudyLocus>? _items;
  String? _error;

  int _currentIndex = 0;
  _StudyPhase _phase = _StudyPhase.placeHero;
  bool _hintRevealed = false;
  final List<ParcourLocusEval> _sessionEvals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      ensureLibrarySchema(widget.db);
      final r = widget.db.select(
        'SELECT key, seq, title, body_text FROM entries WHERE parentKey = ? AND cognitiveRole = ? ORDER BY seq ASC',
        [widget.parcourKey, 'object'],
      );
      final list = <_StudyLocus>[];
      for (final row in r) {
        final k = row['key']?.toString() ?? '';
        final body = row['body_text'] as String?;
        final place = _firstParagraphByKind(body, 'place');
        if (place == null || place.isEmpty) continue;
        final title = (row['title'] as String?)?.trim();
        list.add(
          _StudyLocus(
            key: k,
            title: (title != null && title.isNotEmpty) ? title : k,
            bodyText: body,
            placeText: place,
            hintText: _firstParagraphByKind(body, 'hint'),
            ridiculousText: _firstParagraphByKind(body, 'ridiculous_story'),
            heroPath: _resolveHeroPath(k, body),
          ),
        );
      }
      setState(() {
        _items = list;
        _error = null;
        _currentIndex = 0;
        _phase = list.isEmpty ? _StudyPhase.finished : _StudyPhase.placeHero;
        _hintRevealed = false;
        _sessionEvals.clear();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _items = null;
      });
    }
  }

  _StudyLocus? get _current {
    final items = _items;
    if (items == null || items.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= items.length) return null;
    return items[_currentIndex];
  }

  void _onPickRating(LocusRatingKind uiRating) {
    final loc = _current;
    if (loc == null || _phase != _StudyPhase.placeHero) return;

    final effective = _hintRevealed && uiRating == LocusRatingKind.good
        ? LocusRatingKind.medium
        : uiRating;

    _sessionEvals.add(
      ParcourLocusEval(
        locusKey: loc.key,
        rating: effective,
        wasReviewed: true,
      ),
    );

    final ridiculous = loc.ridiculousText;
    if (ridiculous != null && ridiculous.trim().isNotEmpty) {
      setState(() => _phase = _StudyPhase.ridiculousFlash);
    } else {
      _advanceAfterRidiculous();
    }
  }

  void _advanceAfterRidiculous() {
    if (!mounted) return;
    setState(() {
      _hintRevealed = false;
      _currentIndex++;
      if (_items != null && _currentIndex >= _items!.length) {
        _phase = _StudyPhase.finished;
      } else {
        _phase = _StudyPhase.placeHero;
      }
    });
  }

  Future<void> _saveSession(BuildContext context) async {
    if (_sessionEvals.isEmpty) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    ensureLibrarySchema(widget.db);
    final now = DateTime.now();

    applyParcourReviewSession(
      db: widget.db,
      parcourKey: widget.parcourKey,
      evals: List<ParcourLocusEval>.from(_sessionEvals),
      now: now,
    );

    try {
      writeParcourReviewBridgeSummary(widget.db);
    } catch (_) {}

    try {
      runLibraryBuild();
    } catch (_) {}

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión de Parcour Review registrada')),
    );
    Navigator.of(context).pop();
  }

  Widget _ratingBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.tonal(
          onPressed: () => _onPickRating(LocusRatingKind.good),
          child: const Text('Good'),
        ),
        FilledButton.tonal(
          onPressed: () => _onPickRating(LocusRatingKind.medium),
          child: const Text('Medium'),
        ),
        FilledButton.tonal(
          onPressed: () => _onPickRating(LocusRatingKind.fail),
          child: const Text('Fail'),
        ),
      ],
    );
  }

  Widget _placeHeroBody(BuildContext context) {
    final loc = _current!;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            loc.key,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: cs.outline,
                ),
          ),
          const SizedBox(height: 16),
          if (loc.heroPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.file(
                  File(loc.heroPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: cs.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Text('Imagen no disponible'),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cs.surfaceContainerHighest,
              ),
              child: Text(
                'Sin hero en assets / primera imagen en body',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Place',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.placeText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (loc.hintText != null && loc.hintText!.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (!_hintRevealed)
              OutlinedButton.icon(
                onPressed: () => setState(() => _hintRevealed = true),
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Ver hint (opcional)'),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: cs.tertiaryContainer.withValues(alpha: 0.35),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hint',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onTertiaryContainer,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(loc.hintText!, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hint visible → Good se registrará como Medium',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          Text(
            'Tu calificación',
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _ratingBar(),
        ],
      ),
    );
  }

  Widget _ridiculousFlashBody(BuildContext context) {
    final loc = _current!;
    final text = loc.ridiculousText ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ridiculous story',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _advanceAfterRidiculous,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parcour Study')),
        body: Center(child: Text(_error!)),
      );
    }

    final items = _items;
    if (items == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parcour Study')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Ningún objeto con bloque **place** bajo este parcour.\n'
              'Añade place en el editor para poder estudiar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final total = items.length;
    final n = _currentIndex + 1;
    final subtitle = _phase == _StudyPhase.finished
        ? 'Sesión lista'
        : '$n / $total · ${_current?.key ?? ""}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Parcour Study'),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      body: _phase == _StudyPhase.finished
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _sessionEvals.isEmpty
                          ? 'No se registraron calificaciones.'
                          : 'Listo: ${_sessionEvals.length} locus evaluados.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: _kMinTouch + 8,
                      child: FilledButton(
                        onPressed: _sessionEvals.isEmpty
                            ? () => Navigator.of(context).pop()
                            : () => _saveSession(context),
                        child: Text(
                          _sessionEvals.isEmpty ? 'Cerrar' : 'Guardar sesión',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _phase == _StudyPhase.ridiculousFlash
              ? _ridiculousFlashBody(context)
              : _placeHeroBody(context),
    );
  }
}
