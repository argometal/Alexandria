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

  /// No description provided for @paoEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'PAO (00–99)'**
  String get paoEditorTitle;

  /// No description provided for @paoEditorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Two-digit system · import / export JSON'**
  String get paoEditorSubtitle;

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
  /// **'Each pair: lemma (native script), optional transliteration, optional meaning (gloss), and image. route_key is for future “along a route”; FSRS table exists but scheduling is not implemented.'**
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

  /// No description provided for @goGameScoreLine.
  ///
  /// In en, this message translates to:
  /// **'Black {blackPt} — White {whitePt} (komi +{komi})'**
  String goGameScoreLine(String blackPt, String whitePt, String komi);

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
  /// **'Navigation intent'**
  String get navigationIntentTitle;

  /// No description provided for @navigationIntentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Explore / review / seek / drift mode. When an object is in focus, it is saved as a frame: place, hint and ridiculous story are tied to that locus Hero.'**
  String get navigationIntentTooltip;

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
  /// **'Intent → {mode}{frameSuffix} (HUD GateKeeper)'**
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

  /// No description provided for @locusEditorPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste: Ctrl+V. Image roles: Viewer / Collage / Hero. Quick hero: focus image + Ctrl/Cmd+H. More: menu ☰'**
  String get locusEditorPasteHint;

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
  /// **'Delete all data (irreversible)'**
  String get realmAdminTooltipNuclear;

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
  /// **'All realms, assets, bridge, snapshots, manifests, PAO under data/pao, and realm_shelf.json will be deleted.\n\nOnly a new base will remain at:\ndata/realms/default/alexandria.db\n\nThe realm seed snapshot will also be written to:\ndata/realm_seed/alexandria.db\n\nActive realm: default.\n\nClose GateKeeper if it is open (file locking).\n\nTo confirm, type exactly:'**
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
  /// **'Data cleared: default/alexandria.db + data/realm_seed/alexandria.db. Run Library build or reopen the app to regenerate snapshot/viewer.'**
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
