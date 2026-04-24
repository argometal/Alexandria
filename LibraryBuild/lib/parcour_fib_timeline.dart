import 'package:flutter/material.dart';

import 'parcour_review.dart' show kParcourFibDays;

/// Franja horizontal de hitos Fib (días por índice): mismo eje en
/// `parcour_review_state` y en `locus_review_state` (objetos / Parcour Study).
/// Pasado = verde, índice actual = acento, futuro = gris. Sin fechas de calendario.
class ParcourFibTimelineStrip extends StatelessWidget {
  const ParcourFibTimelineStrip({
    super.key,
    required this.fibIndex,
  });

  /// Índice vigente en `parcour_review_state` (mismo eje que [kParcourFibDays]).
  final int fibIndex;

  static const double _dotSize = 15;
  static const double _connectorWidth = 22;
  static const double _connectorHeight = 4;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = kParcourFibDays.length;
    if (n == 0) return const SizedBox.shrink();

    final current = fibIndex.clamp(0, n - 1);
    final doneLine = const Color(0xFF689F38);
    final doneNode = const Color(0xFF7CB342);
    final idleLine = Color.alphaBlend(
      cs.outline.withValues(alpha: 0.55),
      cs.surfaceContainerHighest,
    );
    final idleNode = cs.onSurfaceVariant.withValues(alpha: 0.55);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < n; i++) ...[
              if (i > 0)
                Padding(
                  padding: EdgeInsets.only(top: _dotSize / 2 - _connectorHeight / 2),
                  child: Container(
                    width: _connectorWidth,
                    height: _connectorHeight,
                    decoration: BoxDecoration(
                      color: (fibIndex < 0 ? 0 : fibIndex) >= i ? doneLine : idleLine,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: (fibIndex < 0 ? 0 : fibIndex) >= i
                          ? [
                              BoxShadow(
                                color: doneLine.withValues(alpha: 0.35),
                                blurRadius: 0,
                                spreadRadius: 0,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              _FibNode(
                days: kParcourFibDays[i],
                isPast: i < current,
                isCurrent: i == current,
                isFuture: i > current,
                activeColor: cs.tertiary,
                onActive: cs.onTertiary,
                doneFill: doneNode,
                idleFill: idleNode,
                idleBorder: cs.outlineVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FibNode extends StatelessWidget {
  const _FibNode({
    required this.days,
    required this.isPast,
    required this.isCurrent,
    required this.isFuture,
    required this.activeColor,
    required this.onActive,
    required this.doneFill,
    required this.idleFill,
    required this.idleBorder,
  });

  final int days;
  final bool isPast;
  final bool isCurrent;
  final bool isFuture;
  final Color activeColor;
  final Color onActive;
  final Color doneFill;
  final Color idleFill;
  final Color idleBorder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    late final Color fill;
    late final Color border;
    late final double stroke;
    if (isCurrent) {
      fill = activeColor;
      border = onActive;
      stroke = 3;
    } else if (isPast) {
      fill = doneFill;
      border = doneFill.withValues(alpha: 0.9);
      stroke = 2;
    } else {
      fill = idleFill;
      border = idleBorder.withValues(alpha: 0.85);
      stroke = 1.5;
    }

    return Tooltip(
      message: '+$days d',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ParcourFibTimelineStrip._dotSize,
            height: ParcourFibTimelineStrip._dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: border, width: stroke),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.55),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+$days',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isFuture
                      ? cs.onSurfaceVariant.withValues(alpha: 0.78)
                      : isCurrent
                          ? cs.tertiary
                          : cs.onSurface.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
  }
}
