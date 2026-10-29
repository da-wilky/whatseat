// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'WhatsEat';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get pickDate => 'Datum wählen';

  @override
  String get export => 'Exportieren';

  @override
  String get templates => 'Vorlagen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get addEntry => 'Eintrag';

  @override
  String get newEntry => 'Neuer Eintrag';

  @override
  String get editEntry => 'Eintrag bearbeiten';

  @override
  String get eatAgain => 'Wieder essen';

  @override
  String get reuseHint =>
      'Gespeicherte Vorlagen und zuletzt gegessene Mahlzeiten erscheinen hier, damit du sie mit einem Tipp erneut eintragen kannst.';

  @override
  String get emptyDay => 'Noch nichts eingetragen';

  @override
  String get emptyDayHint =>
      'Trage alles ein, was du isst und trinkst – am besten direkt nach dem Essen.';

  @override
  String get dayNote => 'Tagesnotiz';

  @override
  String get dayNoteAdd => 'Tagesnotiz hinzufügen';

  @override
  String get dayNoteHint => 'z. B. Diät oder Krankheit an diesem Tag';

  @override
  String get noteDiet => 'Diät';

  @override
  String get noteSick => 'Krank';

  @override
  String get entryDeleted => 'Eintrag gelöscht';

  @override
  String get undo => 'Rückgängig';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get delete => 'Löschen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get pin => 'Anheften';

  @override
  String get other => 'Andere …';

  @override
  String get yes => 'ja';

  @override
  String get no => 'nein';

  @override
  String get notSet => 'nicht angegeben';

  @override
  String get deleteEntryQuestion => 'Eintrag löschen?';

  @override
  String get discardQuestion => 'Änderungen verwerfen?';

  @override
  String get discard => 'Verwerfen';

  @override
  String get keepEditing => 'Weiter bearbeiten';

  @override
  String get saveAsTemplate => 'Als Vorlage speichern';

  @override
  String get templateName => 'Name der Vorlage';

  @override
  String get templateSaved => 'Vorlage gespeichert';

  @override
  String get templateDeleted => 'Vorlage gelöscht';

  @override
  String get templatesEmpty =>
      'Noch keine Vorlagen.\nIm Eintrag über ⋮ → „Als Vorlage speichern“ anlegen. Beim Verwenden übernimmt die Vorlage automatisch deine letzten Angaben.';

  @override
  String get fromTemplateHint =>
      'Aus Vorlage – beim Speichern wird die Vorlage mit diesen Angaben aktualisiert.';

  @override
  String get needOneItem =>
      'Bitte mindestens ein Lebensmittel oder Getränk eintragen.';

  @override
  String get sectionMeal => 'Mahlzeit';

  @override
  String get mealBreakfast => 'Frühstück';

  @override
  String get mealLunch => 'Mittagessen';

  @override
  String get mealDinner => 'Abendessen';

  @override
  String get mealSnack => 'Snack';

  @override
  String get timeFrom => 'von';

  @override
  String get timeTo => 'bis';

  @override
  String get timeToAdd => 'bis …';

  @override
  String get sectionFood => 'Lebensmittel / Getränke';

  @override
  String get amount => 'Menge';

  @override
  String get foodHint => 'z. B. Vollkornbrot';

  @override
  String get addItem => 'Weiteres hinzufügen';

  @override
  String lastAmount(String amount) {
    return 'zuletzt: $amount';
  }

  @override
  String get withWhom => 'Mit wem';

  @override
  String get withWhomDefaults =>
      'allein|Familie|Partner:in|Freunde|Kolleg:innen';

  @override
  String get sectionBefore => 'Vor dem Essen';

  @override
  String get hunger => 'Hunger';

  @override
  String get appetiteFor => 'Appetit auf';

  @override
  String get situationBefore => 'Situation, Gedanken, Gefühle';

  @override
  String get sectionAfter => 'Nach dem Essen';

  @override
  String get satiety => 'Satt';

  @override
  String get situationAfter => 'Situation, Gedanken, Gefühle';

  @override
  String get sectionBehaviour => 'Essanfall & Maßnahmen';

  @override
  String get binge => 'Essanfall';

  @override
  String get bingeHint => 'Kontrollverlust beim Essen';

  @override
  String get measures => 'Gewichtsregulierende Maßnahmen';

  @override
  String get measureDefaults => 'Sport|Erbrechen|Abführmittel';

  @override
  String get general => 'Allgemein';

  @override
  String get patientName => 'Name';

  @override
  String get patientNameHint => 'Erscheint im PDF-Protokoll';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get security => 'Sicherheit';

  @override
  String get appLock => 'App-Sperre';

  @override
  String get appLockHint => 'PIN beim Öffnen; blockiert Screenshots';

  @override
  String get biometric => 'Fingerabdruck / Face ID';

  @override
  String get biometricConfirm => 'Biometrisches Entsperren bestätigen';

  @override
  String get lockTimeout => 'Sperren nach';

  @override
  String get lockImmediately => 'Sofort';

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String get pinChange => 'PIN ändern';

  @override
  String get encryptionInfo =>
      'Alle Daten werden verschlüsselt auf diesem Gerät gespeichert.';

  @override
  String get lockTitle => 'WhatsEat ist gesperrt';

  @override
  String get unlockReason => 'WhatsEat entsperren';

  @override
  String get pinEnter => 'PIN eingeben';

  @override
  String get pinWrong => 'Falsche PIN';

  @override
  String get pinChoose => 'PIN festlegen';

  @override
  String get pinRepeat => 'PIN wiederholen';

  @override
  String get pinLengthHint => '4–6 Ziffern, dann ✓';

  @override
  String get pinMismatch => 'PINs stimmen nicht überein – bitte erneut';

  @override
  String get data => 'Daten';

  @override
  String get backupCreate => 'Backup erstellen';

  @override
  String get backupWarning => 'Die Backup-Datei ist nicht verschlüsselt';

  @override
  String get backupRestore => 'Backup wiederherstellen';

  @override
  String get backupRestoreHint => 'Wird mit vorhandenen Daten zusammengeführt';

  @override
  String backupImported(int count) {
    return '$count Datensätze übernommen';
  }

  @override
  String backupInvalid(String error) {
    return 'Backup konnte nicht gelesen werden: $error';
  }

  @override
  String get exportRange => 'Zeitraum';

  @override
  String lastDays(int days) {
    return 'Letzte $days Tage';
  }

  @override
  String get customRange => 'Zeitraum wählen';

  @override
  String get exportPdf => 'PDF-Protokoll ansehen & teilen';

  @override
  String get exportPdfHint =>
      'Eine Seite pro Tag, im Format des Essprotokolls.';

  @override
  String get exportCsv => 'Als CSV teilen';

  @override
  String get protocolTitle => 'Essprotokoll';

  @override
  String get pdfName => 'Name';

  @override
  String get pdfDate => 'Datum';

  @override
  String get colMeal => 'Mahlzeit\nvon … bis …';

  @override
  String get colMealType => 'Mahlzeit';

  @override
  String get colWithWhom => 'Mit wem';

  @override
  String get colSituationBefore =>
      'Situation vor dem Essen, Gedanken, Gefühle, Appetit auf';

  @override
  String get colHunger => 'Hunger (in %)';

  @override
  String get colAmount => 'Menge';

  @override
  String get colFood => 'Lebensmittel/ Getränk';

  @override
  String get colSatiety => 'Satt (in %)';

  @override
  String get colBinge => 'Essanfall (ja/nein)';

  @override
  String get colMeasures =>
      'Gewichtsregulierende Maßnahmen (z. B. Sport, Erbrechen, Abführmittel)';

  @override
  String get colSituationAfter => 'Situation nach dem Essen, Gedanken, Gefühle';

  @override
  String get unitDefs =>
      'Stück/Stück|Scheibe/Scheiben|Portion/Portionen|Tasse/Tassen|Glas/Gläser|Becher/Becher|Schüssel/Schüsseln|Teller/Teller|EL/EL|TL/TL|Handvoll/Handvoll|Riegel/Riegel|Flasche/Flaschen|g/g|ml/ml';

  @override
  String get unit => 'Einheit';

  @override
  String get quantityHint => 'Anz.';

  @override
  String get newUnit => 'Neue Einheit …';

  @override
  String pinBlocked(int seconds) {
    return 'Zu viele Versuche – erneut in $seconds s';
  }

  @override
  String get pinConfirm => 'Aktuelle PIN bestätigen';

  @override
  String get recoveryTitle => 'Daten nicht lesbar';

  @override
  String get recoveryBody =>
      'Die verschlüsselten Daten auf diesem Gerät lassen sich nicht öffnen – meist, weil der Schlüssel im sicheren Speicher des Geräts verloren gegangen ist. Ohne ihn sind die Daten nicht wiederherstellbar.\n\nVersuche es zuerst erneut (z. B. nach einem Neustart). Hilft das nicht, kannst du ein Backup einspielen oder neu beginnen.';

  @override
  String get recoveryRetry => 'Erneut versuchen';

  @override
  String get recoveryStartFresh => 'Neu beginnen';

  @override
  String get recoveryStartFreshConfirm =>
      'Die unlesbaren Daten werden endgültig gelöscht.';

  @override
  String get startEating => 'Essen beginnen';

  @override
  String get startEatingSave => 'Starten';

  @override
  String get startEatingHint =>
      'Den Rest trägst du ein, wenn du fertig bist. Alles ist optional.';

  @override
  String get finishEating => 'Essen beenden';

  @override
  String get whenDidYouStop => 'Wann hast du aufgehört?';

  @override
  String get inProgress => 'läuft';

  @override
  String runningSince(String meal, String time) {
    return '$meal seit $time';
  }
}
