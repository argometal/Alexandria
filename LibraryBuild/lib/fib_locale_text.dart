import 'l10n/app_localizations.dart';

/// Tiempos relativos cortos para agregados Fib (barra de estado / Parcour review).
String fibFormatRelPast(DateTime t, DateTime now, AppLocalizations l) {
  final d = now.difference(t);
  if (d.inMinutes < 90) return l.fibRelPastMinutes(d.inMinutes);
  if (d.inHours < 48) return l.fibRelPastHours(d.inHours);
  return l.fibRelPastDays(d.inDays);
}

String fibFormatRelFuture(DateTime t, DateTime now, AppLocalizations l) {
  final d = t.difference(now);
  if (d.inMinutes < 90) return l.fibRelFutureMinutes(d.inMinutes);
  if (d.inHours < 48) return l.fibRelFutureHours(d.inHours);
  return l.fibRelFutureDays(d.inDays);
}
