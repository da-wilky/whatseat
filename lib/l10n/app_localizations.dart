import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'WhatsEat'**
  String get appTitle;

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get yesterday;

  /// No description provided for @pickDate.
  ///
  /// In de, this message translates to:
  /// **'Datum wählen'**
  String get pickDate;

  /// No description provided for @export.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get export;

  /// No description provided for @templates.
  ///
  /// In de, this message translates to:
  /// **'Vorlagen'**
  String get templates;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @addEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag'**
  String get addEntry;

  /// No description provided for @newEntry.
  ///
  /// In de, this message translates to:
  /// **'Neuer Eintrag'**
  String get newEntry;

  /// No description provided for @editEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag bearbeiten'**
  String get editEntry;

  /// No description provided for @eatAgain.
  ///
  /// In de, this message translates to:
  /// **'Wieder essen'**
  String get eatAgain;

  /// No description provided for @reuseHint.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Vorlagen und zuletzt gegessene Mahlzeiten erscheinen hier, damit du sie mit einem Tipp erneut eintragen kannst.'**
  String get reuseHint;

  /// No description provided for @emptyDay.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts eingetragen'**
  String get emptyDay;

  /// No description provided for @emptyDayHint.
  ///
  /// In de, this message translates to:
  /// **'Trage alles ein, was du isst und trinkst – am besten direkt nach dem Essen.'**
  String get emptyDayHint;

  /// No description provided for @dayNote.
  ///
  /// In de, this message translates to:
  /// **'Tagesnotiz'**
  String get dayNote;

  /// No description provided for @dayNoteAdd.
  ///
  /// In de, this message translates to:
  /// **'Tagesnotiz hinzufügen'**
  String get dayNoteAdd;

  /// No description provided for @dayNoteHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Diät oder Krankheit an diesem Tag'**
  String get dayNoteHint;

  /// No description provided for @noteDiet.
  ///
  /// In de, this message translates to:
  /// **'Diät'**
  String get noteDiet;

  /// No description provided for @noteSick.
  ///
  /// In de, this message translates to:
  /// **'Krank'**
  String get noteSick;

  /// No description provided for @entryDeleted.
  ///
  /// In de, this message translates to:
  /// **'Eintrag gelöscht'**
  String get entryDeleted;

  /// No description provided for @undo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get undo;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get rename;

  /// No description provided for @pin.
  ///
  /// In de, this message translates to:
  /// **'Anheften'**
  String get pin;

  /// No description provided for @other.
  ///
  /// In de, this message translates to:
  /// **'Andere …'**
  String get other;

  /// No description provided for @yes.
  ///
  /// In de, this message translates to:
  /// **'ja'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In de, this message translates to:
  /// **'nein'**
  String get no;

  /// No description provided for @notSet.
  ///
  /// In de, this message translates to:
  /// **'nicht angegeben'**
  String get notSet;

  /// No description provided for @deleteEntryQuestion.
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen?'**
  String get deleteEntryQuestion;

  /// No description provided for @discardQuestion.
  ///
  /// In de, this message translates to:
  /// **'Änderungen verwerfen?'**
  String get discardQuestion;

  /// No description provided for @discard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In de, this message translates to:
  /// **'Weiter bearbeiten'**
  String get keepEditing;

  /// No description provided for @saveAsTemplate.
  ///
  /// In de, this message translates to:
  /// **'Als Vorlage speichern'**
  String get saveAsTemplate;

  /// No description provided for @templateName.
  ///
  /// In de, this message translates to:
  /// **'Name der Vorlage'**
  String get templateName;

  /// No description provided for @templateSaved.
  ///
  /// In de, this message translates to:
  /// **'Vorlage gespeichert'**
  String get templateSaved;

  /// No description provided for @templateDeleted.
  ///
  /// In de, this message translates to:
  /// **'Vorlage gelöscht'**
  String get templateDeleted;

  /// No description provided for @templatesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Vorlagen.\nIm Eintrag über ⋮ → „Als Vorlage speichern“ anlegen. Beim Verwenden übernimmt die Vorlage automatisch deine letzten Angaben.'**
  String get templatesEmpty;

  /// No description provided for @fromTemplateHint.
  ///
  /// In de, this message translates to:
  /// **'Aus Vorlage – beim Speichern wird die Vorlage mit diesen Angaben aktualisiert.'**
  String get fromTemplateHint;

  /// No description provided for @needOneItem.
  ///
  /// In de, this message translates to:
  /// **'Bitte mindestens ein Lebensmittel oder Getränk eintragen.'**
  String get needOneItem;

  /// No description provided for @sectionMeal.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit'**
  String get sectionMeal;

  /// No description provided for @mealBreakfast.
  ///
  /// In de, this message translates to:
  /// **'Frühstück'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In de, this message translates to:
  /// **'Mittagessen'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In de, this message translates to:
  /// **'Abendessen'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In de, this message translates to:
  /// **'Snack'**
  String get mealSnack;

  /// No description provided for @timeFrom.
  ///
  /// In de, this message translates to:
  /// **'von'**
  String get timeFrom;

  /// No description provided for @timeTo.
  ///
  /// In de, this message translates to:
  /// **'bis'**
  String get timeTo;

  /// No description provided for @timeToAdd.
  ///
  /// In de, this message translates to:
  /// **'bis …'**
  String get timeToAdd;

  /// No description provided for @sectionFood.
  ///
  /// In de, this message translates to:
  /// **'Lebensmittel'**
  String get sectionFood;

  /// No description provided for @amount.
  ///
  /// In de, this message translates to:
  /// **'Menge'**
  String get amount;

  /// No description provided for @foodHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Vollkornbrot'**
  String get foodHint;

  /// No description provided for @addItem.
  ///
  /// In de, this message translates to:
  /// **'Weiteres hinzufügen'**
  String get addItem;

  /// No description provided for @lastAmount.
  ///
  /// In de, this message translates to:
  /// **'zuletzt: {amount}'**
  String lastAmount(String amount);

  /// No description provided for @withWhom.
  ///
  /// In de, this message translates to:
  /// **'Mit wem'**
  String get withWhom;

  /// No description provided for @withWhomDefaults.
  ///
  /// In de, this message translates to:
  /// **'allein|Familie|Partner:in|Freunde|Kolleg:innen'**
  String get withWhomDefaults;

  /// No description provided for @sectionBefore.
  ///
  /// In de, this message translates to:
  /// **'Vor dem Essen'**
  String get sectionBefore;

  /// No description provided for @hunger.
  ///
  /// In de, this message translates to:
  /// **'Hunger'**
  String get hunger;

  /// No description provided for @appetiteFor.
  ///
  /// In de, this message translates to:
  /// **'Appetit auf'**
  String get appetiteFor;

  /// No description provided for @situationBefore.
  ///
  /// In de, this message translates to:
  /// **'Situation, Gedanken, Gefühle'**
  String get situationBefore;

  /// No description provided for @sectionAfter.
  ///
  /// In de, this message translates to:
  /// **'Nach dem Essen'**
  String get sectionAfter;

  /// No description provided for @satiety.
  ///
  /// In de, this message translates to:
  /// **'Satt'**
  String get satiety;

  /// No description provided for @situationAfter.
  ///
  /// In de, this message translates to:
  /// **'Situation, Gedanken, Gefühle'**
  String get situationAfter;

  /// No description provided for @sectionBehaviour.
  ///
  /// In de, this message translates to:
  /// **'Essanfall & Maßnahmen'**
  String get sectionBehaviour;

  /// No description provided for @binge.
  ///
  /// In de, this message translates to:
  /// **'Essanfall'**
  String get binge;

  /// No description provided for @bingeHint.
  ///
  /// In de, this message translates to:
  /// **'Kontrollverlust beim Essen'**
  String get bingeHint;

  /// No description provided for @measures.
  ///
  /// In de, this message translates to:
  /// **'Gewichtsregulierende Maßnahmen'**
  String get measures;

  /// No description provided for @measureDefaults.
  ///
  /// In de, this message translates to:
  /// **'Sport|Erbrechen|Abführmittel'**
  String get measureDefaults;

  /// No description provided for @general.
  ///
  /// In de, this message translates to:
  /// **'Allgemein'**
  String get general;

  /// No description provided for @patientName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get patientName;

  /// No description provided for @patientNameHint.
  ///
  /// In de, this message translates to:
  /// **'Erscheint im PDF-Protokoll'**
  String get patientNameHint;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In de, this message translates to:
  /// **'Systemsprache'**
  String get languageSystem;

  /// No description provided for @security.
  ///
  /// In de, this message translates to:
  /// **'Sicherheit'**
  String get security;

  /// No description provided for @appLock.
  ///
  /// In de, this message translates to:
  /// **'App-Sperre'**
  String get appLock;

  /// No description provided for @appLockHint.
  ///
  /// In de, this message translates to:
  /// **'PIN beim Öffnen; blockiert Screenshots'**
  String get appLockHint;

  /// No description provided for @biometric.
  ///
  /// In de, this message translates to:
  /// **'Fingerabdruck / Face ID'**
  String get biometric;

  /// No description provided for @biometricConfirm.
  ///
  /// In de, this message translates to:
  /// **'Biometrisches Entsperren bestätigen'**
  String get biometricConfirm;

  /// No description provided for @lockTimeout.
  ///
  /// In de, this message translates to:
  /// **'Sperren nach'**
  String get lockTimeout;

  /// No description provided for @lockImmediately.
  ///
  /// In de, this message translates to:
  /// **'Sofort'**
  String get lockImmediately;

  /// No description provided for @lockAfterMinutes.
  ///
  /// In de, this message translates to:
  /// **'{minutes, plural, =1{1 Minute} other{{minutes} Minuten}}'**
  String lockAfterMinutes(int minutes);

  /// No description provided for @pinChange.
  ///
  /// In de, this message translates to:
  /// **'PIN ändern'**
  String get pinChange;

  /// No description provided for @encryptionInfo.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten werden verschlüsselt auf diesem Gerät gespeichert.'**
  String get encryptionInfo;

  /// No description provided for @lockTitle.
  ///
  /// In de, this message translates to:
  /// **'WhatsEat ist gesperrt'**
  String get lockTitle;

  /// No description provided for @unlockReason.
  ///
  /// In de, this message translates to:
  /// **'WhatsEat entsperren'**
  String get unlockReason;

  /// No description provided for @pinEnter.
  ///
  /// In de, this message translates to:
  /// **'PIN eingeben'**
  String get pinEnter;

  /// No description provided for @pinWrong.
  ///
  /// In de, this message translates to:
  /// **'Falsche PIN'**
  String get pinWrong;

  /// No description provided for @pinChoose.
  ///
  /// In de, this message translates to:
  /// **'PIN festlegen'**
  String get pinChoose;

  /// No description provided for @pinRepeat.
  ///
  /// In de, this message translates to:
  /// **'PIN wiederholen'**
  String get pinRepeat;

  /// No description provided for @pinLengthHint.
  ///
  /// In de, this message translates to:
  /// **'4–6 Ziffern, dann ✓'**
  String get pinLengthHint;

  /// No description provided for @pinMismatch.
  ///
  /// In de, this message translates to:
  /// **'PINs stimmen nicht überein – bitte erneut'**
  String get pinMismatch;

  /// No description provided for @data.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get data;

  /// No description provided for @backupCreate.
  ///
  /// In de, this message translates to:
  /// **'Backup erstellen'**
  String get backupCreate;

  /// No description provided for @backupWarning.
  ///
  /// In de, this message translates to:
  /// **'Am besten mit Passwort verschlüsselt'**
  String get backupWarning;

  /// No description provided for @backupRestore.
  ///
  /// In de, this message translates to:
  /// **'Backup wiederherstellen'**
  String get backupRestore;

  /// No description provided for @backupRestoreHint.
  ///
  /// In de, this message translates to:
  /// **'Wird mit vorhandenen Daten zusammengeführt'**
  String get backupRestoreHint;

  /// No description provided for @backupImported.
  ///
  /// In de, this message translates to:
  /// **'{count} Datensätze übernommen'**
  String backupImported(int count);

  /// No description provided for @backupInvalid.
  ///
  /// In de, this message translates to:
  /// **'Backup konnte nicht gelesen werden: {error}'**
  String backupInvalid(String error);

  /// No description provided for @exportRange.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum'**
  String get exportRange;

  /// No description provided for @lastDays.
  ///
  /// In de, this message translates to:
  /// **'Letzte {days} Tage'**
  String lastDays(int days);

  /// No description provided for @customRange.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum wählen'**
  String get customRange;

  /// No description provided for @exportPdf.
  ///
  /// In de, this message translates to:
  /// **'PDF-Protokoll ansehen & teilen'**
  String get exportPdf;

  /// No description provided for @exportPdfHint.
  ///
  /// In de, this message translates to:
  /// **'Eine Seite pro Tag, im Format des Essprotokolls.'**
  String get exportPdfHint;

  /// No description provided for @exportCsv.
  ///
  /// In de, this message translates to:
  /// **'Als CSV teilen'**
  String get exportCsv;

  /// No description provided for @protocolTitle.
  ///
  /// In de, this message translates to:
  /// **'Essprotokoll'**
  String get protocolTitle;

  /// No description provided for @pdfName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get pdfName;

  /// No description provided for @pdfDate.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get pdfDate;

  /// No description provided for @colMeal.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit\nvon … bis …'**
  String get colMeal;

  /// No description provided for @colMealType.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit'**
  String get colMealType;

  /// No description provided for @colWithWhom.
  ///
  /// In de, this message translates to:
  /// **'Mit wem'**
  String get colWithWhom;

  /// No description provided for @colSituationBefore.
  ///
  /// In de, this message translates to:
  /// **'Situation vor dem Essen, Gedanken, Gefühle, Appetit auf'**
  String get colSituationBefore;

  /// No description provided for @colHunger.
  ///
  /// In de, this message translates to:
  /// **'Hunger (in %)'**
  String get colHunger;

  /// No description provided for @colAmount.
  ///
  /// In de, this message translates to:
  /// **'Menge'**
  String get colAmount;

  /// No description provided for @colFood.
  ///
  /// In de, this message translates to:
  /// **'Lebensmittel/ Getränk'**
  String get colFood;

  /// No description provided for @colSatiety.
  ///
  /// In de, this message translates to:
  /// **'Satt (in %)'**
  String get colSatiety;

  /// No description provided for @colBinge.
  ///
  /// In de, this message translates to:
  /// **'Essanfall (ja/nein)'**
  String get colBinge;

  /// No description provided for @colMeasures.
  ///
  /// In de, this message translates to:
  /// **'Gewichtsregulierende Maßnahmen (z. B. Sport, Erbrechen, Abführmittel)'**
  String get colMeasures;

  /// No description provided for @colSituationAfter.
  ///
  /// In de, this message translates to:
  /// **'Situation nach dem Essen, Gedanken, Gefühle'**
  String get colSituationAfter;

  /// No description provided for @unitDefs.
  ///
  /// In de, this message translates to:
  /// **'Stück/Stück|Scheibe/Scheiben|Portion/Portionen|Tasse/Tassen|Glas/Gläser|Becher/Becher|Schüssel/Schüsseln|Teller/Teller|EL/EL|TL/TL|Handvoll/Handvoll|Riegel/Riegel|Flasche/Flaschen|g/g|ml/ml'**
  String get unitDefs;

  /// No description provided for @unit.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get unit;

  /// No description provided for @quantityHint.
  ///
  /// In de, this message translates to:
  /// **'Anz.'**
  String get quantityHint;

  /// No description provided for @newUnit.
  ///
  /// In de, this message translates to:
  /// **'Neue Einheit …'**
  String get newUnit;

  /// No description provided for @pinBlocked.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche – erneut in {seconds} s'**
  String pinBlocked(int seconds);

  /// No description provided for @pinConfirm.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle PIN bestätigen'**
  String get pinConfirm;

  /// No description provided for @recoveryTitle.
  ///
  /// In de, this message translates to:
  /// **'Daten nicht lesbar'**
  String get recoveryTitle;

  /// No description provided for @recoveryBody.
  ///
  /// In de, this message translates to:
  /// **'Die verschlüsselten Daten auf diesem Gerät lassen sich nicht öffnen – meist, weil der Schlüssel im sicheren Speicher des Geräts verloren gegangen ist. Ohne ihn sind die Daten nicht wiederherstellbar.\n\nVersuche es zuerst erneut (z. B. nach einem Neustart). Hilft das nicht, kannst du ein Backup einspielen oder neu beginnen.'**
  String get recoveryBody;

  /// No description provided for @recoveryRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get recoveryRetry;

  /// No description provided for @recoveryStartFresh.
  ///
  /// In de, this message translates to:
  /// **'Neu beginnen'**
  String get recoveryStartFresh;

  /// No description provided for @recoveryStartFreshConfirm.
  ///
  /// In de, this message translates to:
  /// **'Die unlesbaren Daten werden endgültig gelöscht.\n\nEin automatisches Backup wird dabei ausgeschaltet, damit es deine alten Backups nicht nach und nach ersetzt. Sie bleiben am Speicherort und lassen sich später wiederherstellen.'**
  String get recoveryStartFreshConfirm;

  /// No description provided for @startEating.
  ///
  /// In de, this message translates to:
  /// **'Essen beginnen'**
  String get startEating;

  /// No description provided for @startEatingSave.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get startEatingSave;

  /// No description provided for @startEatingHint.
  ///
  /// In de, this message translates to:
  /// **'Den Rest trägst du ein, wenn du fertig bist. Alles ist optional.'**
  String get startEatingHint;

  /// No description provided for @finishEating.
  ///
  /// In de, this message translates to:
  /// **'Essen beenden'**
  String get finishEating;

  /// No description provided for @whenDidYouStop.
  ///
  /// In de, this message translates to:
  /// **'Wann hast du aufgehört?'**
  String get whenDidYouStop;

  /// No description provided for @inProgress.
  ///
  /// In de, this message translates to:
  /// **'läuft'**
  String get inProgress;

  /// No description provided for @runningSince.
  ///
  /// In de, this message translates to:
  /// **'{meal} seit {time}'**
  String runningSince(String meal, String time);

  /// No description provided for @statistics.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get statistics;

  /// No description provided for @statsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Einträge in diesem Zeitraum'**
  String get statsEmpty;

  /// No description provided for @statsSearch.
  ///
  /// In de, this message translates to:
  /// **'Suchen …'**
  String get statsSearch;

  /// No description provided for @statsIncidents.
  ///
  /// In de, this message translates to:
  /// **'Essanfall / Maßnahmen'**
  String get statsIncidents;

  /// No description provided for @drink.
  ///
  /// In de, this message translates to:
  /// **'Getränk'**
  String get drink;

  /// No description provided for @drinkDefault.
  ///
  /// In de, this message translates to:
  /// **'Wasser'**
  String get drinkDefault;

  /// No description provided for @sectionDrinks.
  ///
  /// In de, this message translates to:
  /// **'Getränke'**
  String get sectionDrinks;

  /// No description provided for @addDrink.
  ///
  /// In de, this message translates to:
  /// **'Getränk hinzufügen'**
  String get addDrink;

  /// No description provided for @drinkHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Tee'**
  String get drinkHint;

  /// The empty entry means no unit, e.g. 2 Bananen
  ///
  /// In de, this message translates to:
  /// **'Portion||g|ml|EL|TL|Teller|Schüssel|Scheibe|Stück'**
  String get foodUnits;

  /// No description provided for @noUnit.
  ///
  /// In de, this message translates to:
  /// **'ohne Einheit'**
  String get noUnit;

  /// No description provided for @drinkUnits.
  ///
  /// In de, this message translates to:
  /// **'ml|l|Glas|Tasse|Becher|Flasche'**
  String get drinkUnits;

  /// No description provided for @time.
  ///
  /// In de, this message translates to:
  /// **'Uhrzeit'**
  String get time;

  /// No description provided for @backupEncryptTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup mit Passwort schützen'**
  String get backupEncryptTitle;

  /// No description provided for @backupEncryptHint.
  ///
  /// In de, this message translates to:
  /// **'Mit Passwort kann niemand die Datei lesen, der das Passwort nicht kennt. Bewahre es gut auf: Ein vergessenes Passwort lässt sich nicht zurücksetzen, das Backup wäre dann verloren.'**
  String get backupEncryptHint;

  /// No description provided for @password.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get password;

  /// No description provided for @passwordRepeat.
  ///
  /// In de, this message translates to:
  /// **'Passwort wiederholen'**
  String get passwordRepeat;

  /// No description provided for @passwordTooShort.
  ///
  /// In de, this message translates to:
  /// **'Mindestens {min} Zeichen'**
  String passwordTooShort(int min);

  /// No description provided for @passwordMismatch.
  ///
  /// In de, this message translates to:
  /// **'Die Passwörter stimmen nicht überein'**
  String get passwordMismatch;

  /// No description provided for @backupEncrypt.
  ///
  /// In de, this message translates to:
  /// **'Verschlüsseln'**
  String get backupEncrypt;

  /// No description provided for @backupLockedTitle.
  ///
  /// In de, this message translates to:
  /// **'Verschlüsseltes Backup'**
  String get backupLockedTitle;

  /// No description provided for @backupLockedHint.
  ///
  /// In de, this message translates to:
  /// **'Gib das Passwort ein, mit dem dieses Backup erstellt wurde.'**
  String get backupLockedHint;

  /// No description provided for @backupWrongPassword.
  ///
  /// In de, this message translates to:
  /// **'Falsches Passwort'**
  String get backupWrongPassword;

  /// No description provided for @autoBackup.
  ///
  /// In de, this message translates to:
  /// **'Automatisches Backup'**
  String get autoBackup;

  /// No description provided for @autoBackupOff.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get autoBackupOff;

  /// No description provided for @autoBackupIntro.
  ///
  /// In de, this message translates to:
  /// **'Sichert dein Protokoll nach Änderungen verschlüsselt an einem Ort deiner Wahl – etwa in deiner Nextcloud oder einem Cloud-Ordner. Nur mit deinem Wiederherstellungscode oder Passwort lässt es sich öffnen, auch nicht vom Anbieter des Speicherorts. Die letzten 7 Tage bleiben erhalten.'**
  String get autoBackupIntro;

  /// No description provided for @autoBackupSetUp.
  ///
  /// In de, this message translates to:
  /// **'Automatisches Backup einrichten'**
  String get autoBackupSetUp;

  /// No description provided for @autoBackupNever.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Backup'**
  String get autoBackupNever;

  /// No description provided for @autoBackupLast.
  ///
  /// In de, this message translates to:
  /// **'Letztes Backup: {time}'**
  String autoBackupLast(String time);

  /// No description provided for @autoBackupNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt sichern'**
  String get autoBackupNow;

  /// No description provided for @autoBackupDisable.
  ///
  /// In de, this message translates to:
  /// **'Automatisches Backup ausschalten'**
  String get autoBackupDisable;

  /// No description provided for @autoBackupDisableHint.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel und Zugangsdaten werden von diesem Gerät gelöscht. Ohne Haken bleiben die Backups am Speicherort und lassen sich mit dem Code weiter wiederherstellen.'**
  String get autoBackupDisableHint;

  /// No description provided for @autoBackupDeleteFiles.
  ///
  /// In de, this message translates to:
  /// **'Auch die Backups dieses Geräts am Speicherort löschen'**
  String get autoBackupDeleteFiles;

  /// No description provided for @autoBackupDeleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Auch Konto und alle Backups auf dem Server löschen'**
  String get autoBackupDeleteAccount;

  /// No description provided for @autoBackupDeleteFailed.
  ///
  /// In de, this message translates to:
  /// **'Löschen fehlgeschlagen, Backup bleibt eingeschaltet: {error}'**
  String autoBackupDeleteFailed(String error);

  /// No description provided for @autoBackupPasswordTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup-Passwort festlegen'**
  String get autoBackupPasswordTitle;

  /// No description provided for @autoBackupPasswordHint.
  ///
  /// In de, this message translates to:
  /// **'Wer den Speicherort betreibt, kann beliebig oft raten. Deshalb mindestens {min} Zeichen mit Groß- und Kleinbuchstaben, Ziffern oder Sonderzeichen – oder ein langer Satz ab 24 Zeichen. Ein vergessenes Passwort lässt sich nicht zurücksetzen.'**
  String autoBackupPasswordHint(int min);

  /// No description provided for @passwordTooWeak.
  ///
  /// In de, this message translates to:
  /// **'Zu schwach – siehe Hinweis oben'**
  String get passwordTooWeak;

  /// No description provided for @backupCodeLockedHint.
  ///
  /// In de, this message translates to:
  /// **'Gib den Wiederherstellungscode ein, den du beim Einrichten des automatischen Backups notiert hast.'**
  String get backupCodeLockedHint;

  /// No description provided for @backupWrongCode.
  ///
  /// In de, this message translates to:
  /// **'Falscher Code'**
  String get backupWrongCode;

  /// No description provided for @recoveryCode.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellungscode'**
  String get recoveryCode;

  /// No description provided for @recoveryCodeHint.
  ///
  /// In de, this message translates to:
  /// **'Notiere diesen Code und bewahre ihn sicher auf, getrennt von deinem Handy. Er wird nur jetzt angezeigt. Ohne ihn lässt sich kein Backup wiederherstellen.'**
  String get recoveryCodeHint;

  /// No description provided for @recoveryCodeSaved.
  ///
  /// In de, this message translates to:
  /// **'Ich habe den Code notiert'**
  String get recoveryCodeSaved;

  /// No description provided for @recoveryCodeCopy.
  ///
  /// In de, this message translates to:
  /// **'Kopieren'**
  String get recoveryCodeCopy;

  /// No description provided for @recoveryCodeCopied.
  ///
  /// In de, this message translates to:
  /// **'Code kopiert'**
  String get recoveryCodeCopied;

  /// No description provided for @recoveryCodeDownload.
  ///
  /// In de, this message translates to:
  /// **'Als Datei speichern'**
  String get recoveryCodeDownload;

  /// No description provided for @recoveryCodeSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Speichern fehlgeschlagen: {error}'**
  String recoveryCodeSaveFailed(String error);

  /// No description provided for @backupLocation.
  ///
  /// In de, this message translates to:
  /// **'Speicherort'**
  String get backupLocation;

  /// No description provided for @backupLocationServer.
  ///
  /// In de, this message translates to:
  /// **'WhatsEat-Server'**
  String get backupLocationServer;

  /// No description provided for @backupLocationServerHint.
  ///
  /// In de, this message translates to:
  /// **'Eigener Server, Anmeldung nur mit dem Wiederherstellungscode'**
  String get backupLocationServerHint;

  /// No description provided for @serverUrl.
  ///
  /// In de, this message translates to:
  /// **'Server-Adresse oder Einladungslink'**
  String get serverUrl;

  /// No description provided for @serverInvite.
  ///
  /// In de, this message translates to:
  /// **'Einladungscode'**
  String get serverInvite;

  /// No description provided for @serverInviteLabel.
  ///
  /// In de, this message translates to:
  /// **'Vom Betreiber des Servers erhalten'**
  String get serverInviteLabel;

  /// No description provided for @serverInviteInvalid.
  ///
  /// In de, this message translates to:
  /// **'Ungültiger oder abgelaufener Einladungscode'**
  String get serverInviteInvalid;

  /// No description provided for @serverInactivityTitle.
  ///
  /// In de, this message translates to:
  /// **'Inaktive Konten werden gelöscht'**
  String get serverInactivityTitle;

  /// No description provided for @serverInactivityWarning.
  ///
  /// In de, this message translates to:
  /// **'Dieser Server löscht Konten nach {days} Tagen ohne Aktivität – mitsamt allen Backups darauf.\n\nAls Aktivität zählt jeder Start der App und jedes Backup. Das Melden beim App-Start kannst du in den Einstellungen abschalten.'**
  String serverInactivityWarning(int days);

  /// No description provided for @understood.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get understood;

  /// No description provided for @keepAlive.
  ///
  /// In de, this message translates to:
  /// **'Konto aktiv halten'**
  String get keepAlive;

  /// No description provided for @keepAliveHint.
  ///
  /// In de, this message translates to:
  /// **'Meldet sich bei jedem App-Start beim Server, auch ohne neue Einträge'**
  String get keepAliveHint;

  /// No description provided for @serverInactivityNote.
  ///
  /// In de, this message translates to:
  /// **'Der Server löscht Konten nach {days} Tagen ohne Aktivität mitsamt allen Backups.'**
  String serverInactivityNote(int days);

  /// No description provided for @keepAliveOffTitle.
  ///
  /// In de, this message translates to:
  /// **'Nicht mehr beim App-Start melden?'**
  String get keepAliveOffTitle;

  /// No description provided for @keepAliveOffWarning.
  ///
  /// In de, this message translates to:
  /// **'Dann zählen nur noch Backups nach Änderungen als Aktivität. Trägst du {days} Tage lang nichts ein, löscht der Server dein Konto und alle Backups darauf.'**
  String keepAliveOffWarning(int days);

  /// No description provided for @keepAliveOffHint.
  ///
  /// In de, this message translates to:
  /// **'Dann zählen nur noch Backups nach Änderungen als Aktivität.'**
  String get keepAliveOffHint;

  /// No description provided for @keepAliveOffConfirm.
  ///
  /// In de, this message translates to:
  /// **'Abschalten'**
  String get keepAliveOffConfirm;

  /// No description provided for @backupLocationWebDav.
  ///
  /// In de, this message translates to:
  /// **'WebDAV'**
  String get backupLocationWebDav;

  /// No description provided for @backupLocationWebDavHint.
  ///
  /// In de, this message translates to:
  /// **'Nextcloud, ownCloud, NAS'**
  String get backupLocationWebDavHint;

  /// No description provided for @backupLocationFolder.
  ///
  /// In de, this message translates to:
  /// **'Ordner'**
  String get backupLocationFolder;

  /// No description provided for @backupLocationFolderHint.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Gerät oder über eine Cloud-App, z. B. Google Drive oder iCloud Drive'**
  String get backupLocationFolderHint;

  /// No description provided for @backupLocationFailed.
  ///
  /// In de, this message translates to:
  /// **'Speicherort nicht erreichbar: {error}'**
  String backupLocationFailed(String error);

  /// No description provided for @backupNoneFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Backups an diesem Speicherort gefunden'**
  String get backupNoneFound;

  /// No description provided for @backupRestoreConfirm.
  ///
  /// In de, this message translates to:
  /// **'Dieses Backup wiederherstellen?'**
  String get backupRestoreConfirm;

  /// No description provided for @backupCreatedAt.
  ///
  /// In de, this message translates to:
  /// **'Gesichert am {date}.'**
  String backupCreatedAt(String date);

  /// No description provided for @backupDateMismatch.
  ///
  /// In de, this message translates to:
  /// **'Achtung: Laut Dateiname ist es vom {day}. Die Datei wurde womöglich umbenannt oder ausgetauscht – stelle sie nur wieder her, wenn du damit gerechnet hast.'**
  String backupDateMismatch(String day);

  /// No description provided for @backupChoose.
  ///
  /// In de, this message translates to:
  /// **'Backup wählen'**
  String get backupChoose;

  /// No description provided for @backupLocationHasBackups.
  ///
  /// In de, this message translates to:
  /// **'Hier liegen schon Backups'**
  String get backupLocationHasBackups;

  /// No description provided for @backupLocationHasBackupsHint.
  ///
  /// In de, this message translates to:
  /// **'Wenn das ein neues Gerät ist, stelle zuerst das Backup wieder her – sonst ersetzt das heutige Backup dieses Geräts das deines alten Geräts.'**
  String get backupLocationHasBackupsHint;

  /// No description provided for @backupContinueSetup.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem einrichten'**
  String get backupContinueSetup;

  /// No description provided for @backupSecretTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup schützen mit …'**
  String get backupSecretTitle;

  /// No description provided for @backupSecretCode.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellungscode'**
  String get backupSecretCode;

  /// No description provided for @backupSecretCodeHint.
  ///
  /// In de, this message translates to:
  /// **'Empfohlen. Ein zufälliger Code, den du einmal notierst.'**
  String get backupSecretCodeHint;

  /// No description provided for @backupSecretPassword.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Passwort'**
  String get backupSecretPassword;

  /// No description provided for @backupSecretPasswordHint.
  ///
  /// In de, this message translates to:
  /// **'Muss lang und stark sein.'**
  String get backupSecretPasswordHint;

  /// No description provided for @backupDone.
  ///
  /// In de, this message translates to:
  /// **'Backup gespeichert'**
  String get backupDone;

  /// No description provided for @backupFailed.
  ///
  /// In de, this message translates to:
  /// **'Backup fehlgeschlagen: {error}'**
  String backupFailed(String error);

  /// No description provided for @backupRestoreFromLocation.
  ///
  /// In de, this message translates to:
  /// **'Von Speicherort wiederherstellen'**
  String get backupRestoreFromLocation;

  /// No description provided for @webDavHint.
  ///
  /// In de, this message translates to:
  /// **'Adresse des Ordners für die Backups. Bei Nextcloud: https://<server>/remote.php/dav/files/<benutzer>/WhatsEat – und unter Einstellungen → Sicherheit ein App-Passwort erstellen.'**
  String get webDavHint;

  /// No description provided for @webDavUrl.
  ///
  /// In de, this message translates to:
  /// **'Ordner-Adresse'**
  String get webDavUrl;

  /// No description provided for @webDavUrlInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine https://-Adresse angeben'**
  String get webDavUrlInvalid;

  /// No description provided for @webDavUser.
  ///
  /// In de, this message translates to:
  /// **'Benutzername'**
  String get webDavUser;

  /// No description provided for @webDavPassword.
  ///
  /// In de, this message translates to:
  /// **'(App-)Passwort'**
  String get webDavPassword;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
