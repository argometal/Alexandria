// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Realm Library';

  @override
  String activeRealmLabel(String realm) {
    return 'Active realm: $realm';
  }

  @override
  String get sectionReading => 'READING';

  @override
  String get sectionImport => 'IMPORT';

  @override
  String get sectionPao => 'PAO';

  @override
  String get sectionMatchCards => 'MATCH CARDS';

  @override
  String get sectionGo => 'GO';

  @override
  String get sectionMetrics => 'METRICS';

  @override
  String get sectionSystem => 'SYSTEM';

  @override
  String get sectionLanguage => 'LANGUAGE';

  @override
  String get nodeReaderTitle => 'Node reader';

  @override
  String get nodeReaderSubtitle => 'Parcour or object (list)';

  @override
  String get pdfNodeTitle => 'Node PDF';

  @override
  String get pdfNodeSubtitle => 'Object or other entry';

  @override
  String get pdfParcourTitle => 'Parcour PDF';

  @override
  String get pdfParcourSubtitle => 'One parcour per export';

  @override
  String get importLocusTitle => 'Import content into locus';

  @override
  String get importLocusSubtitle => 'From data-transfer/out/ → body_text';

  @override
  String get paoEditorTitle => 'PAO (00–99)';

  @override
  String get paoEditorSubtitle => 'Two-digit system · import / export JSON';

  @override
  String get paoPracticeTitle => 'PAO · individual practice';

  @override
  String get paoPracticeSubtitle =>
      'Mental recall · show answers · pass / fail';

  @override
  String get matchCardsTitle => 'Match cards';

  @override
  String get matchCardsSubtitle =>
      'Image ↔ caption pairs · random session (LB only)';

  @override
  String get matchCardsOrmHint =>
      'Each pair: lemma (native script), optional transliteration, optional meaning (gloss), and image. route_key is for future “along a route”; FSRS table exists but scheduling is not implemented.';

  @override
  String get matchCardsEmpty => 'No pairs yet. Add an image and a caption.';

  @override
  String get matchCardsAddPair => 'Add pair';

  @override
  String get matchCardsPractice => 'Practice';

  @override
  String get matchCardsDeleteTooltip => 'Remove pair';

  @override
  String get matchCardsAddDialogTitle => 'New pair';

  @override
  String get matchCardsLemmaLabel => 'Lemma / word (native script)';

  @override
  String get matchCardsLemmaHint => 'e.g. кошка';

  @override
  String get matchCardsLemmaRequired => 'Enter the lemma first.';

  @override
  String get matchCardsTransliterationLabel => 'Transliteration (optional)';

  @override
  String get matchCardsTransliterationHint => 'e.g. koshka';

  @override
  String get matchCardsGlossLabel => 'Meaning (optional)';

  @override
  String get matchCardsGlossHint => 'e.g. cat';

  @override
  String get matchCardsPickImage => 'Choose image';

  @override
  String get matchCardsCancel => 'Cancel';

  @override
  String get matchCardsSessionTitle => 'Match session';

  @override
  String get matchCardsNeedTwoPairs =>
      'Add at least two pairs in Match cards to play.';

  @override
  String get matchCardsNoMatch => 'No match — try again.';

  @override
  String get matchCardsPlayAgain => 'Again';

  @override
  String matchCardsAttempts(int count) {
    return 'Attempts: $count';
  }

  @override
  String get matchCardsComplete => 'Complete';

  @override
  String get matchCardsPairsRemaining => 'pairs left';

  @override
  String get matchCardsPasteDropHint =>
      'Paste image: Ctrl+V (⌘V on Mac) outside a text field. Or drop an image file here. Captions accept any script (Chinese, Japanese, Russian, …).';

  @override
  String get matchCardsLemmaUnicodeHelper => 'Any script — stored as UTF-8.';

  @override
  String get matchCardsImageReady => 'Image ready — add caption and save.';

  @override
  String get matchCardsPasteImageInDialog => 'Paste image from clipboard';

  @override
  String get matchCardsSavePair => 'Save pair';

  @override
  String get matchCardsImageRequired =>
      'Choose, paste, or drop an image first.';

  @override
  String get matchCardsClipboardNoImage => 'Clipboard has no image.';

  @override
  String get matchCardsDeckLabel => 'Deck';

  @override
  String get matchCardsDeckMenuTooltip => 'Decks · export · import';

  @override
  String get matchCardsNewDeckMenu => 'New deck…';

  @override
  String get matchCardsRenameDeckMenu => 'Rename deck…';

  @override
  String get matchCardsDeleteDeckMenu => 'Delete deck…';

  @override
  String get matchCardsExportMenu => 'Export deck (.zip)…';

  @override
  String get matchCardsImportMenu => 'Import deck (.zip)…';

  @override
  String get matchCardsNewDeckTitle => 'New deck';

  @override
  String get matchCardsRenameDeckTitle => 'Rename deck';

  @override
  String get matchCardsDeleteDeckTitle => 'Delete deck?';

  @override
  String get matchCardsDeleteDeckBody =>
      'Pairs in this deck will be moved to another deck.';

  @override
  String get matchCardsDeleteDeckConfirm => 'Delete';

  @override
  String get matchCardsDeckNameLabel => 'Name';

  @override
  String get matchCardsExportTitle => 'Save deck export';

  @override
  String get matchCardsExportDone => 'Export saved.';

  @override
  String matchCardsExportError(String error) {
    return 'Export failed: $error';
  }

  @override
  String get matchCardsImportTitle => 'New deck for import';

  @override
  String get matchCardsImportDefaultDeckName => 'Imported';

  @override
  String get matchCardsImportNewDeckNameLabel => 'Deck name';

  @override
  String get matchCardsImportNewDeckNameHelper =>
      'Pairs from the file are added to this new deck.';

  @override
  String get matchCardsImportConfirm => 'Import';

  @override
  String matchCardsImportDone(int count) {
    return 'Imported $count pair(s).';
  }

  @override
  String matchCardsImportError(String error) {
    return 'Import failed: $error';
  }

  @override
  String get matchCardsSearchHint => 'Search lemma, transliteration, gloss…';

  @override
  String get matchCardsDuplicatesOnly => 'Duplicates only';

  @override
  String matchCardsDuplicateSummary(int groups) {
    return '$groups duplicate lemma(s) in this deck';
  }

  @override
  String get matchCardsSearchNoResults =>
      'No cards match the search or filter.';

  @override
  String get matchCardsDuplicateLemmaTooltip =>
      'Same lemma as another card in this deck';

  @override
  String get matchCardsDuplicateSaveTitle => 'Duplicate lemma';

  @override
  String get matchCardsDuplicateSaveBody =>
      'A pair with this lemma already exists in this deck.';

  @override
  String get matchCardsContinueAnyway => 'Save anyway';

  @override
  String get goGameTitle => 'Go 9×9';

  @override
  String get goGameSubtitle =>
      'Captures, no suicide, positional superko. Two passes end the game. Komi for White.';

  @override
  String get goGameModePvp => 'Two players';

  @override
  String get goGameModeBot => 'vs Bot (you are Black)';

  @override
  String get goGameNew => 'New game';

  @override
  String get goGamePass => 'Pass';

  @override
  String get goGameBlackTurn => 'Black to play';

  @override
  String get goGameWhiteTurn => 'White to play';

  @override
  String get goGameBotThinking => 'Bot thinking…';

  @override
  String get goGameIllegal => 'Illegal move';

  @override
  String get goGameOver => 'Game over';

  @override
  String goGameScoreLine(String blackPt, String whitePt, String komi) {
    return 'Black $blackPt — White $whitePt (komi +$komi)';
  }

  @override
  String get metricsRecallTitle => 'Recall metrics';

  @override
  String get metricsRecallSubtitle => 'Export CSV';

  @override
  String get realmsTitle => 'Realms';

  @override
  String get realmsSubtitle => 'Core / Active / Seek';

  @override
  String get navigationIntentTitle => 'Navigation intent';

  @override
  String get navigationIntentTooltip =>
      'Explore / review / seek / drift mode. When an object is in focus, it is saved as a frame: place, hint and ridiculous story are tied to that locus Hero.';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get backTooltip => 'Go up';

  @override
  String get searchTooltip => 'Search objects (FTS5) · Core / Active / Seek';

  @override
  String get refreshTooltip => 'Regenerate snapshot / list';

  @override
  String get emptyLevelMessage =>
      'No entries at this level.\nGo back to continue.';

  @override
  String get tooltipDoubleTapObject => 'Double-tap: content viewer (node card)';

  @override
  String get tooltipDoubleTapEnter => 'Double-tap to enter this level';

  @override
  String get tooltipRoleObject => 'Role (LB only). Double-tap: content viewer.';

  @override
  String get tooltipRoleEnter =>
      'Role (LB only; GK does not read it). Double-tap the row to enter.';

  @override
  String lastReviewPrefix(String when) {
    return '·  Last review: $when';
  }

  @override
  String duePrefix(String when) {
    return '·  Due: $when';
  }

  @override
  String get roleRealm => 'Realm';

  @override
  String get roleParcour => 'Parcour';

  @override
  String get roleObject => 'Object';

  @override
  String get languageTitle => 'Interface language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get languageSystem => 'Use device language';

  @override
  String get languageChanged => 'Language updated';

  @override
  String get edit => 'Edit';

  @override
  String get moveObjectTooltip =>
      'Move to another parcour / slot (replaces target)';

  @override
  String get moveParcourTooltip => 'Move to another parcour (replaces target)';

  @override
  String get studyTooltip => 'Study';

  @override
  String get reviewAgain => 'Again';

  @override
  String get reviewHard => 'Hard';

  @override
  String get reviewGood => 'Good';

  @override
  String get reviewEasy => 'Easy';

  @override
  String statsRecallLine(int due, int n, int total) {
    return 'Recall (entries) · due $due · new $n · total $total';
  }

  @override
  String parcourRowRecallLine(int due, int n, int total) {
    return 'Recall · due $due · new $n · total $total';
  }

  @override
  String get realmNA => 'Realm: N/A';

  @override
  String realmPercent(int percent, int good, int active) {
    return 'Realm: $percent% (good $good / active $active)';
  }

  @override
  String get dialogMoveParcourTitle => 'Move parcour';

  @override
  String get dialogMoveObjectTitle => 'Move object';

  @override
  String originLabel(String key) {
    return 'From: $key';
  }

  @override
  String get moveParcourHint =>
      'Choose the parcour that will replace the destination (same number of object children).';

  @override
  String get moveParcourBodyWarning =>
      'The destination subtree is removed and replaced by the source. The source slot returns to the empty skeleton (L1…L20).';

  @override
  String get destinationParcourLabel => 'Destination parcour';

  @override
  String get moveObjectBodyWarning =>
      'If the destination slot already has content, it is replaced. The gap in the source parcour is filled with the skeleton.';

  @override
  String get slotLabel => 'Slot (1–20)';

  @override
  String get moveObjectHint =>
      'Choose destination parcour and slot (seq). The object moves to Parent_O## for that seq.';

  @override
  String get cancel => 'Cancel';

  @override
  String get move => 'Move';

  @override
  String get snackbarNoDestParcour =>
      'No other parcour available as destination.';

  @override
  String snackbarParcourMoved(String from, String to) {
    return 'Parcour moved: $from → $to';
  }

  @override
  String get snackbarNoParcoursUnderHub => 'No parcours under PARCOUR_MAIN.';

  @override
  String snackbarObjectMoved(String obj, String dest) {
    return 'Object moved: $obj → $dest';
  }

  @override
  String snackbarNuclearError(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get breadcrumbRoot => 'R1';

  @override
  String get breadcrumbParcours => 'Parcours (R1)';

  @override
  String intentFrameSuffix(String focus) {
    return ' · frame $focus';
  }

  @override
  String intentDrawerWithFrame(String mode, String frame) {
    return '$mode · frame $frame';
  }

  @override
  String intentSnackbar(String mode, String frameSuffix) {
    return 'Intent → $mode$frameSuffix (HUD GateKeeper)';
  }

  @override
  String keySeqLine(String key, String seq) {
    return 'key=$key  ·  seq=$seq';
  }

  @override
  String parcourReviewTooltip(String rating) {
    return 'Last Parcour Review: $rating';
  }

  @override
  String get parcourReviewNoData => 'no data';

  @override
  String get timeReviewNever => 'never';

  @override
  String get timeReviewUpcoming => 'upcoming';

  @override
  String get timeReviewToday => 'today';

  @override
  String get timeReviewYesterday => 'yesterday';

  @override
  String timeReviewDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String timeReviewWeeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String timeReviewMonthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String timeReviewYearsAgo(int count) {
    return '$count years ago';
  }

  @override
  String get dueTagNew => 'new';

  @override
  String get dueTagDue => 'due';

  @override
  String dueTagInHours(int h) {
    return 'in ${h}h';
  }

  @override
  String dueTagInDays(int d) {
    return 'in ${d}d';
  }

  @override
  String get fibScheduleEmpty => 'Fib · no objects under this level';

  @override
  String fibScheduleLine(String prev, String next) {
    return 'Fib · last: $prev · next: $next';
  }

  @override
  String get fibOverdue => 'overdue';

  @override
  String fibRelPastMinutes(int m) {
    return '${m}m ago';
  }

  @override
  String fibRelPastHours(int h) {
    return '${h}h ago';
  }

  @override
  String fibRelPastDays(int d) {
    return '${d}d ago';
  }

  @override
  String fibRelFutureMinutes(int m) {
    return 'in ${m}m';
  }

  @override
  String fibRelFutureHours(int h) {
    return 'in ${h}h';
  }

  @override
  String fibRelFutureDays(int d) {
    return 'in ${d}d';
  }

  @override
  String get parcourFibDueDash => 'due —';

  @override
  String get parcourFibDueOverdue => 'due overdue';

  @override
  String parcourFibDueIn(String when) {
    return 'due $when';
  }

  @override
  String get parcourFibScoreDash => 'score —';

  @override
  String parcourFibScoreValue(String value) {
    return 'score $value';
  }

  @override
  String parcourFibFullLine(int fibIndex, String due, String score) {
    return 'Parcour · fib $fibIndex · $due · $score';
  }

  @override
  String get locusEditorTitle => 'Locus editor';

  @override
  String get locusEditorAddBlockTooltip => 'Add block';

  @override
  String get locusEditorBlockParagraph => 'Paragraph';

  @override
  String get locusEditorBlockLink => 'Link';

  @override
  String get locusEditorBlockImage => 'Image';

  @override
  String get locusEditorBlockCard => 'Card';

  @override
  String get locusEditorCardWordLabel => 'Word / lemma';

  @override
  String get locusEditorCardImageLabel =>
      'Illustration (filename under assets)';

  @override
  String get locusEditorCardPhoneticLabel =>
      'Phonetic / notes (file, e.g. ipa.txt)';

  @override
  String get locusEditorCardAudioLabel =>
      'Pronunciation audio (ogg / mp3 / wav)';

  @override
  String get locusEditorCardRelatedLabel => 'Related entry keys';

  @override
  String get locusEditorCardRelatedHint =>
      'Comma or space separated (must exist in this realm)';

  @override
  String get locusEditorEmptyBlocksHint =>
      'No blocks yet. Add paragraph, link, image, or vocabulary card—or paste or drop an image.';

  @override
  String locusEditorUnknownRelatedKey(String key) {
    return 'Related key not found in this realm: $key';
  }

  @override
  String get locusEditorSpatialTurnTooltip =>
      'Spatial turn (path to next frame in GateKeeper)';

  @override
  String get locusEditorSpatialStraight => 'Straight';

  @override
  String get locusEditorSpatialLeft => 'Left';

  @override
  String get locusEditorSpatialRight => 'Right';

  @override
  String get locusEditorMenuTooltip => 'Locus settings, role, help';

  @override
  String get locusEditorSave => 'Save';

  @override
  String get locusEditorPasteHint =>
      'Paste: Ctrl+V. Image roles: Viewer / Collage / Hero. Quick hero: focus image + Ctrl/Cmd+H. More: menu ☰';

  @override
  String get locusEditorSaved => 'Saved';

  @override
  String locusEditorSubtitleLine(String role, String turn) {
    return '$role · $turn';
  }

  @override
  String get sectionHelp => 'HELP';

  @override
  String get helpGuideTitle => 'How Alexandria works';

  @override
  String get helpGuideClose => 'Close';

  @override
  String get helpGuideGkHint => 'Press F1 in GateKeeper for this guide.';

  @override
  String get helpGuideOverviewTitle => 'Big picture';

  @override
  String get helpGuideOverviewBody =>
      'Alexandria has two apps that share the same data folder. Library Build (LB) is where you edit the realm tree, locus content, images, and reviews. GateKeeper (GK) is the 3D corridor: you walk between frames and open the viewer. Both read the same SQLite database and assets; a small bridge folder tells GK which level and frame are active.';

  @override
  String get helpGuideRolesTitle => 'Realms, parcours, and objects';

  @override
  String get helpGuideRolesBody =>
      'The tree starts at ROOT, then realms (e.g. R1), the parcour hub (PARCOUR_MAIN), numbered parcours (P1…P20), and object slots under each parcour. Each row has a cognitive role: Realm (container), Parcour (a corridor of frames), or Object (a leaf you open for full content). In LB you assign roles when you create or edit entries. In GK, parcour levels show many frames along a path; object levels focus on one frame.';

  @override
  String get helpGuideContentTitle => 'Hero, collage, and body';

  @override
  String get helpGuideContentBody =>
      'In the locus editor, images can be Viewer-only, Collage (panels on the GK wall between frames), or Hero (the picture on the 3D frame). Text blocks can carry place, hint, or ridiculous story for study. Saving updates files under assets/<key>/ and refreshes snapshots so GK can rebuild the corridor.';

  @override
  String get helpGuideCardsTitle => 'Vocabulary cards';

  @override
  String get helpGuideCardsBody =>
      'Add a Card block for language-style entries: a large word, an illustration file under assets/<key>/, optional phonetic notes (.txt), optional pronunciation audio (ogg/mp3/wav), and related_to with other entry keys in this realm. In GateKeeper, related keys only change focus (same corridor); Back returns to the previous focus.';

  @override
  String get helpGuideLbTitle => 'Library Build — what you can do';

  @override
  String get helpGuideLbBody =>
      'Browse with the app bar and drawer: open any level, edit a locus (double-tap or edit), search objects, refresh snapshots. The drawer offers node PDF, parcour PDF, import from data-transfer, PAO tools, recall metrics export, language, realm folders, and navigation intent (explore / review / seek / drift — optionally tied to a focus locus for Hero-linked fields). The list shows recall due dates, review history, parcour review dots, and Fib schedule lines where applicable.';

  @override
  String get helpGuideGkTitle => 'GateKeeper — 3D realm';

  @override
  String get helpGuideGkBody =>
      'Move with WASD, look with the mouse (Esc frees or recaptures the cursor). Click a frame to set focus for the viewer; use the on-screen viewer to enter a child level or go back to the parent. The top line shows navigation intent from LB. The corridor layout follows spatial turns you set per frame in LB (straight, left, right).';

  @override
  String get helpGuideMetricsTitle => 'Metrics and reviews';

  @override
  String get helpGuideMetricsBody =>
      'LB stores per-entry recall fields (next review, strength, counts) and parcour review ratings. Use the metrics page to export CSV. In the list, badges and tooltips summarize due state and last parcour review when you are under a parcour.';

  @override
  String get helpGuideBridgeTitle => 'Bridge and sync';

  @override
  String get helpGuideBridgeBody =>
      'Files under data/…/bridge/ carry context_key (which snapshot level GK loads), focus_key (which locus the viewer highlights), navigation_intent.txt, and optional refresh flags. After edits in LB, use Refresh so snapshots and manifests stay aligned; GK picks up changes when those files update.';

  @override
  String get usageBandAll => 'All';

  @override
  String get usageBandCore => 'Core';

  @override
  String get usageBandActive => 'Active';

  @override
  String get usageBandSeek => 'Seek';

  @override
  String get usageBandSubtitleCore => 'Core usage — highest engagement';

  @override
  String get usageBandSubtitleActive => 'Recurrent use';

  @override
  String get usageBandSubtitleSeek => 'Exploration / long tail';

  @override
  String get realmShelfPopupCore => 'Core — core priority';

  @override
  String get realmShelfPopupActive => 'Active — regular use';

  @override
  String get realmShelfPopupSeek => 'Seek — long tail';

  @override
  String get realmAdminFabCreate => 'Create new realm';

  @override
  String get realmAdminTabFolders => 'Folders';

  @override
  String get realmAdminTabShelves => 'Shelves';

  @override
  String get realmAdminTooltipEmptySubfolder =>
      'Create empty folder (organization only, no realm)';

  @override
  String get realmAdminTooltipRefresh => 'Refresh list';

  @override
  String get realmAdminTooltipOpenExplorer =>
      'Open this folder in file explorer';

  @override
  String get realmAdminTooltipCreateSeed =>
      'Create realm seed from active realm (data/realm_seed/)';

  @override
  String get realmAdminTooltipNuclear => 'Delete all data (irreversible)';

  @override
  String get realmAdminTooltipOpenRealmFolder =>
      'Open realm folder in explorer';

  @override
  String get realmAdminTooltipMoveShelf => 'Change shelf assignment';

  @override
  String get realmAdminTooltipEnterSubfolders => 'Enter subfolders';

  @override
  String get realmAdminTooltipShelfMenu => 'Shelf';

  @override
  String get realmAdminTooltipMoveRealm => 'Move or rename realm on disk';

  @override
  String get realmAdminMoveRealmMenu => 'Move to path…';

  @override
  String get realmAdminMoveRealmTitle => 'Move realm';

  @override
  String get realmAdminMoveRealmBody =>
      'New location under data/realms/. The destination must not exist. The database is closed briefly.';

  @override
  String get realmAdminMoveRealmTargetLabel => 'New path (e.g. Lab/my_course)';

  @override
  String realmAdminMoveRealmOk(String path) {
    return 'Moved to $path';
  }

  @override
  String get realmAdminMoveRealmFailed =>
      'Could not move (folder exists or files in use).';

  @override
  String get realmAdminMoveRealmButton => 'Move';

  @override
  String get realmAdminShelvesIntro =>
      'Only one active realm at a time (GateKeeper reads data/active_realm.txt). Core / Active / Seek are priority shelves (not physical folders).';

  @override
  String realmAdminActiveLine(String id) {
    return 'Active: $id';
  }

  @override
  String get realmAdminTierHeaderCore => 'Most important / in use';

  @override
  String get realmAdminTierHeaderActive => 'Regular work realms';

  @override
  String get realmAdminTierHeaderSeek => 'Long tail and experiments';

  @override
  String get realmAdminEmptyTier => 'Empty';

  @override
  String get realmAdminFolderIntro =>
      'Lists what exists on disk under data/realms/ from the resolved repo root (not invented). Realm = folder with alexandria.db. Moving many folders: prefer apps closed if the DB is in use.';

  @override
  String get realmAdminRepoRootCaption =>
      'Repo root (ALEXANDRIA_ROOT env, or search from the .exe, or C:\\\\Alexandria if it has data/realms):';

  @override
  String get realmAdminRealmsFolderCaption =>
      'Realms folder (must match what the explorer opens):';

  @override
  String get realmAdminFolderEmpty => 'Empty folder.';

  @override
  String get realmAdminLeafFolderWithoutDb =>
      'Folder without alexandria.db or subfolders';

  @override
  String get realmAdminRootGroupLabel => 'Root (no subfolder)';

  @override
  String get realmAdminDataRealmsChip => 'data/realms';

  @override
  String realmAdminShelfLabel(String tier) {
    return 'Shelf: $tier';
  }

  @override
  String get objectSearchUsageCaption =>
      'Usage views: Core · Active · Seek (same loci; does not change structure).';

  @override
  String realmAdminExplorerMissingFolder(String root, String path) {
    return 'That folder does not exist on disk.\nResolved root: $root\nAttempted path:\n$path';
  }

  @override
  String realmAdminExplorerError(String error, String path) {
    return 'Explorer: $error\n$path';
  }

  @override
  String realmAdminFolderMissing(String path) {
    return 'Missing folder:\n$path';
  }

  @override
  String realmAdminOpenFailed(String error) {
    return 'Could not open: $error';
  }

  @override
  String get realmAdminEmptyFolderDialogTitle => 'Empty folder';

  @override
  String realmAdminEmptyFolderBody(String path) {
    return 'Organization only (no alexandria.db). Created under:\n$path';
  }

  @override
  String get realmAdminEmptyFolderNameLabel => 'Folder name';

  @override
  String get realmAdminEmptyFolderNameHint => 'e.g. Lab or Clients_2026';

  @override
  String get realmAdminEmptyFolderNameHelper => 'One segment; no /';

  @override
  String get realmAdminSnackbarSingleSegment => 'Use a single name without /';

  @override
  String get realmAdminSnackbarSubfolderCreateFailed =>
      'Could not create (already a realm with DB there, or invalid name?).';

  @override
  String get realmAdminSnackbarFolderCreated => 'Folder created';

  @override
  String get realmDialogNewTitle => 'New realm';

  @override
  String get realmDialogFolderOptionalLabel => 'Optional folder';

  @override
  String get realmDialogFolderHint => 'e.g. Lab or Clients/2026';

  @override
  String get realmDialogFolderHelper =>
      'Under data/realms/; empty = root. Folders tab fills from current view.';

  @override
  String get realmDialogIdLabel => 'Realm id';

  @override
  String get realmDialogIdHint => 'e.g. my_realm';

  @override
  String get realmDialogIdHelper => 'Single name; no /';

  @override
  String get realmDialogTemplateCopyTitle => 'Copy from template';

  @override
  String get realmDialogTemplateCopySubtitle =>
      'Duplicates DB, bridge, snapshot, assets… from another realm.';

  @override
  String get realmDialogEmptyTitle => 'Empty (same architecture)';

  @override
  String get realmDialogEmptySubtitle =>
      'Same fixed tree (20 parcours + 400 objects under PARCOUR_MAIN), but no locus text, no recall/review, empty assets.';

  @override
  String get realmDialogTemplateLabel => 'Template';

  @override
  String get realmDialogCreate => 'Create';

  @override
  String get realmDialogIdInvalidChars => 'Realm id cannot contain / or \\.';

  @override
  String get realmSnackbarCreateEmptyFailed =>
      'Could not create empty (duplicate path or write error?).';

  @override
  String get realmSnackbarDuplicateFailed =>
      'Could not copy (missing template, duplicate path?).';

  @override
  String realmSnackbarActiveRealm(String id) {
    return 'Active realm: $id';
  }

  @override
  String get realmAdminNuclearTitle => 'Delete all data';

  @override
  String get realmAdminNuclearDialogIntro =>
      'All realms, assets, bridge, snapshots, manifests, PAO under data/pao, and realm_shelf.json will be deleted.\n\nOnly a new base will remain at:\ndata/realms/default/alexandria.db\n\nThe realm seed snapshot will also be written to:\ndata/realm_seed/alexandria.db\n\nActive realm: default.\n\nClose GateKeeper if it is open (file locking).\n\nTo confirm, type exactly:';

  @override
  String get realmAdminConfirmLabel => 'Confirmation';

  @override
  String get realmAdminPhraseMismatch => 'The phrase does not match exactly.';

  @override
  String get realmAdminNuclearButton => 'Delete all';

  @override
  String get realmAdminNuclearSuccessSnackbar =>
      'Data cleared: default/alexandria.db + data/realm_seed/alexandria.db. Run Library build or reopen the app to regenerate snapshot/viewer.';

  @override
  String get realmSeedDialogTitle => 'Create realm seed';

  @override
  String realmSeedDialogBody(String realm) {
    return 'The active realm ($realm) will be sanitized, Library build will run, and the database will be copied to:\ndata/realm_seed/alexandria.db\n\nClose GateKeeper if it is open.';
  }

  @override
  String get realmSeedConfirm => 'Create';

  @override
  String get realmSeedSavedSnackbar =>
      'Realm seed saved: data/realm_seed/alexandria.db';

  @override
  String get realmSeedErrorPrefix => 'Realm seed:';

  @override
  String get objectSearchTitle => 'Search objects (FTS5)';

  @override
  String get objectSearchHint => 'Locus title or body text…';

  @override
  String get objectSearchCardReaderTooltip => 'Node card reader (full info)';

  @override
  String get objectSearchNoObjects => 'No objects in the database.';

  @override
  String get objectSearchNoMatches => 'No matches.';
}
