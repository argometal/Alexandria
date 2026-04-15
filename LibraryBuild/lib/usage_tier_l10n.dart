import 'fts_object_search.dart';
import 'l10n/app_localizations.dart';
import 'realm_shelf.dart';

/// Etiquetas cortas compartidas (estantes realm y bandas de búsqueda FTS).
String l10nRealmShelfTierShort(AppLocalizations l, RealmShelfTier t) {
  return switch (t) {
    RealmShelfTier.core => l.usageBandCore,
    RealmShelfTier.active => l.usageBandActive,
    RealmShelfTier.seek => l.usageBandSeek,
  };
}

String l10nUsageBandShort(AppLocalizations l, UsageBand b) {
  return switch (b) {
    UsageBand.core => l.usageBandCore,
    UsageBand.active => l.usageBandActive,
    UsageBand.seek => l.usageBandSeek,
  };
}

String l10nUsageBandSubtitle(AppLocalizations l, UsageBand b) {
  return switch (b) {
    UsageBand.core => l.usageBandSubtitleCore,
    UsageBand.active => l.usageBandSubtitleActive,
    UsageBand.seek => l.usageBandSubtitleSeek,
  };
}

String l10nRealmShelfPopup(AppLocalizations l, RealmShelfTier t) {
  return switch (t) {
    RealmShelfTier.core => l.realmShelfPopupCore,
    RealmShelfTier.active => l.realmShelfPopupActive,
    RealmShelfTier.seek => l.realmShelfPopupSeek,
  };
}
