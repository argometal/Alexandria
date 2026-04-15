import 'package:flutter/material.dart';

import 'alexandria_lb_theme.dart';
import 'l10n/app_localizations.dart';

/// Guía de usuario: realms, parcours, objetos, LB, GK, métricas, bridge (sin detalle de código).
class AlexandriaHelpPage extends StatelessWidget {
  const AlexandriaHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    Widget section(String title, String body) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.titleMedium?.copyWith(
                color: AlexandriaLbTheme.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: t.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.helpGuideTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            section(l.helpGuideOverviewTitle, l.helpGuideOverviewBody),
            section(l.helpGuideRolesTitle, l.helpGuideRolesBody),
            section(l.helpGuideContentTitle, l.helpGuideContentBody),
            section(l.helpGuideCardsTitle, l.helpGuideCardsBody),
            section(l.helpGuideLbTitle, l.helpGuideLbBody),
            section(l.helpGuideGkTitle, l.helpGuideGkBody),
            section(l.helpGuideMetricsTitle, l.helpGuideMetricsBody),
            section(l.helpGuideBridgeTitle, l.helpGuideBridgeBody),
            const SizedBox(height: 8),
            Text(
              l.helpGuideGkHint,
              style: t.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
