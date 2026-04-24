import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../library_build.dart';
import 'match_cards_store.dart';

/// Resumen del mazo: KPIs + mini‑histograma por paso Fib (sin dependencias de gráficas).
class MatchCardsDeckOverviewCard extends StatelessWidget {
  const MatchCardsDeckOverviewCard({
    super.key,
    required this.overview,
    this.compact = false,
    this.showTitleRow = true,
  });

  final LbMatchDeckOverview overview;
  /// Menos padding y barras más bajas (p. ej. dentro de un diálogo).
  final bool compact;
  /// Si false, oculta la fila con icono + título (útil cuando el [AlertDialog] ya tiene título).
  final bool showTitleRow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mx = overview.countByFibIndex.fold<int>(
      0,
      (m, c) => m > c ? m : c,
    );
    final maxH = compact ? 28.0 : 52.0;
    final pad = compact
        ? const EdgeInsets.fromLTRB(8, 6, 8, 6)
        : const EdgeInsets.fromLTRB(12, 10, 12, 10);
    final idxFont = compact ? 7.0 : 8.0;
    final gapBars = compact ? 1.0 : 2.0;

    final inner = Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitleRow) ...[
            Row(
              children: [
                Icon(Icons.insights_outlined,
                    size: compact ? 18 : 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.matchCardsSessionStatsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : null,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 4 : 8),
          ],
          Text(
            l10n.matchCardsDeckOverviewKpis(
              overview.pairCount,
              overview.dueCount,
              overview.matchRatePercentOrDash(),
            ),
            style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                ?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
          Text(
            l10n.matchCardsDeckOverviewFibBars,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: compact ? 10 : null,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          SizedBox(
            height: maxH + (compact ? 14 : 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < overview.countByFibIndex.length; i++) ...[
                  if (i > 0) SizedBox(width: gapBars),
                  Expanded(
                    child: Tooltip(
                      message:
                          '${l10n.matchCardsSessionStatsFib(i)} · ${overview.countByFibIndex[i]} · +${kParcourFibDays[i]}d',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: mx <= 0
                                ? 2.0
                                : (maxH * overview.countByFibIndex[i] / mx)
                                    .clamp(2.0, maxH),
                            decoration: BoxDecoration(
                              color: overview.countByFibIndex[i] > 0
                                  ? cs.tertiary.withValues(alpha: 0.85)
                                  : cs.outlineVariant.withValues(alpha: 0.35),
                              borderRadius:
                                  BorderRadius.circular(compact ? 2 : 4),
                            ),
                          ),
                          SizedBox(height: compact ? 2 : 4),
                          Text(
                            '$i',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: idxFont,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (compact) {
      return inner;
    }

    return Card(
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerHighest,
      child: inner,
    );
  }
}
