import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Realm Library'**
  String get appTitle;

  /// No description provided for @librarySurfaceRealmTree.
  ///
  /// In en, this message translates to:
  /// **'Realm tree'**
  String get librarySurfaceRealmTree;

  /// No description provided for @activeRealmLabel.
  ///
  /// In en, this message translates to:
  /// **'Active realm: {realm}'**
  String activeRealmLabel(String realm);

  /// No description provided for @sectionReading.
  ///
  /// In en, this message translates to:
  /// **'READING'**
  String get sectionReading;

  /// No description provided for @sectionImport.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get sectionImport;

  /// No description provided for @sectionPao.
  ///
  /// In en, this message translates to:
  /// **'PAO'**
  String get sectionPao;

  /// No description provided for @sectionMatchCards.
  ///
  /// In en, this message translates to:
  /// **'MATCH CARDS'**
  String get sectionMatchCards;

  /// No description provided for @sectionGo.
  ///
  /// In en, this message translates to:
  /// **'GO'**
  String get sectionGo;

  /// No description provided for @sectionMetrics.
  ///
  /// In en, this message translates to:
  /// **'METRICS'**
  String get sectionMetrics;

  /// No description provided for @sectionSystem.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get sectionSystem;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get sectionLanguage;

  /// No description provided for @nodeReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Node reader'**
  String get nodeReaderTitle;

  /// No description provided for @nodeReaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Parcour or object (list)'**
  String get nodeReaderSubtitle;

  /// No description provided for @pdfNodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Node PDF'**
  String get pdfNodeTitle;

  /// No description provided for @pdfNodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Object or other entry'**
  String get pdfNodeSubtitle;

  /// No description provided for @pdfParcourTitle.
  ///
  /// In en, this message translates to:
  /// **'Parcour PDF'**
  String get pdfParcourTitle;

  /// No description provided for @pdfParcourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One parcour per export'**
  String get pdfParcourSubtitle;

  /// No description provided for @importLocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Import content into locus'**
  String get importLocusTitle;

  /// No description provided for @importLocusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From data-transfer/out/ → body_text'**
  String get importLocusSubtitle;

  /// No description provided for @dataTransferAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Data transfer → LibraryBuild'**
  String get dataTransferAppBarTitle;

  /// No description provided for @dataTransferRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh files and status'**
  String get dataTransferRefreshTooltip;

  /// No description provided for @dataTransferServerRepoLabel.
  ///
  /// In en, this message translates to:
  /// **'Server in repo: {path}'**
  String dataTransferServerRepoLabel(String path);

  /// No description provided for @dataTransferStartServer.
  ///
  /// In en, this message translates to:
  /// **'Start server (node)'**
  String get dataTransferStartServer;

  /// No description provided for @dataTransferStopLbProcess.
  ///
  /// In en, this message translates to:
  /// **'Stop LB process'**
  String get dataTransferStopLbProcess;

  /// No description provided for @dataTransferOpenWebUi.
  ///
  /// In en, this message translates to:
  /// **'Open web UI (:4020)'**
  String get dataTransferOpenWebUi;

  /// No description provided for @dataTransferServerReachable.
  ///
  /// In en, this message translates to:
  /// **'Server reachable at http://127.0.0.1:{port}'**
  String dataTransferServerReachable(int port);

  /// No description provided for @dataTransferHealthNoResponse.
  ///
  /// In en, this message translates to:
  /// **'No response on /health (start node or use local import only)'**
  String get dataTransferHealthNoResponse;

  /// No description provided for @dataTransferImportHeading.
  ///
  /// In en, this message translates to:
  /// **'Import file into a locus'**
  String get dataTransferImportHeading;

  /// No description provided for @dataTransferImportHint.
  ///
  /// In en, this message translates to:
  /// **'Source: {folder} · If the content starts with [ it is interpreted as block JSON; otherwise a single paragraph is created. “Append” mode concatenates blocks to the existing body.'**
  String dataTransferImportHint(String folder);

  /// No description provided for @dataTransferFolderLabelOut.
  ///
  /// In en, this message translates to:
  /// **'out/'**
  String get dataTransferFolderLabelOut;

  /// No description provided for @dataTransferFolderLabelIncoming.
  ///
  /// In en, this message translates to:
  /// **'handoff/incoming/'**
  String get dataTransferFolderLabelIncoming;

  /// No description provided for @dataTransferNoObjects.
  ///
  /// In en, this message translates to:
  /// **'No object entries in the database.'**
  String get dataTransferNoObjects;

  /// No description provided for @dataTransferTargetLocus.
  ///
  /// In en, this message translates to:
  /// **'Target locus (object)'**
  String get dataTransferTargetLocus;

  /// No description provided for @dataTransferLocusDropdownLine.
  ///
  /// In en, this message translates to:
  /// **'{key} — {title} (parent: {parentKey})'**
  String dataTransferLocusDropdownLine(
    String key,
    String title,
    String parentKey,
  );

  /// No description provided for @dataTransferFileFolder.
  ///
  /// In en, this message translates to:
  /// **'File folder'**
  String get dataTransferFileFolder;

  /// No description provided for @dataTransferSegmentOut.
  ///
  /// In en, this message translates to:
  /// **'out/'**
  String get dataTransferSegmentOut;

  /// No description provided for @dataTransferSegmentIncoming.
  ///
  /// In en, this message translates to:
  /// **'incoming/'**
  String get dataTransferSegmentIncoming;

  /// No description provided for @dataTransferFileCounts.
  ///
  /// In en, this message translates to:
  /// **'out/: {outCount} · incoming/: {incomingCount}'**
  String dataTransferFileCounts(int outCount, int incomingCount);

  /// No description provided for @dataTransferOutFolderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Folder out/ is empty. Use the web UI, switch to incoming/, or copy files into data-transfer/out/.'**
  String get dataTransferOutFolderEmpty;

  /// No description provided for @dataTransferIncomingFolderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Folder handoff/incoming/ is empty. Copy files here or use out/.'**
  String get dataTransferIncomingFolderEmpty;

  /// No description provided for @dataTransferFilePickerLabel.
  ///
  /// In en, this message translates to:
  /// **'File ({folder})'**
  String dataTransferFilePickerLabel(String folder);

  /// No description provided for @dataTransferImportMode.
  ///
  /// In en, this message translates to:
  /// **'Import mode'**
  String get dataTransferImportMode;

  /// No description provided for @dataTransferReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'Replace body'**
  String get dataTransferReplaceBody;

  /// No description provided for @dataTransferAppendBlocks.
  ///
  /// In en, this message translates to:
  /// **'Append at end'**
  String get dataTransferAppendBlocks;

  /// No description provided for @dataTransferImportRunBuild.
  ///
  /// In en, this message translates to:
  /// **'Import to locus and runLibraryBuild'**
  String get dataTransferImportRunBuild;

  /// No description provided for @dataTransferScriptMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing file: {path}'**
  String dataTransferScriptMissing(String path);

  /// No description provided for @dataTransferServerAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'A server is already listening on :4020 (external or another process)'**
  String get dataTransferServerAlreadyRunning;

  /// No description provided for @dataTransferNodeStartedNoHealth.
  ///
  /// In en, this message translates to:
  /// **'Node process started but /health does not respond. Is Node on PATH?'**
  String get dataTransferNodeStartedNoHealth;

  /// No description provided for @dataTransferNodeStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start node: {error}'**
  String dataTransferNodeStartFailed(String error);

  /// No description provided for @dataTransferOpenUrlFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String dataTransferOpenUrlFailed(String url);

  /// No description provided for @dataTransferPickFileAndLocus.
  ///
  /// In en, this message translates to:
  /// **'Choose a file and target locus.'**
  String get dataTransferPickFileAndLocus;

  /// No description provided for @dataTransferImportDoneReplace.
  ///
  /// In en, this message translates to:
  /// **'Replaced · {key} ({file})'**
  String dataTransferImportDoneReplace(String key, String file);

  /// No description provided for @dataTransferImportDoneAppend.
  ///
  /// In en, this message translates to:
  /// **'Appended · {key} ({file})'**
  String dataTransferImportDoneAppend(String key, String file);

  /// No description provided for @dataTransferErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String dataTransferErrorWithMessage(String message);

  /// No description provided for @dataTransferHttpStatus.
  ///
  /// In en, this message translates to:
  /// **'HTTP {code}'**
  String dataTransferHttpStatus(int code);

  /// No description provided for @paoEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'PAO'**
  String get paoEditorTitle;

  /// No description provided for @paoEditorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Phonetic keys · pegs 0–9 · 00–99 · 000–999 · JSON'**
  String get paoEditorSubtitle;

  /// No description provided for @paoTabPhonetic.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get paoTabPhonetic;

  /// No description provided for @paoTabDigit.
  ///
  /// In en, this message translates to:
  /// **'0–9'**
  String get paoTabDigit;

  /// No description provided for @paoTabPair.
  ///
  /// In en, this message translates to:
  /// **'00–99'**
  String get paoTabPair;

  /// No description provided for @paoTabTriple.
  ///
  /// In en, this message translates to:
  /// **'000–999'**
  String get paoTabTriple;

  /// No description provided for @paoPhoneticBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Assign consonants or sounds to each digit (your Major-system variant). Vowels are fillers—use the optional column for vowel notes only.'**
  String get paoPhoneticBoardHint;

  /// No description provided for @paoPhoneticConsonantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Consonants / sounds'**
  String get paoPhoneticConsonantsLabel;

  /// No description provided for @paoPhoneticVowelNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Vowel notes (optional)'**
  String get paoPhoneticVowelNoteLabel;

  /// No description provided for @paoPhoneticSaveRow.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get paoPhoneticSaveRow;

  /// No description provided for @paoPhoneticSaved.
  ///
  /// In en, this message translates to:
  /// **'Row saved'**
  String get paoPhoneticSaved;

  /// No description provided for @paoSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by code, person, action, object, or image path'**
  String get paoSearchHint;

  /// No description provided for @paoSubtitleTier.
  ///
  /// In en, this message translates to:
  /// **'{filled} / {total} with text or image · realm {realm}'**
  String paoSubtitleTier(int filled, int total, String realm);

  /// No description provided for @paoMenuImportJsonAuto.
  ///
  /// In en, this message translates to:
  /// **'Import JSON (auto: full v2 or legacy 00–99)'**
  String get paoMenuImportJsonAuto;

  /// No description provided for @paoMenuExportJsonV2.
  ///
  /// In en, this message translates to:
  /// **'Export JSON (full v2)…'**
  String get paoMenuExportJsonV2;

  /// No description provided for @paoMenuExportPairCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV (00–99 only)…'**
  String get paoMenuExportPairCsv;

  /// No description provided for @paoMenuTemplateV2.
  ///
  /// In en, this message translates to:
  /// **'Write empty template v2 in repo'**
  String get paoMenuTemplateV2;

  /// No description provided for @paoSnackbarImportOk.
  ///
  /// In en, this message translates to:
  /// **'PAO data imported'**
  String get paoSnackbarImportOk;

  /// No description provided for @paoSnackbarTemplateV2.
  ///
  /// In en, this message translates to:
  /// **'Template v2 written: {path}'**
  String paoSnackbarTemplateV2(String path);

  /// No description provided for @paoEditCodeImageHintPair.
  ///
  /// In en, this message translates to:
  /// **'Code image (00–99): drag here or Ctrl/Cmd+V with focus outside text fields.'**
  String get paoEditCodeImageHintPair;

  /// No description provided for @paoEditCodeImageHintDigit.
  ///
  /// In en, this message translates to:
  /// **'Code image (single digit): drag here or Ctrl/Cmd+V with focus outside text fields.'**
  String get paoEditCodeImageHintDigit;

  /// No description provided for @paoEditCodeImageHintTriple.
  ///
  /// In en, this message translates to:
  /// **'Code image (000–999): drag here or Ctrl/Cmd+V with focus outside text fields.'**
  String get paoEditCodeImageHintTriple;

  /// No description provided for @paoEditPreviewExerciseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Preview in practice'**
  String get paoEditPreviewExerciseTooltip;

  /// No description provided for @paoEditPreviewExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice preview'**
  String get paoEditPreviewExerciseTitle;

  /// No description provided for @paoEditPreviewExerciseIntro.
  ///
  /// In en, this message translates to:
  /// **'How this peg can look in individual practice (all drill stimuli and the answers panel).'**
  String get paoEditPreviewExerciseIntro;

  /// No description provided for @paoPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'PAO · individual practice'**
  String get paoPracticeTitle;

  /// No description provided for @paoPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mental recall · show answers · pass / fail'**
  String get paoPracticeSubtitle;

  /// No description provided for @paoDrillInstruction.
  ///
  /// In en, this message translates to:
  /// **'Recall silently; do not type. Then show the answers and mark pass or fail.'**
  String get paoDrillInstruction;

  /// No description provided for @paoDrillModeCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Code → person, action, object (mental)'**
  String get paoDrillModeCodeTitle;

  /// No description provided for @paoDrillModePersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Person → code, action, object (mental)'**
  String get paoDrillModePersonTitle;

  /// No description provided for @paoDrillModeObjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Object → code, person, action (mental)'**
  String get paoDrillModeObjectTitle;

  /// No description provided for @paoDrillPoolInfo.
  ///
  /// In en, this message translates to:
  /// **'{count} codes · realm {realmId}'**
  String paoDrillPoolInfo(int count, String realmId);

  /// No description provided for @paoDrillShowAnswers.
  ///
  /// In en, this message translates to:
  /// **'Show answers'**
  String get paoDrillShowAnswers;

  /// No description provided for @paoDrillAnswersHeading.
  ///
  /// In en, this message translates to:
  /// **'Answers'**
  String get paoDrillAnswersHeading;

  /// No description provided for @paoFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get paoFieldCode;

  /// No description provided for @paoFieldPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get paoFieldPerson;

  /// No description provided for @paoFieldAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get paoFieldAction;

  /// No description provided for @paoFieldObject.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get paoFieldObject;

  /// No description provided for @paoDrillSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get paoDrillSuccess;

  /// No description provided for @paoDrillFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get paoDrillFail;

  /// No description provided for @paoDrillNextUnmarked.
  ///
  /// In en, this message translates to:
  /// **'Next (unmarked)'**
  String get paoDrillNextUnmarked;

  /// No description provided for @paoDrillEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No codes ready to practice.'**
  String get paoDrillEmptyTitle;

  /// No description provided for @paoDrillEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in person, action, and object for at least one code in PAO (digit, pair 00–99, or triple 000–999).'**
  String get paoDrillEmptyHint;

  /// No description provided for @paoDrillStimulusCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get paoDrillStimulusCode;

  /// No description provided for @paoDrillStimulusPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get paoDrillStimulusPerson;

  /// No description provided for @paoDrillStimulusObject.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get paoDrillStimulusObject;

  /// No description provided for @paoDrillStimulusRecallNumber.
  ///
  /// In en, this message translates to:
  /// **'Recall the number'**
  String get paoDrillStimulusRecallNumber;

  /// No description provided for @paoDrillStimulusRecallMnemonic.
  ///
  /// In en, this message translates to:
  /// **'Recall the image (mnemonic)'**
  String get paoDrillStimulusRecallMnemonic;

  /// No description provided for @paoDrillPoolAllTiersHint.
  ///
  /// In en, this message translates to:
  /// **'Pool: random codes from 0–9, 00–99, and 000–999 (complete rows only). Each code round shows either the number or the code image — not both.'**
  String get paoDrillPoolAllTiersHint;

  /// No description provided for @paoListEmptyRow.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get paoListEmptyRow;

  /// No description provided for @paoListDetailLine.
  ///
  /// In en, this message translates to:
  /// **'P: {person}  |  A: {action}  |  O: {object}'**
  String paoListDetailLine(String person, String action, String object);

  /// No description provided for @paoEditChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get paoEditChooseImage;

  /// No description provided for @paoEditRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get paoEditRemoveImage;

  /// No description provided for @paoEditNoImageOptional.
  ///
  /// In en, this message translates to:
  /// **'No image (optional)'**
  String get paoEditNoImageOptional;

  /// No description provided for @paoEditImageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get paoEditImageLoadError;

  /// No description provided for @paoEditPersonImage1.
  ///
  /// In en, this message translates to:
  /// **'Character image 1'**
  String get paoEditPersonImage1;

  /// No description provided for @paoEditPersonImage2.
  ///
  /// In en, this message translates to:
  /// **'Character image 2'**
  String get paoEditPersonImage2;

  /// No description provided for @paoEditObjectImage1.
  ///
  /// In en, this message translates to:
  /// **'Object image 1'**
  String get paoEditObjectImage1;

  /// No description provided for @paoEditObjectImage2.
  ///
  /// In en, this message translates to:
  /// **'Object image 2'**
  String get paoEditObjectImage2;

  /// No description provided for @paoEditPasteImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste image (Ctrl+V in this slot)'**
  String get paoEditPasteImageTooltip;

  /// No description provided for @paoTemplateExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Template already exists'**
  String get paoTemplateExistsTitle;

  /// No description provided for @paoTemplateExistsBody.
  ///
  /// In en, this message translates to:
  /// **'Overwrite?\n{path}'**
  String paoTemplateExistsBody(String path);

  /// No description provided for @paoOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get paoOverwrite;

  /// No description provided for @paoTemplateWritten0099.
  ///
  /// In en, this message translates to:
  /// **'Template written: {path}'**
  String paoTemplateWritten0099(String path);

  /// No description provided for @paoExportJsonDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export PAO JSON v2'**
  String get paoExportJsonDialogTitle;

  /// No description provided for @paoExportCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export PAO CSV'**
  String get paoExportCsvDialogTitle;

  /// No description provided for @paoSavedToPath.
  ///
  /// In en, this message translates to:
  /// **'Saved: {path}'**
  String paoSavedToPath(String path);

  /// No description provided for @paoErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String paoErrorGeneric(String message);

  /// No description provided for @paoJsonV2CopiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'PAO v2 JSON copied to clipboard'**
  String get paoJsonV2CopiedClipboard;

  /// No description provided for @paoMenuTemplate0099.
  ///
  /// In en, this message translates to:
  /// **'Template 00–99 (repo)'**
  String get paoMenuTemplate0099;

  /// No description provided for @paoMenuCopyJsonV2Clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON v2 to clipboard'**
  String get paoMenuCopyJsonV2Clipboard;

  /// No description provided for @paoSnackbarPasteImageUseTabs.
  ///
  /// In en, this message translates to:
  /// **'Paste image: open tab 0–9, 00–99, or 000–999 and tap a row.'**
  String get paoSnackbarPasteImageUseTabs;

  /// No description provided for @paoSnackbarTapRowFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap a row first to choose the code.'**
  String get paoSnackbarTapRowFirst;

  /// No description provided for @paoSnackbarCodeNotInTab.
  ///
  /// In en, this message translates to:
  /// **'Code not found in this tab.'**
  String get paoSnackbarCodeNotInTab;

  /// No description provided for @paoSnackbarClipboardNoImage.
  ///
  /// In en, this message translates to:
  /// **'Clipboard: no image'**
  String get paoSnackbarClipboardNoImage;

  /// No description provided for @paoSnackbarCouldNotSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Could not save image'**
  String get paoSnackbarCouldNotSaveImage;

  /// No description provided for @paoSnackbarCouldNotCopyImage.
  ///
  /// In en, this message translates to:
  /// **'Could not copy image'**
  String get paoSnackbarCouldNotCopyImage;

  /// No description provided for @paoSnackbarCodeImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Code {code} image updated'**
  String paoSnackbarCodeImageUpdated(String code);

  /// No description provided for @paoSnackbarDropImageUseTabs.
  ///
  /// In en, this message translates to:
  /// **'Drop image on tab 0–9, 00–99, or 000–999 (after tapping a row).'**
  String get paoSnackbarDropImageUseTabs;

  /// No description provided for @paoEditDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'PAO {code}'**
  String paoEditDialogTitle(String code);

  /// No description provided for @paoEditDeletePegButton.
  ///
  /// In en, this message translates to:
  /// **'Delete peg'**
  String get paoEditDeletePegButton;

  /// No description provided for @paoEditDeletePegConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this peg?'**
  String get paoEditDeletePegConfirmTitle;

  /// No description provided for @paoEditDeletePegConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes all text and images for this code and deletes the image files from the realm assets folder.'**
  String get paoEditDeletePegConfirmBody;

  /// No description provided for @paoEditDeletePegSuccess.
  ///
  /// In en, this message translates to:
  /// **'Peg cleared'**
  String get paoEditDeletePegSuccess;

  /// No description provided for @pokerMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Poker · number map'**
  String get pokerMemoryTitle;

  /// No description provided for @pokerMemoryDrawerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Number ↔ card · 13 numbers per suit · quick drill'**
  String get pokerMemoryDrawerSubtitle;

  /// No description provided for @frameRecallQuizDrawerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'4-image crop quiz · same parcour'**
  String get frameRecallQuizDrawerSubtitle;

  /// No description provided for @frameRecallQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Frame recall (prototype)'**
  String get frameRecallQuizTitle;

  /// No description provided for @frameRecallQuizIntro.
  ///
  /// In en, this message translates to:
  /// **'Each locus needs one image block with role «Recall crop» (detail of the hero). Hero is not shown here — only your place hint and four crops. Pick the crop that belongs to the locus described.'**
  String get frameRecallQuizIntro;

  /// No description provided for @frameRecallSelectParcour.
  ///
  /// In en, this message translates to:
  /// **'Parcour'**
  String get frameRecallSelectParcour;

  /// No description provided for @frameRecallFramesWithCrop.
  ///
  /// In en, this message translates to:
  /// **'{count} frames with recall crop'**
  String frameRecallFramesWithCrop(int count);

  /// No description provided for @frameRecallNeedFour.
  ///
  /// In en, this message translates to:
  /// **'Need at least 4 loci in this parcour with a recall crop image. Edit each locus and add an image with role «Recall crop».'**
  String get frameRecallNeedFour;

  /// No description provided for @frameRecallNoParcours.
  ///
  /// In en, this message translates to:
  /// **'No parcours under the hub. Create parcours first.'**
  String get frameRecallNoParcours;

  /// No description provided for @frameRecallQuestion.
  ///
  /// In en, this message translates to:
  /// **'Place / hint'**
  String get frameRecallQuestion;

  /// No description provided for @frameRecallLocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Locus'**
  String get frameRecallLocusLabel;

  /// No description provided for @frameRecallPickCrop.
  ///
  /// In en, this message translates to:
  /// **'Which crop matches?'**
  String get frameRecallPickCrop;

  /// No description provided for @frameRecallCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct.'**
  String get frameRecallCorrect;

  /// No description provided for @frameRecallWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong — green border shows the right crop.'**
  String get frameRecallWrong;

  /// No description provided for @frameRecallNext.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get frameRecallNext;

  /// No description provided for @frameRecallMissingFile.
  ///
  /// In en, this message translates to:
  /// **'Missing file: {name}'**
  String frameRecallMissingFile(String name);

  /// No description provided for @pokerMemoryTabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get pokerMemoryTabMap;

  /// No description provided for @pokerMemoryTabRanges.
  ///
  /// In en, this message translates to:
  /// **'Ranges'**
  String get pokerMemoryTabRanges;

  /// No description provided for @pokerMemoryTabDrill.
  ///
  /// In en, this message translates to:
  /// **'Quick drill'**
  String get pokerMemoryTabDrill;

  /// No description provided for @pokerMemoryMapIntro.
  ///
  /// In en, this message translates to:
  /// **'Each number maps to one card (A, 2–10, J, Q, K within the suit block). Edit ranges on the Ranges tab.'**
  String get pokerMemoryMapIntro;

  /// No description provided for @pokerMemoryMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No mappings. Check ranges (each suit must span exactly 13 numbers, no overlaps).'**
  String get pokerMemoryMapEmpty;

  /// No description provided for @pokerMemoryRangesIntro.
  ///
  /// In en, this message translates to:
  /// **'Assign a contiguous block of 13 numbers per suit. Default: spades 01–13, hearts 41–53, diamonds 61–73, clubs 81–93.'**
  String get pokerMemoryRangesIntro;

  /// No description provided for @pokerMemoryRangeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get pokerMemoryRangeFrom;

  /// No description provided for @pokerMemoryRangeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get pokerMemoryRangeTo;

  /// No description provided for @pokerMemoryRangesSave.
  ///
  /// In en, this message translates to:
  /// **'Save ranges'**
  String get pokerMemoryRangesSave;

  /// No description provided for @pokerMemoryRangesSaved.
  ///
  /// In en, this message translates to:
  /// **'Ranges saved'**
  String get pokerMemoryRangesSaved;

  /// No description provided for @pokerMemoryRangesInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter valid integers for from / to.'**
  String get pokerMemoryRangesInvalidNumber;

  /// No description provided for @pokerMemoryRangesHint.
  ///
  /// In en, this message translates to:
  /// **'Ranks are fixed in order: A, 2, 3, …, 10, J, Q, K within each block. Gaps between blocks are allowed.'**
  String get pokerMemoryRangesHint;

  /// No description provided for @pokerMemorySuitSpades.
  ///
  /// In en, this message translates to:
  /// **'Spades'**
  String get pokerMemorySuitSpades;

  /// No description provided for @pokerMemorySuitHearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get pokerMemorySuitHearts;

  /// No description provided for @pokerMemorySuitDiamonds.
  ///
  /// In en, this message translates to:
  /// **'Diamonds'**
  String get pokerMemorySuitDiamonds;

  /// No description provided for @pokerMemorySuitClubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get pokerMemorySuitClubs;

  /// No description provided for @pokerMemoryDrillInstruction.
  ///
  /// In en, this message translates to:
  /// **'Recall the other side mentally, then reveal and mark pass or fail.'**
  String get pokerMemoryDrillInstruction;

  /// No description provided for @pokerMemoryDrillModeNumberToCard.
  ///
  /// In en, this message translates to:
  /// **'Number → card'**
  String get pokerMemoryDrillModeNumberToCard;

  /// No description provided for @pokerMemoryDrillModeCardToNumber.
  ///
  /// In en, this message translates to:
  /// **'Card → number'**
  String get pokerMemoryDrillModeCardToNumber;

  /// No description provided for @pokerMemoryDrillPoolInfo.
  ///
  /// In en, this message translates to:
  /// **'{count} cards · realm {realmId}'**
  String pokerMemoryDrillPoolInfo(int count, String realmId);

  /// No description provided for @pokerMemoryStimulusNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get pokerMemoryStimulusNumber;

  /// No description provided for @pokerMemoryStimulusCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get pokerMemoryStimulusCard;

  /// No description provided for @pokerMemoryShowAnswer.
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get pokerMemoryShowAnswer;

  /// No description provided for @pokerMemoryAnswerHeading.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get pokerMemoryAnswerHeading;

  /// No description provided for @pokerMemoryAnswerNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get pokerMemoryAnswerNumber;

  /// No description provided for @pokerMemoryAnswerCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get pokerMemoryAnswerCard;

  /// No description provided for @pokerMemoryPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pokerMemoryPass;

  /// No description provided for @pokerMemoryFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get pokerMemoryFail;

  /// No description provided for @pokerMemoryNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get pokerMemoryNext;

  /// No description provided for @pokerMemoryDrillEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to drill. Fix ranges first.'**
  String get pokerMemoryDrillEmpty;

  /// No description provided for @matchCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Match cards'**
  String get matchCardsTitle;

  /// No description provided for @matchCardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Image ↔ caption pairs · random session (LB only)'**
  String get matchCardsSubtitle;

  /// No description provided for @matchCardsOrmHint.
  ///
  /// In en, this message translates to:
  /// **'Each pair: lemma (native script), optional transliteration, optional meaning (gloss), and image. route_key is for future “along a route”. Practice sessions pick cards by Fibonacci step (shorter interval first), then by higher fail counts.'**
  String get matchCardsOrmHint;

  /// No description provided for @matchCardsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pairs yet. Add an image and a caption.'**
  String get matchCardsEmpty;

  /// No description provided for @matchCardsAddPair.
  ///
  /// In en, this message translates to:
  /// **'Add pair'**
  String get matchCardsAddPair;

  /// No description provided for @matchCardsPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get matchCardsPractice;

  /// No description provided for @matchCardsDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove pair'**
  String get matchCardsDeleteTooltip;

  /// No description provided for @matchCardsAddDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New pair'**
  String get matchCardsAddDialogTitle;

  /// No description provided for @matchCardsLemmaLabel.
  ///
  /// In en, this message translates to:
  /// **'Lemma / word (native script)'**
  String get matchCardsLemmaLabel;

  /// No description provided for @matchCardsLemmaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. кошка'**
  String get matchCardsLemmaHint;

  /// No description provided for @matchCardsLemmaRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the lemma first.'**
  String get matchCardsLemmaRequired;

  /// No description provided for @matchCardsTransliterationLabel.
  ///
  /// In en, this message translates to:
  /// **'Transliteration (optional)'**
  String get matchCardsTransliterationLabel;

  /// No description provided for @matchCardsTransliterationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. koshka'**
  String get matchCardsTransliterationHint;

  /// No description provided for @matchCardsGlossLabel.
  ///
  /// In en, this message translates to:
  /// **'Meaning (optional)'**
  String get matchCardsGlossLabel;

  /// No description provided for @matchCardsGlossHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. cat'**
  String get matchCardsGlossHint;

  /// No description provided for @matchCardsPickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get matchCardsPickImage;

  /// No description provided for @matchCardsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get matchCardsCancel;

  /// No description provided for @matchCardsSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Match session'**
  String get matchCardsSessionTitle;

  /// No description provided for @matchCardsNeedTwoPairs.
  ///
  /// In en, this message translates to:
  /// **'Add at least two pairs in Match cards to play.'**
  String get matchCardsNeedTwoPairs;

  /// No description provided for @matchCardsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match — try again.'**
  String get matchCardsNoMatch;

  /// No description provided for @matchCardsPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get matchCardsPlayAgain;

  /// No description provided for @matchCardsSessionMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get matchCardsSessionMenuTooltip;

  /// No description provided for @matchCardsSessionNewRound.
  ///
  /// In en, this message translates to:
  /// **'New round'**
  String get matchCardsSessionNewRound;

  /// No description provided for @matchCardsSessionChangeDeck.
  ///
  /// In en, this message translates to:
  /// **'Change deck…'**
  String get matchCardsSessionChangeDeck;

  /// No description provided for @matchCardsSessionStats.
  ///
  /// In en, this message translates to:
  /// **'Weakest cards…'**
  String get matchCardsSessionStats;

  /// No description provided for @matchCardsSessionStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Deck stats'**
  String get matchCardsSessionStatsTitle;

  /// No description provided for @matchCardsSessionStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rounds prioritize low Fibonacci step (needs practice), then higher fail counts. Each wrong image–text match increments fails for both cards.'**
  String get matchCardsSessionStatsSubtitle;

  /// No description provided for @matchCardsSessionStatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No review data yet — finish a few rounds to see counts.'**
  String get matchCardsSessionStatsEmpty;

  /// No description provided for @matchCardsSessionStatsFailPass.
  ///
  /// In en, this message translates to:
  /// **'{fails} fails · {passes} OK'**
  String matchCardsSessionStatsFailPass(int fails, int passes);

  /// No description provided for @matchCardsSessionStatsFib.
  ///
  /// In en, this message translates to:
  /// **'Step {n}'**
  String matchCardsSessionStatsFib(int n);

  /// No description provided for @matchCardsDeckOverviewKpis.
  ///
  /// In en, this message translates to:
  /// **'{pairCount} pairs · {dueCount} due · match rate {matchRate}'**
  String matchCardsDeckOverviewKpis(
    int pairCount,
    int dueCount,
    String matchRate,
  );

  /// No description provided for @matchCardsDeckOverviewFibBars.
  ///
  /// In en, this message translates to:
  /// **'Pairs per Fibonacci step (bar height)'**
  String get matchCardsDeckOverviewFibBars;

  /// No description provided for @matchCardsDeckStatsMenu.
  ///
  /// In en, this message translates to:
  /// **'Deck statistics…'**
  String get matchCardsDeckStatsMenu;

  /// No description provided for @matchCardsSessionPickDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose deck'**
  String get matchCardsSessionPickDeckTitle;

  /// No description provided for @matchCardsAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts: {count}'**
  String matchCardsAttempts(int count);

  /// No description provided for @matchCardsComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get matchCardsComplete;

  /// No description provided for @matchCardsPairsRemaining.
  ///
  /// In en, this message translates to:
  /// **'pairs left'**
  String get matchCardsPairsRemaining;

  /// No description provided for @matchCardsPasteDropHint.
  ///
  /// In en, this message translates to:
  /// **'Paste image: Ctrl+V (⌘V on Mac) outside a text field. Or drop an image file here. Captions accept any script (Chinese, Japanese, Russian, …).'**
  String get matchCardsPasteDropHint;

  /// No description provided for @matchCardsLemmaUnicodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Any script — stored as UTF-8.'**
  String get matchCardsLemmaUnicodeHelper;

  /// No description provided for @matchCardsImageReady.
  ///
  /// In en, this message translates to:
  /// **'Image ready — add caption and save.'**
  String get matchCardsImageReady;

  /// No description provided for @matchCardsPasteImageInDialog.
  ///
  /// In en, this message translates to:
  /// **'Paste image from clipboard'**
  String get matchCardsPasteImageInDialog;

  /// No description provided for @matchCardsSavePair.
  ///
  /// In en, this message translates to:
  /// **'Save pair'**
  String get matchCardsSavePair;

  /// No description provided for @matchCardsImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose, paste, or drop an image first.'**
  String get matchCardsImageRequired;

  /// No description provided for @matchCardsClipboardNoImage.
  ///
  /// In en, this message translates to:
  /// **'Clipboard has no image.'**
  String get matchCardsClipboardNoImage;

  /// No description provided for @matchCardsDeckLabel.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get matchCardsDeckLabel;

  /// No description provided for @matchCardsDeckMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decks · export · import'**
  String get matchCardsDeckMenuTooltip;

  /// No description provided for @matchCardsNewDeckMenu.
  ///
  /// In en, this message translates to:
  /// **'New deck…'**
  String get matchCardsNewDeckMenu;

  /// No description provided for @matchCardsRenameDeckMenu.
  ///
  /// In en, this message translates to:
  /// **'Rename deck…'**
  String get matchCardsRenameDeckMenu;

  /// No description provided for @matchCardsDeleteDeckMenu.
  ///
  /// In en, this message translates to:
  /// **'Delete deck…'**
  String get matchCardsDeleteDeckMenu;

  /// No description provided for @matchCardsExportMenu.
  ///
  /// In en, this message translates to:
  /// **'Export deck (.zip)…'**
  String get matchCardsExportMenu;

  /// No description provided for @matchCardsImportMenu.
  ///
  /// In en, this message translates to:
  /// **'Import deck (.zip)…'**
  String get matchCardsImportMenu;

  /// No description provided for @matchCardsNewDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'New deck'**
  String get matchCardsNewDeckTitle;

  /// No description provided for @matchCardsRenameDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename deck'**
  String get matchCardsRenameDeckTitle;

  /// No description provided for @matchCardsDeleteDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete deck?'**
  String get matchCardsDeleteDeckTitle;

  /// No description provided for @matchCardsDeleteDeckBody.
  ///
  /// In en, this message translates to:
  /// **'Pairs in this deck will be moved to another deck.'**
  String get matchCardsDeleteDeckBody;

  /// No description provided for @matchCardsDeleteDeckConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get matchCardsDeleteDeckConfirm;

  /// No description provided for @matchCardsDeckNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get matchCardsDeckNameLabel;

  /// No description provided for @matchCardsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Save deck export'**
  String get matchCardsExportTitle;

  /// No description provided for @matchCardsExportDone.
  ///
  /// In en, this message translates to:
  /// **'Export saved.'**
  String get matchCardsExportDone;

  /// No description provided for @matchCardsExportError.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String matchCardsExportError(String error);

  /// No description provided for @matchCardsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'New deck for import'**
  String get matchCardsImportTitle;

  /// No description provided for @matchCardsImportDefaultDeckName.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get matchCardsImportDefaultDeckName;

  /// No description provided for @matchCardsImportNewDeckNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Deck name'**
  String get matchCardsImportNewDeckNameLabel;

  /// No description provided for @matchCardsImportNewDeckNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Pairs from the file are added to this new deck.'**
  String get matchCardsImportNewDeckNameHelper;

  /// No description provided for @matchCardsImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get matchCardsImportConfirm;

  /// No description provided for @matchCardsImportDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} pair(s).'**
  String matchCardsImportDone(int count);

  /// No description provided for @matchCardsImportError.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String matchCardsImportError(String error);

  /// No description provided for @matchCardsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search lemma, transliteration, gloss…'**
  String get matchCardsSearchHint;

  /// No description provided for @matchCardsDuplicatesOnly.
  ///
  /// In en, this message translates to:
  /// **'Duplicates only'**
  String get matchCardsDuplicatesOnly;

  /// No description provided for @matchCardsDuplicateSummary.
  ///
  /// In en, this message translates to:
  /// **'{groups} duplicate lemma(s) in this deck'**
  String matchCardsDuplicateSummary(int groups);

  /// No description provided for @matchCardsSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No cards match the search or filter.'**
  String get matchCardsSearchNoResults;

  /// No description provided for @matchCardsDuplicateLemmaTooltip.
  ///
  /// In en, this message translates to:
  /// **'Same lemma as another card in this deck'**
  String get matchCardsDuplicateLemmaTooltip;

  /// No description provided for @matchCardsDuplicateSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate lemma'**
  String get matchCardsDuplicateSaveTitle;

  /// No description provided for @matchCardsDuplicateSaveBody.
  ///
  /// In en, this message translates to:
  /// **'A pair with this lemma already exists in this deck.'**
  String get matchCardsDuplicateSaveBody;

  /// No description provided for @matchCardsContinueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get matchCardsContinueAnyway;

  /// No description provided for @goGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Go 9×9'**
  String get goGameTitle;

  /// No description provided for @goGameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Captures, no suicide, positional superko. Two passes end the game. Komi for White.'**
  String get goGameSubtitle;

  /// No description provided for @goGameModePvp.
  ///
  /// In en, this message translates to:
  /// **'Two players'**
  String get goGameModePvp;

  /// No description provided for @goGameModeBot.
  ///
  /// In en, this message translates to:
  /// **'vs Bot (you are Black)'**
  String get goGameModeBot;

  /// No description provided for @goGameNew.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get goGameNew;

  /// No description provided for @goGamePass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get goGamePass;

  /// No description provided for @goGameBlackTurn.
  ///
  /// In en, this message translates to:
  /// **'Black to play'**
  String get goGameBlackTurn;

  /// No description provided for @goGameWhiteTurn.
  ///
  /// In en, this message translates to:
  /// **'White to play'**
  String get goGameWhiteTurn;

  /// No description provided for @goGameBotThinking.
  ///
  /// In en, this message translates to:
  /// **'Bot thinking…'**
  String get goGameBotThinking;

  /// No description provided for @goGameIllegal.
  ///
  /// In en, this message translates to:
  /// **'Illegal move'**
  String get goGameIllegal;

  /// No description provided for @goGameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get goGameOver;

  /// No description provided for @goGameScoreSummary.
  ///
  /// In en, this message translates to:
  /// **'Black {blackPt} pts — White {whiteBoardPt} on board + {komi} komi = {whiteTotal} pts. {verdict}'**
  String goGameScoreSummary(
    String blackPt,
    String whiteBoardPt,
    String komi,
    String whiteTotal,
    String verdict,
  );

  /// No description provided for @goGameVerdictDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw.'**
  String get goGameVerdictDraw;

  /// No description provided for @goGameVerdictBlackWins.
  ///
  /// In en, this message translates to:
  /// **'Black wins by {margin} pts.'**
  String goGameVerdictBlackWins(String margin);

  /// No description provided for @goGameVerdictWhiteWins.
  ///
  /// In en, this message translates to:
  /// **'White wins by {margin} pts.'**
  String goGameVerdictWhiteWins(String margin);

  /// No description provided for @goGameStoneTotals.
  ///
  /// In en, this message translates to:
  /// **'Stones on grid: Black {blackStones} · White {whiteStones}'**
  String goGameStoneTotals(int blackStones, int whiteStones);

  /// No description provided for @goStudyTabFree.
  ///
  /// In en, this message translates to:
  /// **'Free play'**
  String get goStudyTabFree;

  /// No description provided for @goStudyTabProblems.
  ///
  /// In en, this message translates to:
  /// **'Problems'**
  String get goStudyTabProblems;

  /// No description provided for @goStudyLibraryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Problem library & progress'**
  String get goStudyLibraryTooltip;

  /// No description provided for @goStudyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Go problems'**
  String get goStudyLibraryTitle;

  /// No description provided for @goStudyLibraryLine.
  ///
  /// In en, this message translates to:
  /// **'{solved} solved · {mastered} studied (3+ hits)'**
  String goStudyLibraryLine(int solved, int mastered);

  /// No description provided for @goStudyMasteredLabel.
  ///
  /// In en, this message translates to:
  /// **'Studied'**
  String get goStudyMasteredLabel;

  /// No description provided for @goStudySolvedLabel.
  ///
  /// In en, this message translates to:
  /// **'Solved once'**
  String get goStudySolvedLabel;

  /// No description provided for @goStudyAttemptsLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} attempts'**
  String goStudyAttemptsLabel(int n);

  /// No description provided for @goStudyProblemWrong.
  ///
  /// In en, this message translates to:
  /// **'Not the intended move — try again.'**
  String get goStudyProblemWrong;

  /// No description provided for @goStudyProblemCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get goStudyProblemCorrect;

  /// No description provided for @goStudyHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get goStudyHint;

  /// No description provided for @goStudyShowLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal moves'**
  String get goStudyShowLegal;

  /// No description provided for @goStudyProblemIndex.
  ///
  /// In en, this message translates to:
  /// **'Problem {current} / {total}'**
  String goStudyProblemIndex(int current, int total);

  /// No description provided for @goStudyNextProblem.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get goStudyNextProblem;

  /// No description provided for @goStudyPrevProblem.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get goStudyPrevProblem;

  /// No description provided for @goStudyResetProblem.
  ///
  /// In en, this message translates to:
  /// **'Reset position'**
  String get goStudyResetProblem;

  /// No description provided for @goStudyPassDisabled.
  ///
  /// In en, this message translates to:
  /// **'Pass is disabled in this problem mode.'**
  String get goStudyPassDisabled;

  /// No description provided for @goStudyBotDisabled.
  ///
  /// In en, this message translates to:
  /// **'Bot is off during problems.'**
  String get goStudyBotDisabled;

  /// No description provided for @goProblemCapTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture (atari)'**
  String get goProblemCapTitle;

  /// No description provided for @goProblemCapHint.
  ///
  /// In en, this message translates to:
  /// **'Remove the last liberty of the white stone.'**
  String get goProblemCapHint;

  /// No description provided for @goProblemConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect (side)'**
  String get goProblemConnectTitle;

  /// No description provided for @goProblemConnectHint.
  ///
  /// In en, this message translates to:
  /// **'Play between the two black stones.'**
  String get goProblemConnectHint;

  /// No description provided for @goProblemBridgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect (up/down)'**
  String get goProblemBridgeTitle;

  /// No description provided for @goProblemBridgeHint.
  ///
  /// In en, this message translates to:
  /// **'Join the two black stones on the same file.'**
  String get goProblemBridgeHint;

  /// No description provided for @metricsRecallTitle.
  ///
  /// In en, this message translates to:
  /// **'Recall metrics'**
  String get metricsRecallTitle;

  /// No description provided for @metricsRecallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get metricsRecallSubtitle;

  /// No description provided for @realmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Realms'**
  String get realmsTitle;

  /// No description provided for @realmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Core / Active / Seek'**
  String get realmsSubtitle;

  /// No description provided for @navigationIntentTitle.
  ///
  /// In en, this message translates to:
  /// **'Study navigation'**
  String get navigationIntentTitle;

  /// No description provided for @navigationIntentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tap to cycle modes. With a focused object, line 2 in the bridge file is the Hero frame key for place / hint / story.'**
  String get navigationIntentTooltip;

  /// No description provided for @memoryAthleteSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Parcour pass: 100% (athlete) vs 80% (standard)'**
  String get memoryAthleteSwitchTitle;

  /// No description provided for @memoryAthleteSwitchSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Switch on — full pass required (100% of session score).'**
  String get memoryAthleteSwitchSubtitleOn;

  /// No description provided for @memoryAthleteSwitchSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Switch off — pass at 80% of session score (standard).'**
  String get memoryAthleteSwitchSubtitleOff;

  /// No description provided for @studyNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Study navigation'**
  String get studyNavigationTitle;

  /// No description provided for @studyNavigationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tap to cycle modes. Subtitle: mode and Hero frame key.'**
  String get studyNavigationTooltip;

  /// No description provided for @studyNavigationDetailModeOnly.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String studyNavigationDetailModeOnly(String mode);

  /// No description provided for @studyNavigationDetailWithFrame.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}\nFrame (Hero locus): {frame}'**
  String studyNavigationDetailWithFrame(String mode, String frame);

  /// No description provided for @menuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Go up'**
  String get backTooltip;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search objects (FTS5) · Core / Active / Seek'**
  String get searchTooltip;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Regenerate snapshot / list'**
  String get refreshTooltip;

  /// No description provided for @emptyLevelMessage.
  ///
  /// In en, this message translates to:
  /// **'No entries at this level.\nGo back to continue.'**
  String get emptyLevelMessage;

  /// No description provided for @tooltipDoubleTapObject.
  ///
  /// In en, this message translates to:
  /// **'Double-tap: content viewer (node card)'**
  String get tooltipDoubleTapObject;

  /// No description provided for @tooltipDoubleTapEnter.
  ///
  /// In en, this message translates to:
  /// **'Double-tap to enter this level'**
  String get tooltipDoubleTapEnter;

  /// No description provided for @tooltipRoleObject.
  ///
  /// In en, this message translates to:
  /// **'Role (LB only). Double-tap: content viewer.'**
  String get tooltipRoleObject;

  /// No description provided for @tooltipRoleEnter.
  ///
  /// In en, this message translates to:
  /// **'Role (LB only; GK does not read it). Double-tap the row to enter.'**
  String get tooltipRoleEnter;

  /// No description provided for @lastReviewPrefix.
  ///
  /// In en, this message translates to:
  /// **'·  Last review: {when}'**
  String lastReviewPrefix(String when);

  /// No description provided for @duePrefix.
  ///
  /// In en, this message translates to:
  /// **'·  Due: {when}'**
  String duePrefix(String when);

  /// No description provided for @roleRealm.
  ///
  /// In en, this message translates to:
  /// **'Realm'**
  String get roleRealm;

  /// No description provided for @roleParcour.
  ///
  /// In en, this message translates to:
  /// **'Parcour'**
  String get roleParcour;

  /// No description provided for @roleObject.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get roleObject;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get languageSystem;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageChanged;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @moveObjectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Move to another parcour / slot (replaces target)'**
  String get moveObjectTooltip;

  /// No description provided for @moveParcourTooltip.
  ///
  /// In en, this message translates to:
  /// **'Move to another parcour (replaces target)'**
  String get moveParcourTooltip;

  /// No description provided for @studyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get studyTooltip;

  /// No description provided for @reviewAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get reviewAgain;

  /// No description provided for @reviewHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get reviewHard;

  /// No description provided for @reviewGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewGood;

  /// No description provided for @reviewEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get reviewEasy;

  /// No description provided for @statsRecallLine.
  ///
  /// In en, this message translates to:
  /// **'Recall (entries) · due {due} · new {n} · total {total}'**
  String statsRecallLine(int due, int n, int total);

  /// No description provided for @parcourRowRecallLine.
  ///
  /// In en, this message translates to:
  /// **'Recall · due {due} · new {n} · total {total}'**
  String parcourRowRecallLine(int due, int n, int total);

  /// No description provided for @realmNA.
  ///
  /// In en, this message translates to:
  /// **'Realm: N/A'**
  String get realmNA;

  /// No description provided for @realmPercent.
  ///
  /// In en, this message translates to:
  /// **'Realm: {percent}% (good {good} / active {active})'**
  String realmPercent(int percent, int good, int active);

  /// No description provided for @dialogMoveParcourTitle.
  ///
  /// In en, this message translates to:
  /// **'Move parcour'**
  String get dialogMoveParcourTitle;

  /// No description provided for @dialogMoveObjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Move object'**
  String get dialogMoveObjectTitle;

  /// No description provided for @originLabel.
  ///
  /// In en, this message translates to:
  /// **'From: {key}'**
  String originLabel(String key);

  /// No description provided for @moveParcourHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the parcour that will replace the destination (same number of object children).'**
  String get moveParcourHint;

  /// No description provided for @moveParcourBodyWarning.
  ///
  /// In en, this message translates to:
  /// **'The destination subtree is removed and replaced by the source. The source slot returns to the empty skeleton (L1…L20).'**
  String get moveParcourBodyWarning;

  /// No description provided for @destinationParcourLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination parcour'**
  String get destinationParcourLabel;

  /// No description provided for @moveObjectBodyWarning.
  ///
  /// In en, this message translates to:
  /// **'If the destination slot already has content, it is replaced. The gap in the source parcour is filled with the skeleton.'**
  String get moveObjectBodyWarning;

  /// No description provided for @slotLabel.
  ///
  /// In en, this message translates to:
  /// **'Slot (1–20)'**
  String get slotLabel;

  /// No description provided for @moveObjectHint.
  ///
  /// In en, this message translates to:
  /// **'Choose destination parcour and slot (seq). The object moves to Parent_O## for that seq.'**
  String get moveObjectHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @snackbarNoDestParcour.
  ///
  /// In en, this message translates to:
  /// **'No other parcour available as destination.'**
  String get snackbarNoDestParcour;

  /// No description provided for @snackbarParcourMoved.
  ///
  /// In en, this message translates to:
  /// **'Parcour moved: {from} → {to}'**
  String snackbarParcourMoved(String from, String to);

  /// No description provided for @snackbarNoParcoursUnderHub.
  ///
  /// In en, this message translates to:
  /// **'No parcours under PARCOUR_MAIN.'**
  String get snackbarNoParcoursUnderHub;

  /// No description provided for @snackbarObjectMoved.
  ///
  /// In en, this message translates to:
  /// **'Object moved: {obj} → {dest}'**
  String snackbarObjectMoved(String obj, String dest);

  /// No description provided for @snackbarNuclearError.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String snackbarNuclearError(String error);

  /// No description provided for @breadcrumbRoot.
  ///
  /// In en, this message translates to:
  /// **'R1'**
  String get breadcrumbRoot;

  /// No description provided for @breadcrumbParcours.
  ///
  /// In en, this message translates to:
  /// **'Parcours (R1)'**
  String get breadcrumbParcours;

  /// No description provided for @intentFrameSuffix.
  ///
  /// In en, this message translates to:
  /// **' · frame {focus}'**
  String intentFrameSuffix(String focus);

  /// No description provided for @intentDrawerWithFrame.
  ///
  /// In en, this message translates to:
  /// **'{mode} · frame {frame}'**
  String intentDrawerWithFrame(String mode, String frame);

  /// No description provided for @intentSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Mode → {mode}{frameSuffix} (3D viewer HUD)'**
  String intentSnackbar(String mode, String frameSuffix);

  /// No description provided for @keySeqLine.
  ///
  /// In en, this message translates to:
  /// **'key={key}  ·  seq={seq}'**
  String keySeqLine(String key, String seq);

  /// No description provided for @parcourReviewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Last Parcour Review: {rating}'**
  String parcourReviewTooltip(String rating);

  /// No description provided for @parcourReviewNoData.
  ///
  /// In en, this message translates to:
  /// **'no data'**
  String get parcourReviewNoData;

  /// No description provided for @timeReviewNever.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get timeReviewNever;

  /// No description provided for @timeReviewUpcoming.
  ///
  /// In en, this message translates to:
  /// **'upcoming'**
  String get timeReviewUpcoming;

  /// No description provided for @timeReviewToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get timeReviewToday;

  /// No description provided for @timeReviewYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get timeReviewYesterday;

  /// No description provided for @timeReviewDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String timeReviewDaysAgo(int count);

  /// No description provided for @timeReviewWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String timeReviewWeeksAgo(int count);

  /// No description provided for @timeReviewMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String timeReviewMonthsAgo(int count);

  /// No description provided for @timeReviewYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String timeReviewYearsAgo(int count);

  /// No description provided for @dueTagNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get dueTagNew;

  /// No description provided for @dueTagDue.
  ///
  /// In en, this message translates to:
  /// **'due'**
  String get dueTagDue;

  /// No description provided for @dueTagInHours.
  ///
  /// In en, this message translates to:
  /// **'in {h}h'**
  String dueTagInHours(int h);

  /// No description provided for @dueTagInDays.
  ///
  /// In en, this message translates to:
  /// **'in {d}d'**
  String dueTagInDays(int d);

  /// No description provided for @fibScheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Fib · no objects under this level'**
  String get fibScheduleEmpty;

  /// No description provided for @fibScheduleLine.
  ///
  /// In en, this message translates to:
  /// **'Fib · last: {prev} · next: {next}'**
  String fibScheduleLine(String prev, String next);

  /// No description provided for @fibOverdue.
  ///
  /// In en, this message translates to:
  /// **'overdue'**
  String get fibOverdue;

  /// No description provided for @fibRelPastMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m}m ago'**
  String fibRelPastMinutes(int m);

  /// No description provided for @fibRelPastHours.
  ///
  /// In en, this message translates to:
  /// **'{h}h ago'**
  String fibRelPastHours(int h);

  /// No description provided for @fibRelPastDays.
  ///
  /// In en, this message translates to:
  /// **'{d}d ago'**
  String fibRelPastDays(int d);

  /// No description provided for @fibRelFutureMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {m}m'**
  String fibRelFutureMinutes(int m);

  /// No description provided for @fibRelFutureHours.
  ///
  /// In en, this message translates to:
  /// **'in {h}h'**
  String fibRelFutureHours(int h);

  /// No description provided for @fibRelFutureDays.
  ///
  /// In en, this message translates to:
  /// **'in {d}d'**
  String fibRelFutureDays(int d);

  /// No description provided for @parcourFibDueDash.
  ///
  /// In en, this message translates to:
  /// **'due —'**
  String get parcourFibDueDash;

  /// No description provided for @parcourFibDueReady.
  ///
  /// In en, this message translates to:
  /// **'due'**
  String get parcourFibDueReady;

  /// No description provided for @parcourFibDueInDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String parcourFibDueInDaysCount(int count);

  /// No description provided for @parcourFibDueOverdue.
  ///
  /// In en, this message translates to:
  /// **'due overdue'**
  String get parcourFibDueOverdue;

  /// No description provided for @parcourFibDueIn.
  ///
  /// In en, this message translates to:
  /// **'due {when}'**
  String parcourFibDueIn(String when);

  /// No description provided for @parcourFibScoreDash.
  ///
  /// In en, this message translates to:
  /// **'score —'**
  String get parcourFibScoreDash;

  /// No description provided for @parcourFibScoreValue.
  ///
  /// In en, this message translates to:
  /// **'score {value}'**
  String parcourFibScoreValue(String value);

  /// No description provided for @parcourFibFullLine.
  ///
  /// In en, this message translates to:
  /// **'Parcour · fib {fibIndex} · {due} · {score}'**
  String parcourFibFullLine(int fibIndex, String due, String score);

  /// No description provided for @locusEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Locus editor'**
  String get locusEditorTitle;

  /// No description provided for @locusEditorAddBlockTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add block'**
  String get locusEditorAddBlockTooltip;

  /// No description provided for @locusEditorBlockParagraph.
  ///
  /// In en, this message translates to:
  /// **'Paragraph'**
  String get locusEditorBlockParagraph;

  /// No description provided for @locusEditorBlockLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get locusEditorBlockLink;

  /// No description provided for @locusEditorBlockImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get locusEditorBlockImage;

  /// No description provided for @locusEditorBlockCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get locusEditorBlockCard;

  /// No description provided for @locusEditorCardWordLabel.
  ///
  /// In en, this message translates to:
  /// **'Word / lemma'**
  String get locusEditorCardWordLabel;

  /// No description provided for @locusEditorCardImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Illustration (filename under assets)'**
  String get locusEditorCardImageLabel;

  /// No description provided for @locusEditorCardPhoneticLabel.
  ///
  /// In en, this message translates to:
  /// **'Phonetic / notes (file, e.g. ipa.txt)'**
  String get locusEditorCardPhoneticLabel;

  /// No description provided for @locusEditorCardAudioLabel.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation audio (ogg / mp3 / wav)'**
  String get locusEditorCardAudioLabel;

  /// No description provided for @locusEditorCardRelatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Related entry keys'**
  String get locusEditorCardRelatedLabel;

  /// No description provided for @locusEditorCardRelatedHint.
  ///
  /// In en, this message translates to:
  /// **'Comma or space separated (must exist in this realm)'**
  String get locusEditorCardRelatedHint;

  /// No description provided for @locusEditorEmptyBlocksHint.
  ///
  /// In en, this message translates to:
  /// **'No blocks yet. Add paragraph, link, image, or vocabulary card—or paste or drop an image.'**
  String get locusEditorEmptyBlocksHint;

  /// No description provided for @locusEditorUnknownRelatedKey.
  ///
  /// In en, this message translates to:
  /// **'Related key not found in this realm: {key}'**
  String locusEditorUnknownRelatedKey(String key);

  /// No description provided for @locusEditorSpatialTurnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Spatial turn (path to next frame in GateKeeper)'**
  String get locusEditorSpatialTurnTooltip;

  /// No description provided for @locusEditorSpatialStraight.
  ///
  /// In en, this message translates to:
  /// **'Straight'**
  String get locusEditorSpatialStraight;

  /// No description provided for @locusEditorSpatialLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get locusEditorSpatialLeft;

  /// No description provided for @locusEditorSpatialRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get locusEditorSpatialRight;

  /// No description provided for @locusEditorMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Locus settings, role, help'**
  String get locusEditorMenuTooltip;

  /// No description provided for @locusEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get locusEditorSave;

  /// No description provided for @locusEditorSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get locusEditorSaved;

  /// No description provided for @locusEditorSubtitleLine.
  ///
  /// In en, this message translates to:
  /// **'{role} · {turn}'**
  String locusEditorSubtitleLine(String role, String turn);

  /// No description provided for @locusEditorHelpMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Locus editor help'**
  String get locusEditorHelpMenuLabel;

  /// No description provided for @locusEditorHelpMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What this screen does and how it syncs with GateKeeper'**
  String get locusEditorHelpMenuSubtitle;

  /// No description provided for @locusEditorHelpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Using the locus editor'**
  String get locusEditorHelpDialogTitle;

  /// No description provided for @locusEditorDeleteMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete this locus'**
  String get locusEditorDeleteMenuLabel;

  /// No description provided for @placeRecallDrawerTitle.
  ///
  /// In en, this message translates to:
  /// **'Place recall'**
  String get placeRecallDrawerTitle;

  /// No description provided for @placeRecallDrawerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enables the crop gate in the 3D viewer (or use study mode place_recall). Needs recall_crop assets; three distractors come from siblings in the parcour when possible.'**
  String get placeRecallDrawerSubtitle;

  /// No description provided for @locusEditorDeleteMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes this entry and descendants from the database and realm files—not the whole database file.'**
  String get locusEditorDeleteMenuSubtitle;

  /// No description provided for @locusEditorDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete locus permanently'**
  String get locusEditorDeleteConfirmTitle;

  /// No description provided for @locusEditorDeleteConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'Removes this entry and all descendants from the realm database ({realmPath}), deletes matching rows in review/parcour tables, removes assets/snapshot/viewer/manifest files for those keys, then rebuilds snapshots.'**
  String locusEditorDeleteConfirmDescription(String realmPath);

  /// No description provided for @locusEditorDeleteConfirmDeletingLabel.
  ///
  /// In en, this message translates to:
  /// **'Deleting: {key}'**
  String locusEditorDeleteConfirmDeletingLabel(String key);

  /// No description provided for @locusEditorDeleteConfirmTypeInstruction.
  ///
  /// In en, this message translates to:
  /// **'This will delete the locus named above. To confirm, type the phrase below in the box—not your database key. It must match exactly, including spaces and capitals:'**
  String get locusEditorDeleteConfirmTypeInstruction;

  /// No description provided for @locusEditorDeleteConfirmPhraseExact.
  ///
  /// In en, this message translates to:
  /// **'Delete Node'**
  String get locusEditorDeleteConfirmPhraseExact;

  /// No description provided for @locusEditorDeleteConfirmFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Delete Node'**
  String get locusEditorDeleteConfirmFieldHint;

  /// No description provided for @locusEditorDeleteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get locusEditorDeleteConfirmButton;

  /// No description provided for @locusEditorHelpDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This screen edits one entry in the realm: blocks of text, links, images, and vocabulary cards.\n\nCognitive role — Realm (container), Parcour (a corridor of frames), or Object (what you read in the GateKeeper viewer). Children under a parcour become ordered frames along the 3D path.\n\nBlocks — Paragraphs can be plain text or study kinds: Place, Hint, Ridiculous story. Images pick a role: Content (viewer only), Collage (panels on the GateKeeper wall between frames), or Hero (the picture on the 3D frame). Quick Hero: focus an image block and press Ctrl/Cmd+H.\n\nCards — Word or lemma, illustration and audio files under assets for this key, optional phonetic notes file, and related entry keys that already exist in this realm.\n\nSpatial turn — For entries that are direct children of a parcour, set how the corridor continues toward the next frame (straight, left, right).\n\nPlace recall — On objects, turn on place recall when you want the GateKeeper place drill. Add an image with role Recall crop; the drill needs this frame plus three other objects in the realm with valid recall crops.\n\nPaste and files — Paste text or images with Ctrl+V / Cmd+V when focus is outside text fields. On desktop, drop .png / .jpg / .webp on the drop target.\n\nSave — Writes the database, copies assets, and refreshes viewer and snapshot outputs so GateKeeper can reload.'**
  String get locusEditorHelpDialogBody;

  /// No description provided for @sectionHelp.
  ///
  /// In en, this message translates to:
  /// **'HELP'**
  String get sectionHelp;

  /// No description provided for @helpGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How Alexandria works'**
  String get helpGuideTitle;

  /// No description provided for @helpGuideClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get helpGuideClose;

  /// No description provided for @helpGuideGkHint.
  ///
  /// In en, this message translates to:
  /// **'Press F1 in GateKeeper for this guide.'**
  String get helpGuideGkHint;

  /// No description provided for @helpGuideOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Big picture'**
  String get helpGuideOverviewTitle;

  /// No description provided for @helpGuideOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'Alexandria has two apps that share the same data folder. Library Build (LB) is where you edit the realm tree, locus content, images, and reviews. GateKeeper (GK) is the 3D corridor: you walk between frames and open the viewer. Both read the same SQLite database and assets; a small bridge folder tells GK which level and frame are active.'**
  String get helpGuideOverviewBody;

  /// No description provided for @helpGuideRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Realms, parcours, and objects'**
  String get helpGuideRolesTitle;

  /// No description provided for @helpGuideRolesBody.
  ///
  /// In en, this message translates to:
  /// **'The tree starts at ROOT, then realms (e.g. R1), the parcour hub (PARCOUR_MAIN), numbered parcours (P1…P20), and object slots under each parcour. Each row has a cognitive role: Realm (container), Parcour (a corridor of frames), or Object (a leaf you open for full content). In LB you assign roles when you create or edit entries. In GK, parcour levels show many frames along a path; object levels focus on one frame.'**
  String get helpGuideRolesBody;

  /// No description provided for @helpGuideContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Hero, collage, and body'**
  String get helpGuideContentTitle;

  /// No description provided for @helpGuideContentBody.
  ///
  /// In en, this message translates to:
  /// **'In the locus editor, images can be Viewer-only, Collage (panels on the GK wall between frames), or Hero (the picture on the 3D frame). Text blocks can carry place, hint, or ridiculous story for study. Saving updates files under assets/<key>/ and refreshes snapshots so GK can rebuild the corridor.'**
  String get helpGuideContentBody;

  /// No description provided for @helpGuideCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary cards'**
  String get helpGuideCardsTitle;

  /// No description provided for @helpGuideCardsBody.
  ///
  /// In en, this message translates to:
  /// **'Add a Card block for language-style entries: a large word, an illustration file under assets/<key>/, optional phonetic notes (.txt), optional pronunciation audio (ogg/mp3/wav), and related_to with other entry keys in this realm. In GateKeeper, related keys only change focus (same corridor); Back returns to the previous focus.'**
  String get helpGuideCardsBody;

  /// No description provided for @helpGuideLbTitle.
  ///
  /// In en, this message translates to:
  /// **'Library Build — what you can do'**
  String get helpGuideLbTitle;

  /// No description provided for @helpGuideLbBody.
  ///
  /// In en, this message translates to:
  /// **'Browse with the app bar and drawer: open any level, edit a locus (double-tap or edit), search objects, refresh snapshots. The drawer offers node PDF, parcour PDF, import from data-transfer, PAO tools, recall metrics export, language, realm folders, and navigation intent (explore / review / seek / drift — optionally tied to a focus locus for Hero-linked fields). The list shows recall due dates, review history, parcour review dots, and Fib schedule lines where applicable.'**
  String get helpGuideLbBody;

  /// No description provided for @helpGuideGkTitle.
  ///
  /// In en, this message translates to:
  /// **'GateKeeper — 3D realm'**
  String get helpGuideGkTitle;

  /// No description provided for @helpGuideGkBody.
  ///
  /// In en, this message translates to:
  /// **'Move with WASD, look with the mouse (Esc frees or recaptures the cursor). Click a frame to set focus for the viewer; use the on-screen viewer to enter a child level or go back to the parent. The top line shows navigation intent from LB. The corridor layout follows spatial turns you set per frame in LB (straight, left, right).'**
  String get helpGuideGkBody;

  /// No description provided for @helpGuideMetricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Metrics and reviews'**
  String get helpGuideMetricsTitle;

  /// No description provided for @helpGuideMetricsBody.
  ///
  /// In en, this message translates to:
  /// **'LB stores per-entry recall fields (next review, strength, counts) and parcour review ratings. Use the metrics page to export CSV. In the list, badges and tooltips summarize due state and last parcour review when you are under a parcour.'**
  String get helpGuideMetricsBody;

  /// No description provided for @helpGuideBridgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Bridge and sync'**
  String get helpGuideBridgeTitle;

  /// No description provided for @helpGuideBridgeBody.
  ///
  /// In en, this message translates to:
  /// **'Files under data/…/bridge/ carry context_key (which snapshot level GK loads), focus_key (which locus the viewer highlights), navigation_intent.txt, and optional refresh flags. After edits in LB, use Refresh so snapshots and manifests stay aligned; GK picks up changes when those files update.'**
  String get helpGuideBridgeBody;

  /// No description provided for @usageBandAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get usageBandAll;

  /// No description provided for @usageBandCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get usageBandCore;

  /// No description provided for @usageBandActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get usageBandActive;

  /// No description provided for @usageBandSeek.
  ///
  /// In en, this message translates to:
  /// **'Seek'**
  String get usageBandSeek;

  /// No description provided for @usageBandSubtitleCore.
  ///
  /// In en, this message translates to:
  /// **'Core usage — highest engagement'**
  String get usageBandSubtitleCore;

  /// No description provided for @usageBandSubtitleActive.
  ///
  /// In en, this message translates to:
  /// **'Recurrent use'**
  String get usageBandSubtitleActive;

  /// No description provided for @usageBandSubtitleSeek.
  ///
  /// In en, this message translates to:
  /// **'Exploration / long tail'**
  String get usageBandSubtitleSeek;

  /// No description provided for @realmShelfPopupCore.
  ///
  /// In en, this message translates to:
  /// **'Core — core priority'**
  String get realmShelfPopupCore;

  /// No description provided for @realmShelfPopupActive.
  ///
  /// In en, this message translates to:
  /// **'Active — regular use'**
  String get realmShelfPopupActive;

  /// No description provided for @realmShelfPopupSeek.
  ///
  /// In en, this message translates to:
  /// **'Seek — long tail'**
  String get realmShelfPopupSeek;

  /// No description provided for @realmAdminFabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create new realm'**
  String get realmAdminFabCreate;

  /// No description provided for @realmAdminTabFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get realmAdminTabFolders;

  /// No description provided for @realmAdminTabShelves.
  ///
  /// In en, this message translates to:
  /// **'Shelves'**
  String get realmAdminTabShelves;

  /// No description provided for @realmAdminTooltipEmptySubfolder.
  ///
  /// In en, this message translates to:
  /// **'Create empty folder (organization only, no realm)'**
  String get realmAdminTooltipEmptySubfolder;

  /// No description provided for @realmAdminTooltipRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh list'**
  String get realmAdminTooltipRefresh;

  /// No description provided for @realmAdminTooltipOpenExplorer.
  ///
  /// In en, this message translates to:
  /// **'Open this folder in file explorer'**
  String get realmAdminTooltipOpenExplorer;

  /// No description provided for @realmAdminTooltipCreateSeed.
  ///
  /// In en, this message translates to:
  /// **'Create realm seed from active realm (data/realm_seed/)'**
  String get realmAdminTooltipCreateSeed;

  /// No description provided for @realmAdminTooltipNuclear.
  ///
  /// In en, this message translates to:
  /// **'Clear realm libraries (irreversible) — PAO & Match cards are preserved'**
  String get realmAdminTooltipNuclear;

  /// No description provided for @realmAdminCleanupMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear PAO or Match cards data only'**
  String get realmAdminCleanupMenuTooltip;

  /// No description provided for @realmAdminCleanPaoTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear PAO data'**
  String get realmAdminCleanPaoTitle;

  /// No description provided for @realmAdminCleanPaoBody.
  ///
  /// In en, this message translates to:
  /// **'Removes PAO rows in the active realm database and non-template JSON files under data/pao/. Realm tree and Match cards are not affected.'**
  String get realmAdminCleanPaoBody;

  /// No description provided for @realmAdminCleanPaoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear PAO'**
  String get realmAdminCleanPaoConfirm;

  /// No description provided for @realmAdminCleanPaoSnackbar.
  ///
  /// In en, this message translates to:
  /// **'PAO data cleared.'**
  String get realmAdminCleanPaoSnackbar;

  /// No description provided for @realmAdminCleanMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Match cards data'**
  String get realmAdminCleanMatchTitle;

  /// No description provided for @realmAdminCleanMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes all match-card decks, pairs, review state, and files under assets/lb_match_cards/ for the active realm. Irreversible.'**
  String get realmAdminCleanMatchBody;

  /// No description provided for @realmAdminCleanMatchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear Match cards'**
  String get realmAdminCleanMatchConfirm;

  /// No description provided for @realmAdminCleanMatchSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Match cards data cleared.'**
  String get realmAdminCleanMatchSnackbar;

  /// No description provided for @realmAdminMatchCardsTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Match cards'**
  String get realmAdminMatchCardsTileTitle;

  /// No description provided for @realmAdminMatchCardsTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Decks and image–text pairs for the active realm. Opens the Match cards view on the Library home.'**
  String get realmAdminMatchCardsTileSubtitle;

  /// No description provided for @realmAdminTooltipOpenRealmFolder.
  ///
  /// In en, this message translates to:
  /// **'Open realm folder in explorer'**
  String get realmAdminTooltipOpenRealmFolder;

  /// No description provided for @realmAdminTooltipMoveShelf.
  ///
  /// In en, this message translates to:
  /// **'Change shelf assignment'**
  String get realmAdminTooltipMoveShelf;

  /// No description provided for @realmAdminTooltipEnterSubfolders.
  ///
  /// In en, this message translates to:
  /// **'Enter subfolders'**
  String get realmAdminTooltipEnterSubfolders;

  /// No description provided for @realmAdminTooltipShelfMenu.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get realmAdminTooltipShelfMenu;

  /// No description provided for @realmAdminTooltipMoveRealm.
  ///
  /// In en, this message translates to:
  /// **'Move or rename realm on disk'**
  String get realmAdminTooltipMoveRealm;

  /// No description provided for @realmAdminMoveRealmMenu.
  ///
  /// In en, this message translates to:
  /// **'Move to path…'**
  String get realmAdminMoveRealmMenu;

  /// No description provided for @realmAdminMoveRealmTitle.
  ///
  /// In en, this message translates to:
  /// **'Move realm'**
  String get realmAdminMoveRealmTitle;

  /// No description provided for @realmAdminMoveRealmBody.
  ///
  /// In en, this message translates to:
  /// **'New location under data/realms/. The destination must not exist. The database is closed briefly.'**
  String get realmAdminMoveRealmBody;

  /// No description provided for @realmAdminMoveRealmTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'New path (e.g. Lab/my_course)'**
  String get realmAdminMoveRealmTargetLabel;

  /// No description provided for @realmAdminMoveRealmOk.
  ///
  /// In en, this message translates to:
  /// **'Moved to {path}'**
  String realmAdminMoveRealmOk(String path);

  /// No description provided for @realmAdminMoveRealmFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not move (folder exists or files in use).'**
  String get realmAdminMoveRealmFailed;

  /// No description provided for @realmAdminMoveRealmButton.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get realmAdminMoveRealmButton;

  /// No description provided for @realmAdminShelvesIntro.
  ///
  /// In en, this message translates to:
  /// **'Only one active realm at a time (GateKeeper reads data/active_realm.txt). Core / Active / Seek are priority shelves (not physical folders).'**
  String get realmAdminShelvesIntro;

  /// No description provided for @realmAdminActiveLine.
  ///
  /// In en, this message translates to:
  /// **'Active: {id}'**
  String realmAdminActiveLine(String id);

  /// No description provided for @realmAdminTierHeaderCore.
  ///
  /// In en, this message translates to:
  /// **'Most important / in use'**
  String get realmAdminTierHeaderCore;

  /// No description provided for @realmAdminTierHeaderActive.
  ///
  /// In en, this message translates to:
  /// **'Regular work realms'**
  String get realmAdminTierHeaderActive;

  /// No description provided for @realmAdminTierHeaderSeek.
  ///
  /// In en, this message translates to:
  /// **'Long tail and experiments'**
  String get realmAdminTierHeaderSeek;

  /// No description provided for @realmAdminEmptyTier.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get realmAdminEmptyTier;

  /// No description provided for @realmAdminFolderIntro.
  ///
  /// In en, this message translates to:
  /// **'Lists what exists on disk under data/realms/ from the resolved repo root (not invented). Realm = folder with alexandria.db. Moving many folders: prefer apps closed if the DB is in use.'**
  String get realmAdminFolderIntro;

  /// No description provided for @realmAdminRepoRootCaption.
  ///
  /// In en, this message translates to:
  /// **'Repo root (ALEXANDRIA_ROOT env, or search from the .exe, or C:\\\\Alexandria if it has data/realms):'**
  String get realmAdminRepoRootCaption;

  /// No description provided for @realmAdminRealmsFolderCaption.
  ///
  /// In en, this message translates to:
  /// **'Realms folder (must match what the explorer opens):'**
  String get realmAdminRealmsFolderCaption;

  /// No description provided for @realmAdminFolderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty folder.'**
  String get realmAdminFolderEmpty;

  /// No description provided for @realmAdminLeafFolderWithoutDb.
  ///
  /// In en, this message translates to:
  /// **'Folder without alexandria.db or subfolders'**
  String get realmAdminLeafFolderWithoutDb;

  /// No description provided for @realmAdminRootGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Root (no subfolder)'**
  String get realmAdminRootGroupLabel;

  /// No description provided for @realmAdminDataRealmsChip.
  ///
  /// In en, this message translates to:
  /// **'data/realms'**
  String get realmAdminDataRealmsChip;

  /// No description provided for @realmAdminShelfLabel.
  ///
  /// In en, this message translates to:
  /// **'Shelf: {tier}'**
  String realmAdminShelfLabel(String tier);

  /// No description provided for @objectSearchUsageCaption.
  ///
  /// In en, this message translates to:
  /// **'Usage views: Core · Active · Seek (same loci; does not change structure).'**
  String get objectSearchUsageCaption;

  /// No description provided for @realmAdminExplorerMissingFolder.
  ///
  /// In en, this message translates to:
  /// **'That folder does not exist on disk.\nResolved root: {root}\nAttempted path:\n{path}'**
  String realmAdminExplorerMissingFolder(String root, String path);

  /// No description provided for @realmAdminExplorerError.
  ///
  /// In en, this message translates to:
  /// **'Explorer: {error}\n{path}'**
  String realmAdminExplorerError(String error, String path);

  /// No description provided for @realmAdminFolderMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing folder:\n{path}'**
  String realmAdminFolderMissing(String path);

  /// No description provided for @realmAdminOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open: {error}'**
  String realmAdminOpenFailed(String error);

  /// No description provided for @realmAdminEmptyFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get realmAdminEmptyFolderDialogTitle;

  /// No description provided for @realmAdminEmptyFolderBody.
  ///
  /// In en, this message translates to:
  /// **'Organization only (no alexandria.db). Created under:\n{path}'**
  String realmAdminEmptyFolderBody(String path);

  /// No description provided for @realmAdminEmptyFolderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get realmAdminEmptyFolderNameLabel;

  /// No description provided for @realmAdminEmptyFolderNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lab or Clients_2026'**
  String get realmAdminEmptyFolderNameHint;

  /// No description provided for @realmAdminEmptyFolderNameHelper.
  ///
  /// In en, this message translates to:
  /// **'One segment; no /'**
  String get realmAdminEmptyFolderNameHelper;

  /// No description provided for @realmAdminSnackbarSingleSegment.
  ///
  /// In en, this message translates to:
  /// **'Use a single name without /'**
  String get realmAdminSnackbarSingleSegment;

  /// No description provided for @realmAdminSnackbarSubfolderCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create (already a realm with DB there, or invalid name?).'**
  String get realmAdminSnackbarSubfolderCreateFailed;

  /// No description provided for @realmAdminSnackbarFolderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder created'**
  String get realmAdminSnackbarFolderCreated;

  /// No description provided for @realmDialogNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New realm'**
  String get realmDialogNewTitle;

  /// No description provided for @realmDialogFolderOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional folder'**
  String get realmDialogFolderOptionalLabel;

  /// No description provided for @realmDialogFolderHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lab or Clients/2026'**
  String get realmDialogFolderHint;

  /// No description provided for @realmDialogFolderHelper.
  ///
  /// In en, this message translates to:
  /// **'Under data/realms/; empty = root. Folders tab fills from current view.'**
  String get realmDialogFolderHelper;

  /// No description provided for @realmDialogIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Realm id'**
  String get realmDialogIdLabel;

  /// No description provided for @realmDialogIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. my_realm'**
  String get realmDialogIdHint;

  /// No description provided for @realmDialogIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Single name; no /'**
  String get realmDialogIdHelper;

  /// No description provided for @realmDialogTemplateCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy from template'**
  String get realmDialogTemplateCopyTitle;

  /// No description provided for @realmDialogTemplateCopySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicates DB, bridge, snapshot, assets… from another realm.'**
  String get realmDialogTemplateCopySubtitle;

  /// No description provided for @realmDialogEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty (same architecture)'**
  String get realmDialogEmptyTitle;

  /// No description provided for @realmDialogEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same fixed tree (20 parcours + 400 objects under PARCOUR_MAIN), but no locus text, no recall/review, empty assets.'**
  String get realmDialogEmptySubtitle;

  /// No description provided for @realmDialogTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get realmDialogTemplateLabel;

  /// No description provided for @realmDialogCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get realmDialogCreate;

  /// No description provided for @realmDialogIdInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Realm id cannot contain / or \\.'**
  String get realmDialogIdInvalidChars;

  /// No description provided for @realmSnackbarCreateEmptyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create empty (duplicate path or write error?).'**
  String get realmSnackbarCreateEmptyFailed;

  /// No description provided for @realmSnackbarDuplicateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy (missing template, duplicate path?).'**
  String get realmSnackbarDuplicateFailed;

  /// No description provided for @realmSnackbarActiveRealm.
  ///
  /// In en, this message translates to:
  /// **'Active realm: {id}'**
  String realmSnackbarActiveRealm(String id);

  /// No description provided for @realmAdminNuclearTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get realmAdminNuclearTitle;

  /// No description provided for @realmAdminNuclearDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'All realm folders under data/realms/ will be removed (assets, bridge, snapshots, manifests, realm_shelf.json). The repo folder data/pao/ is not deleted.\n\nPAO and Match cards from the active realm are copied into the new default database and assets.\n\nOnly a fresh base will remain at:\ndata/realms/default/alexandria.db\n\nThe realm seed snapshot will also be written to:\ndata/realm_seed/alexandria.db\n\nActive realm: default.\n\nClose the 3D viewer if it is open (file locking).\n\nTo confirm, type exactly:'**
  String get realmAdminNuclearDialogIntro;

  /// No description provided for @realmAdminConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get realmAdminConfirmLabel;

  /// No description provided for @realmAdminPhraseMismatch.
  ///
  /// In en, this message translates to:
  /// **'The phrase does not match exactly.'**
  String get realmAdminPhraseMismatch;

  /// No description provided for @realmAdminNuclearButton.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get realmAdminNuclearButton;

  /// No description provided for @realmAdminNuclearSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Realm libraries cleared; PAO & Match cards restored into default. default/alexandria.db + data/realm_seed/alexandria.db. Run Library build or reopen the app to regenerate snapshot/viewer.'**
  String get realmAdminNuclearSuccessSnackbar;

  /// No description provided for @realmSeedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create realm seed'**
  String get realmSeedDialogTitle;

  /// No description provided for @realmSeedDialogBody.
  ///
  /// In en, this message translates to:
  /// **'The active realm ({realm}) will be sanitized, Library build will run, and the database will be copied to:\ndata/realm_seed/alexandria.db\n\nClose GateKeeper if it is open.'**
  String realmSeedDialogBody(String realm);

  /// No description provided for @realmSeedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get realmSeedConfirm;

  /// No description provided for @realmSeedSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Realm seed saved: data/realm_seed/alexandria.db'**
  String get realmSeedSavedSnackbar;

  /// No description provided for @realmSeedErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Realm seed:'**
  String get realmSeedErrorPrefix;

  /// No description provided for @objectSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search objects (FTS5)'**
  String get objectSearchTitle;

  /// No description provided for @objectSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Locus title or body text…'**
  String get objectSearchHint;

  /// No description provided for @objectSearchCardReaderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Node card reader (full info)'**
  String get objectSearchCardReaderTooltip;

  /// No description provided for @objectSearchNoObjects.
  ///
  /// In en, this message translates to:
  /// **'No objects in the database.'**
  String get objectSearchNoObjects;

  /// No description provided for @objectSearchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches.'**
  String get objectSearchNoMatches;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
