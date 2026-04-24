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
  String get librarySurfaceRealmTree => 'Realm tree';

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
  String get dataTransferAppBarTitle => 'Data transfer → LibraryBuild';

  @override
  String get dataTransferRefreshTooltip => 'Refresh files and status';

  @override
  String dataTransferServerRepoLabel(String path) {
    return 'Server in repo: $path';
  }

  @override
  String get dataTransferStartServer => 'Start server (node)';

  @override
  String get dataTransferStopLbProcess => 'Stop LB process';

  @override
  String get dataTransferOpenWebUi => 'Open web UI (:4020)';

  @override
  String dataTransferServerReachable(int port) {
    return 'Server reachable at http://127.0.0.1:$port';
  }

  @override
  String get dataTransferHealthNoResponse =>
      'No response on /health (start node or use local import only)';

  @override
  String get dataTransferImportHeading => 'Import file into a locus';

  @override
  String dataTransferImportHint(String folder) {
    return 'Source: $folder · If the content starts with [ it is interpreted as block JSON; otherwise a single paragraph is created. “Append” mode concatenates blocks to the existing body.';
  }

  @override
  String get dataTransferFolderLabelOut => 'out/';

  @override
  String get dataTransferFolderLabelIncoming => 'handoff/incoming/';

  @override
  String get dataTransferNoObjects => 'No object entries in the database.';

  @override
  String get dataTransferTargetLocus => 'Target locus (object)';

  @override
  String dataTransferLocusDropdownLine(
    String key,
    String title,
    String parentKey,
  ) {
    return '$key — $title (parent: $parentKey)';
  }

  @override
  String get dataTransferFileFolder => 'File folder';

  @override
  String get dataTransferSegmentOut => 'out/';

  @override
  String get dataTransferSegmentIncoming => 'incoming/';

  @override
  String dataTransferFileCounts(int outCount, int incomingCount) {
    return 'out/: $outCount · incoming/: $incomingCount';
  }

  @override
  String get dataTransferOutFolderEmpty =>
      'Folder out/ is empty. Use the web UI, switch to incoming/, or copy files into data-transfer/out/.';

  @override
  String get dataTransferIncomingFolderEmpty =>
      'Folder handoff/incoming/ is empty. Copy files here or use out/.';

  @override
  String dataTransferFilePickerLabel(String folder) {
    return 'File ($folder)';
  }

  @override
  String get dataTransferImportMode => 'Import mode';

  @override
  String get dataTransferReplaceBody => 'Replace body';

  @override
  String get dataTransferAppendBlocks => 'Append at end';

  @override
  String get dataTransferImportRunBuild =>
      'Import to locus and runLibraryBuild';

  @override
  String dataTransferScriptMissing(String path) {
    return 'Missing file: $path';
  }

  @override
  String get dataTransferServerAlreadyRunning =>
      'A server is already listening on :4020 (external or another process)';

  @override
  String get dataTransferNodeStartedNoHealth =>
      'Node process started but /health does not respond. Is Node on PATH?';

  @override
  String dataTransferNodeStartFailed(String error) {
    return 'Could not start node: $error';
  }

  @override
  String dataTransferOpenUrlFailed(String url) {
    return 'Could not open $url';
  }

  @override
  String get dataTransferPickFileAndLocus => 'Choose a file and target locus.';

  @override
  String dataTransferImportDoneReplace(String key, String file) {
    return 'Replaced · $key ($file)';
  }

  @override
  String dataTransferImportDoneAppend(String key, String file) {
    return 'Appended · $key ($file)';
  }

  @override
  String dataTransferErrorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String dataTransferHttpStatus(int code) {
    return 'HTTP $code';
  }

  @override
  String get paoEditorTitle => 'PAO';

  @override
  String get paoEditorSubtitle =>
      'Phonetic keys · pegs 0–9 · 00–99 · 000–999 · JSON';

  @override
  String get paoTabPhonetic => 'Keys';

  @override
  String get paoTabDigit => '0–9';

  @override
  String get paoTabPair => '00–99';

  @override
  String get paoTabTriple => '000–999';

  @override
  String get paoPhoneticBoardHint =>
      'Assign consonants or sounds to each digit (your Major-system variant). Vowels are fillers—use the optional column for vowel notes only.';

  @override
  String get paoPhoneticConsonantsLabel => 'Consonants / sounds';

  @override
  String get paoPhoneticVowelNoteLabel => 'Vowel notes (optional)';

  @override
  String get paoPhoneticSaveRow => 'Save';

  @override
  String get paoPhoneticSaved => 'Row saved';

  @override
  String get paoSearchHint =>
      'Search by code, person, action, object, or image path';

  @override
  String paoSubtitleTier(int filled, int total, String realm) {
    return '$filled / $total with text or image · realm $realm';
  }

  @override
  String get paoMenuImportJsonAuto =>
      'Import JSON (auto: full v2 or legacy 00–99)';

  @override
  String get paoMenuExportJsonV2 => 'Export JSON (full v2)…';

  @override
  String get paoMenuExportPairCsv => 'Export CSV (00–99 only)…';

  @override
  String get paoMenuTemplateV2 => 'Write empty template v2 in repo';

  @override
  String get paoSnackbarImportOk => 'PAO data imported';

  @override
  String paoSnackbarTemplateV2(String path) {
    return 'Template v2 written: $path';
  }

  @override
  String get paoEditCodeImageHintPair =>
      'Code image (00–99): drag here or Ctrl/Cmd+V with focus outside text fields.';

  @override
  String get paoEditCodeImageHintDigit =>
      'Code image (single digit): drag here or Ctrl/Cmd+V with focus outside text fields.';

  @override
  String get paoEditCodeImageHintTriple =>
      'Code image (000–999): drag here or Ctrl/Cmd+V with focus outside text fields.';

  @override
  String get paoEditPreviewExerciseTooltip => 'Preview in practice';

  @override
  String get paoEditPreviewExerciseTitle => 'Practice preview';

  @override
  String get paoEditPreviewExerciseIntro =>
      'How this peg can look in individual practice (all drill stimuli and the answers panel).';

  @override
  String get paoPracticeTitle => 'PAO · individual practice';

  @override
  String get paoPracticeSubtitle =>
      'Mental recall · show answers · pass / fail';

  @override
  String get paoDrillInstruction =>
      'Recall silently; do not type. Then show the answers and mark pass or fail.';

  @override
  String get paoDrillModeCodeTitle => 'Code → person, action, object (mental)';

  @override
  String get paoDrillModePersonTitle =>
      'Person → code, action, object (mental)';

  @override
  String get paoDrillModeObjectTitle =>
      'Object → code, person, action (mental)';

  @override
  String paoDrillPoolInfo(int count, String realmId) {
    return '$count codes · realm $realmId';
  }

  @override
  String get paoDrillShowAnswers => 'Show answers';

  @override
  String get paoDrillAnswersHeading => 'Answers';

  @override
  String get paoFieldCode => 'Code';

  @override
  String get paoFieldPerson => 'Person';

  @override
  String get paoFieldAction => 'Action';

  @override
  String get paoFieldObject => 'Object';

  @override
  String get paoDrillSuccess => 'Pass';

  @override
  String get paoDrillFail => 'Fail';

  @override
  String get paoDrillNextUnmarked => 'Next (unmarked)';

  @override
  String get paoDrillEmptyTitle => 'No codes ready to practice.';

  @override
  String get paoDrillEmptyHint =>
      'Fill in person, action, and object for at least one code in PAO (digit, pair 00–99, or triple 000–999).';

  @override
  String get paoDrillStimulusCode => 'Code';

  @override
  String get paoDrillStimulusPerson => 'Person';

  @override
  String get paoDrillStimulusObject => 'Object';

  @override
  String get paoDrillStimulusRecallNumber => 'Recall the number';

  @override
  String get paoDrillStimulusRecallMnemonic => 'Recall the image (mnemonic)';

  @override
  String get paoDrillPoolAllTiersHint =>
      'Pool: random codes from 0–9, 00–99, and 000–999 (complete rows only). Each code round shows either the number or the code image — not both.';

  @override
  String get paoListEmptyRow => '(empty)';

  @override
  String paoListDetailLine(String person, String action, String object) {
    return 'P: $person  |  A: $action  |  O: $object';
  }

  @override
  String get paoEditChooseImage => 'Choose image';

  @override
  String get paoEditRemoveImage => 'Remove';

  @override
  String get paoEditNoImageOptional => 'No image (optional)';

  @override
  String get paoEditImageLoadError => 'Could not load image';

  @override
  String get paoEditPersonImage1 => 'Character image 1';

  @override
  String get paoEditPersonImage2 => 'Character image 2';

  @override
  String get paoEditObjectImage1 => 'Object image 1';

  @override
  String get paoEditObjectImage2 => 'Object image 2';

  @override
  String get paoEditPasteImageTooltip => 'Paste image (Ctrl+V in this slot)';

  @override
  String get paoTemplateExistsTitle => 'Template already exists';

  @override
  String paoTemplateExistsBody(String path) {
    return 'Overwrite?\n$path';
  }

  @override
  String get paoOverwrite => 'Overwrite';

  @override
  String paoTemplateWritten0099(String path) {
    return 'Template written: $path';
  }

  @override
  String get paoExportJsonDialogTitle => 'Export PAO JSON v2';

  @override
  String get paoExportCsvDialogTitle => 'Export PAO CSV';

  @override
  String paoSavedToPath(String path) {
    return 'Saved: $path';
  }

  @override
  String paoErrorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get paoJsonV2CopiedClipboard => 'PAO v2 JSON copied to clipboard';

  @override
  String get paoMenuTemplate0099 => 'Template 00–99 (repo)';

  @override
  String get paoMenuCopyJsonV2Clipboard => 'Copy JSON v2 to clipboard';

  @override
  String get paoSnackbarPasteImageUseTabs =>
      'Paste image: open tab 0–9, 00–99, or 000–999 and tap a row.';

  @override
  String get paoSnackbarTapRowFirst => 'Tap a row first to choose the code.';

  @override
  String get paoSnackbarCodeNotInTab => 'Code not found in this tab.';

  @override
  String get paoSnackbarClipboardNoImage => 'Clipboard: no image';

  @override
  String get paoSnackbarCouldNotSaveImage => 'Could not save image';

  @override
  String get paoSnackbarCouldNotCopyImage => 'Could not copy image';

  @override
  String paoSnackbarCodeImageUpdated(String code) {
    return 'Code $code image updated';
  }

  @override
  String get paoSnackbarDropImageUseTabs =>
      'Drop image on tab 0–9, 00–99, or 000–999 (after tapping a row).';

  @override
  String paoEditDialogTitle(String code) {
    return 'PAO $code';
  }

  @override
  String get paoEditDeletePegButton => 'Delete peg';

  @override
  String get paoEditDeletePegConfirmTitle => 'Delete this peg?';

  @override
  String get paoEditDeletePegConfirmBody =>
      'This removes all text and images for this code and deletes the image files from the realm assets folder.';

  @override
  String get paoEditDeletePegSuccess => 'Peg cleared';

  @override
  String get pokerMemoryTitle => 'Poker · number map';

  @override
  String get pokerMemoryDrawerSubtitle =>
      'Number ↔ card · 13 numbers per suit · quick drill';

  @override
  String get frameRecallQuizDrawerSubtitle =>
      '4-image crop quiz · same parcour';

  @override
  String get frameRecallQuizTitle => 'Frame recall (prototype)';

  @override
  String get frameRecallQuizIntro =>
      'Each locus needs one image block with role «Recall crop» (detail of the hero). Hero is not shown here — only your place hint and four crops. Pick the crop that belongs to the locus described.';

  @override
  String get frameRecallSelectParcour => 'Parcour';

  @override
  String frameRecallFramesWithCrop(int count) {
    return '$count frames with recall crop';
  }

  @override
  String get frameRecallNeedFour =>
      'Need at least 4 loci in this parcour with a recall crop image. Edit each locus and add an image with role «Recall crop».';

  @override
  String get frameRecallNoParcours =>
      'No parcours under the hub. Create parcours first.';

  @override
  String get frameRecallQuestion => 'Place / hint';

  @override
  String get frameRecallLocusLabel => 'Locus';

  @override
  String get frameRecallPickCrop => 'Which crop matches?';

  @override
  String get frameRecallCorrect => 'Correct.';

  @override
  String get frameRecallWrong => 'Wrong — green border shows the right crop.';

  @override
  String get frameRecallNext => 'Next question';

  @override
  String frameRecallMissingFile(String name) {
    return 'Missing file: $name';
  }

  @override
  String get pokerMemoryTabMap => 'Map';

  @override
  String get pokerMemoryTabRanges => 'Ranges';

  @override
  String get pokerMemoryTabDrill => 'Quick drill';

  @override
  String get pokerMemoryMapIntro =>
      'Each number maps to one card (A, 2–10, J, Q, K within the suit block). Edit ranges on the Ranges tab.';

  @override
  String get pokerMemoryMapEmpty =>
      'No mappings. Check ranges (each suit must span exactly 13 numbers, no overlaps).';

  @override
  String get pokerMemoryRangesIntro =>
      'Assign a contiguous block of 13 numbers per suit. Default: spades 01–13, hearts 41–53, diamonds 61–73, clubs 81–93.';

  @override
  String get pokerMemoryRangeFrom => 'From';

  @override
  String get pokerMemoryRangeTo => 'To';

  @override
  String get pokerMemoryRangesSave => 'Save ranges';

  @override
  String get pokerMemoryRangesSaved => 'Ranges saved';

  @override
  String get pokerMemoryRangesInvalidNumber =>
      'Enter valid integers for from / to.';

  @override
  String get pokerMemoryRangesHint =>
      'Ranks are fixed in order: A, 2, 3, …, 10, J, Q, K within each block. Gaps between blocks are allowed.';

  @override
  String get pokerMemorySuitSpades => 'Spades';

  @override
  String get pokerMemorySuitHearts => 'Hearts';

  @override
  String get pokerMemorySuitDiamonds => 'Diamonds';

  @override
  String get pokerMemorySuitClubs => 'Clubs';

  @override
  String get pokerMemoryDrillInstruction =>
      'Recall the other side mentally, then reveal and mark pass or fail.';

  @override
  String get pokerMemoryDrillModeNumberToCard => 'Number → card';

  @override
  String get pokerMemoryDrillModeCardToNumber => 'Card → number';

  @override
  String pokerMemoryDrillPoolInfo(int count, String realmId) {
    return '$count cards · realm $realmId';
  }

  @override
  String get pokerMemoryStimulusNumber => 'Number';

  @override
  String get pokerMemoryStimulusCard => 'Card';

  @override
  String get pokerMemoryShowAnswer => 'Show answer';

  @override
  String get pokerMemoryAnswerHeading => 'Answer';

  @override
  String get pokerMemoryAnswerNumber => 'Number';

  @override
  String get pokerMemoryAnswerCard => 'Card';

  @override
  String get pokerMemoryPass => 'Pass';

  @override
  String get pokerMemoryFail => 'Fail';

  @override
  String get pokerMemoryNext => 'Next';

  @override
  String get pokerMemoryDrillEmpty => 'Nothing to drill. Fix ranges first.';

  @override
  String get matchCardsTitle => 'Match cards';

  @override
  String get matchCardsSubtitle =>
      'Image ↔ caption pairs · random session (LB only)';

  @override
  String get matchCardsOrmHint =>
      'Each pair: lemma (native script), optional transliteration, optional meaning (gloss), and image. route_key is for future “along a route”. Practice sessions pick cards by Fibonacci step (shorter interval first), then by higher fail counts.';

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
  String get matchCardsSessionMenuTooltip => 'Session';

  @override
  String get matchCardsSessionNewRound => 'New round';

  @override
  String get matchCardsSessionChangeDeck => 'Change deck…';

  @override
  String get matchCardsSessionStats => 'Weakest cards…';

  @override
  String get matchCardsSessionStatsTitle => 'Deck stats';

  @override
  String get matchCardsSessionStatsSubtitle =>
      'Rounds prioritize low Fibonacci step (needs practice), then higher fail counts. Each wrong image–text match increments fails for both cards.';

  @override
  String get matchCardsSessionStatsEmpty =>
      'No review data yet — finish a few rounds to see counts.';

  @override
  String matchCardsSessionStatsFailPass(int fails, int passes) {
    return '$fails fails · $passes OK';
  }

  @override
  String matchCardsSessionStatsFib(int n) {
    return 'Step $n';
  }

  @override
  String matchCardsDeckOverviewKpis(
    int pairCount,
    int dueCount,
    String matchRate,
  ) {
    return '$pairCount pairs · $dueCount due · match rate $matchRate';
  }

  @override
  String get matchCardsDeckOverviewFibBars =>
      'Pairs per Fibonacci step (bar height)';

  @override
  String get matchCardsDeckStatsMenu => 'Deck statistics…';

  @override
  String get matchCardsSessionPickDeckTitle => 'Choose deck';

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
  String goGameScoreSummary(
    String blackPt,
    String whiteBoardPt,
    String komi,
    String whiteTotal,
    String verdict,
  ) {
    return 'Black $blackPt pts — White $whiteBoardPt on board + $komi komi = $whiteTotal pts. $verdict';
  }

  @override
  String get goGameVerdictDraw => 'Draw.';

  @override
  String goGameVerdictBlackWins(String margin) {
    return 'Black wins by $margin pts.';
  }

  @override
  String goGameVerdictWhiteWins(String margin) {
    return 'White wins by $margin pts.';
  }

  @override
  String goGameStoneTotals(int blackStones, int whiteStones) {
    return 'Stones on grid: Black $blackStones · White $whiteStones';
  }

  @override
  String get goStudyTabFree => 'Free play';

  @override
  String get goStudyTabProblems => 'Problems';

  @override
  String get goStudyLibraryTooltip => 'Problem library & progress';

  @override
  String get goStudyLibraryTitle => 'Go problems';

  @override
  String goStudyLibraryLine(int solved, int mastered) {
    return '$solved solved · $mastered studied (3+ hits)';
  }

  @override
  String get goStudyMasteredLabel => 'Studied';

  @override
  String get goStudySolvedLabel => 'Solved once';

  @override
  String goStudyAttemptsLabel(int n) {
    return '$n attempts';
  }

  @override
  String get goStudyProblemWrong => 'Not the intended move — try again.';

  @override
  String get goStudyProblemCorrect => 'Correct!';

  @override
  String get goStudyHint => 'Hint';

  @override
  String get goStudyShowLegal => 'Legal moves';

  @override
  String goStudyProblemIndex(int current, int total) {
    return 'Problem $current / $total';
  }

  @override
  String get goStudyNextProblem => 'Next';

  @override
  String get goStudyPrevProblem => 'Previous';

  @override
  String get goStudyResetProblem => 'Reset position';

  @override
  String get goStudyPassDisabled => 'Pass is disabled in this problem mode.';

  @override
  String get goStudyBotDisabled => 'Bot is off during problems.';

  @override
  String get goProblemCapTitle => 'Capture (atari)';

  @override
  String get goProblemCapHint => 'Remove the last liberty of the white stone.';

  @override
  String get goProblemConnectTitle => 'Connect (side)';

  @override
  String get goProblemConnectHint => 'Play between the two black stones.';

  @override
  String get goProblemBridgeTitle => 'Connect (up/down)';

  @override
  String get goProblemBridgeHint =>
      'Join the two black stones on the same file.';

  @override
  String get metricsRecallTitle => 'Recall metrics';

  @override
  String get metricsRecallSubtitle => 'Export CSV';

  @override
  String get realmsTitle => 'Realms';

  @override
  String get realmsSubtitle => 'Core / Active / Seek';

  @override
  String get navigationIntentTitle => 'Study navigation';

  @override
  String get navigationIntentTooltip =>
      'Tap to cycle modes. With a focused object, line 2 in the bridge file is the Hero frame key for place / hint / story.';

  @override
  String get memoryAthleteSwitchTitle =>
      'Parcour pass: 100% (athlete) vs 80% (standard)';

  @override
  String get memoryAthleteSwitchSubtitleOn =>
      'Switch on — full pass required (100% of session score).';

  @override
  String get memoryAthleteSwitchSubtitleOff =>
      'Switch off — pass at 80% of session score (standard).';

  @override
  String get studyNavigationTitle => 'Study navigation';

  @override
  String get studyNavigationTooltip =>
      'Tap to cycle modes. Subtitle: mode and Hero frame key.';

  @override
  String studyNavigationDetailModeOnly(String mode) {
    return 'Mode: $mode';
  }

  @override
  String studyNavigationDetailWithFrame(String mode, String frame) {
    return 'Mode: $mode\nFrame (Hero locus): $frame';
  }

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
    return 'Mode → $mode$frameSuffix (3D viewer HUD)';
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
  String get parcourFibDueReady => 'due';

  @override
  String parcourFibDueInDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

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
  String get locusEditorSaved => 'Saved';

  @override
  String locusEditorSubtitleLine(String role, String turn) {
    return '$role · $turn';
  }

  @override
  String get locusEditorHelpMenuLabel => 'Locus editor help';

  @override
  String get locusEditorHelpMenuSubtitle =>
      'What this screen does and how it syncs with GateKeeper';

  @override
  String get locusEditorHelpDialogTitle => 'Using the locus editor';

  @override
  String get locusEditorDeleteMenuLabel => 'Delete this locus';

  @override
  String get placeRecallDrawerTitle => 'Place recall';

  @override
  String get placeRecallDrawerSubtitle =>
      'Enables the crop gate in the 3D viewer (or use study mode place_recall). Needs recall_crop assets; three distractors come from siblings in the parcour when possible.';

  @override
  String get locusEditorDeleteMenuSubtitle =>
      'Removes this entry and descendants from the database and realm files—not the whole database file.';

  @override
  String get locusEditorDeleteConfirmTitle => 'Delete locus permanently';

  @override
  String locusEditorDeleteConfirmDescription(String realmPath) {
    return 'Removes this entry and all descendants from the realm database ($realmPath), deletes matching rows in review/parcour tables, removes assets/snapshot/viewer/manifest files for those keys, then rebuilds snapshots.';
  }

  @override
  String locusEditorDeleteConfirmDeletingLabel(String key) {
    return 'Deleting: $key';
  }

  @override
  String get locusEditorDeleteConfirmTypeInstruction =>
      'This will delete the locus named above. To confirm, type the phrase below in the box—not your database key. It must match exactly, including spaces and capitals:';

  @override
  String get locusEditorDeleteConfirmPhraseExact => 'Delete Node';

  @override
  String get locusEditorDeleteConfirmFieldHint => 'Delete Node';

  @override
  String get locusEditorDeleteConfirmButton => 'Delete';

  @override
  String get locusEditorHelpDialogBody =>
      'This screen edits one entry in the realm: blocks of text, links, images, and vocabulary cards.\n\nCognitive role — Realm (container), Parcour (a corridor of frames), or Object (what you read in the GateKeeper viewer). Children under a parcour become ordered frames along the 3D path.\n\nBlocks — Paragraphs can be plain text or study kinds: Place, Hint, Ridiculous story. Images pick a role: Content (viewer only), Collage (panels on the GateKeeper wall between frames), or Hero (the picture on the 3D frame). Quick Hero: focus an image block and press Ctrl/Cmd+H.\n\nCards — Word or lemma, illustration and audio files under assets for this key, optional phonetic notes file, and related entry keys that already exist in this realm.\n\nSpatial turn — For entries that are direct children of a parcour, set how the corridor continues toward the next frame (straight, left, right).\n\nPlace recall — On objects, turn on place recall when you want the GateKeeper place drill. Add an image with role Recall crop; the drill needs this frame plus three other objects in the realm with valid recall crops.\n\nPaste and files — Paste text or images with Ctrl+V / Cmd+V when focus is outside text fields. On desktop, drop .png / .jpg / .webp on the drop target.\n\nSave — Writes the database, copies assets, and refreshes viewer and snapshot outputs so GateKeeper can reload.';

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
  String get realmAdminTooltipNuclear =>
      'Clear realm libraries (irreversible) — PAO & Match cards are preserved';

  @override
  String get realmAdminCleanupMenuTooltip =>
      'Clear PAO or Match cards data only';

  @override
  String get realmAdminCleanPaoTitle => 'Clear PAO data';

  @override
  String get realmAdminCleanPaoBody =>
      'Removes PAO rows in the active realm database and non-template JSON files under data/pao/. Realm tree and Match cards are not affected.';

  @override
  String get realmAdminCleanPaoConfirm => 'Clear PAO';

  @override
  String get realmAdminCleanPaoSnackbar => 'PAO data cleared.';

  @override
  String get realmAdminCleanMatchTitle => 'Clear Match cards data';

  @override
  String get realmAdminCleanMatchBody =>
      'Deletes all match-card decks, pairs, review state, and files under assets/lb_match_cards/ for the active realm. Irreversible.';

  @override
  String get realmAdminCleanMatchConfirm => 'Clear Match cards';

  @override
  String get realmAdminCleanMatchSnackbar => 'Match cards data cleared.';

  @override
  String get realmAdminMatchCardsTileTitle => 'Match cards';

  @override
  String get realmAdminMatchCardsTileSubtitle =>
      'Decks and image–text pairs for the active realm. Opens the Match cards view on the Library home.';

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
      'All realm folders under data/realms/ will be removed (assets, bridge, snapshots, manifests, realm_shelf.json). The repo folder data/pao/ is not deleted.\n\nPAO and Match cards from the active realm are copied into the new default database and assets.\n\nOnly a fresh base will remain at:\ndata/realms/default/alexandria.db\n\nThe realm seed snapshot will also be written to:\ndata/realm_seed/alexandria.db\n\nActive realm: default.\n\nClose the 3D viewer if it is open (file locking).\n\nTo confirm, type exactly:';

  @override
  String get realmAdminConfirmLabel => 'Confirmation';

  @override
  String get realmAdminPhraseMismatch => 'The phrase does not match exactly.';

  @override
  String get realmAdminNuclearButton => 'Delete all';

  @override
  String get realmAdminNuclearSuccessSnackbar =>
      'Realm libraries cleared; PAO & Match cards restored into default. default/alexandria.db + data/realm_seed/alexandria.db. Run Library build or reopen the app to regenerate snapshot/viewer.';

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
