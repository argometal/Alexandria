import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../library_build.dart';
import 'match_cards_store.dart';

/// Resumen del mazo: KPIs + mini‑histograma por paso Fib (sin dependencias de gráficas).
class MatchCardsDeckOverviewCard extends StatelessWidget {
  const MatchCardsDeckOverviewCard({
    super.key,
    required this.overview,
  });

  final LbMatchDeckOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mx = overview.countByFibIndex.fold<int>(
      0,
      (m, c) => m > c ? m : c,
    );
    final maxH = 52.0;

    return Card(
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.matchCardsSessionStatsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.matchCardsDeckOverviewKpis(
                overview.pairCount,
                overview.dueCount,
                overview.matchRatePercentOrDash(),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.matchCardsDeckOverviewFibBars,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: maxH + 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < overview.countByFibIndex.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
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
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$i',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 8,
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
      ),
    );
  }
}
