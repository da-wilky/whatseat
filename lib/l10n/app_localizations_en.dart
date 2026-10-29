// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WhatsEat';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get pickDate => 'Pick date';

  @override
  String get export => 'Export';

  @override
  String get templates => 'Templates';

  @override
  String get settings => 'Settings';

  @override
  String get addEntry => 'Entry';

  @override
  String get newEntry => 'New entry';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get eatAgain => 'Eat again';

  @override
  String get reuseHint =>
      'Saved templates and recently eaten meals show up here so you can log them again with one tap.';

  @override
  String get emptyDay => 'Nothing logged yet';

  @override
  String get emptyDayHint =>
      'Log everything you eat and drink – ideally right after eating.';

  @override
  String get statMeals => 'Entries';

  @override
  String get statHunger => 'Ø hunger';

  @override
  String get statSatiety => 'Ø full';

  @override
  String get statBinges => 'Binges';

  @override
  String get statMeasures => 'Measures';

  @override
  String get dayNote => 'Day note';

  @override
  String get dayNoteAdd => 'Add day note';

  @override
  String get dayNoteHint => 'e.g. diet or illness on this day';

  @override
  String get noteDiet => 'Diet';

  @override
  String get noteSick => 'Sick';

  @override
  String get entryDeleted => 'Entry deleted';

  @override
  String get undo => 'Undo';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get pin => 'Pin';

  @override
  String get other => 'Other …';

  @override
  String get yes => 'yes';

  @override
  String get no => 'no';

  @override
  String get notSet => 'not set';

  @override
  String get deleteEntryQuestion => 'Delete entry?';

  @override
  String get discardQuestion => 'Discard changes?';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get saveAsTemplate => 'Save as template';

  @override
  String get templateName => 'Template name';

  @override
  String get templateSaved => 'Template saved';

  @override
  String get templateDeleted => 'Template deleted';

  @override
  String get templatesEmpty =>
      'No templates yet.\nCreate one from an entry via ⋮ → “Save as template”. When used, a template automatically takes over your latest values.';

  @override
  String get fromTemplateHint =>
      'From template – saving updates the template with these values.';

  @override
  String get needOneItem => 'Please add at least one food or drink.';

  @override
  String get sectionMeal => 'Meal';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snack';

  @override
  String get timeFrom => 'from';

  @override
  String get timeTo => 'to';

  @override
  String get timeToAdd => 'to …';

  @override
  String get sectionFood => 'Food / drinks';

  @override
  String get amount => 'Amount';

  @override
  String get foodHint => 'e.g. wholegrain bread';

  @override
  String get addItem => 'Add another';

  @override
  String lastAmount(String amount) {
    return 'last: $amount';
  }

  @override
  String get withWhom => 'With whom';

  @override
  String get withWhomDefaults => 'alone|family|partner|friends|colleagues';

  @override
  String get sectionBefore => 'Before eating';

  @override
  String get hunger => 'Hunger';

  @override
  String get appetiteFor => 'Craving';

  @override
  String get situationBefore => 'Situation, thoughts, feelings';

  @override
  String get sectionAfter => 'After eating';

  @override
  String get satiety => 'Full';

  @override
  String get situationAfter => 'Situation, thoughts, feelings';

  @override
  String get sectionBehaviour => 'Binge & measures';

  @override
  String get binge => 'Binge';

  @override
  String get bingeHint => 'Loss of control while eating';

  @override
  String get measures => 'Weight-control measures';

  @override
  String get measureDefaults => 'exercise|vomiting|laxatives';

  @override
  String get general => 'General';

  @override
  String get patientName => 'Name';

  @override
  String get patientNameHint => 'Shown on the PDF protocol';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get security => 'Security';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockHint => 'PIN on open; blocks screenshots';

  @override
  String get biometric => 'Fingerprint / Face ID';

  @override
  String get biometricConfirm => 'Confirm biometric unlock';

  @override
  String get lockTimeout => 'Lock after';

  @override
  String get lockImmediately => 'Immediately';

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get pinChange => 'Change PIN';

  @override
  String get encryptionInfo => 'All data is stored encrypted on this device.';

  @override
  String get lockTitle => 'WhatsEat is locked';

  @override
  String get unlockReason => 'Unlock WhatsEat';

  @override
  String get pinEnter => 'Enter PIN';

  @override
  String get pinWrong => 'Wrong PIN';

  @override
  String get pinChoose => 'Choose a PIN';

  @override
  String get pinRepeat => 'Repeat PIN';

  @override
  String get pinLengthHint => '4–6 digits, then ✓';

  @override
  String get pinMismatch => 'PINs don\'t match – try again';

  @override
  String get data => 'Data';

  @override
  String get backupCreate => 'Create backup';

  @override
  String get backupWarning => 'The backup file is not encrypted';

  @override
  String get backupRestore => 'Restore backup';

  @override
  String get backupRestoreHint => 'Merged with existing data';

  @override
  String backupImported(int count) {
    return '$count records imported';
  }

  @override
  String backupInvalid(String error) {
    return 'Could not read backup: $error';
  }

  @override
  String get exportRange => 'Period';

  @override
  String lastDays(int days) {
    return 'Last $days days';
  }

  @override
  String get customRange => 'Choose period';

  @override
  String get exportPdf => 'View & share PDF protocol';

  @override
  String get exportPdfHint => 'One page per day, in the food diary layout.';

  @override
  String get exportCsv => 'Share as CSV';

  @override
  String get protocolTitle => 'Food diary';

  @override
  String get pdfName => 'Name';

  @override
  String get pdfDate => 'Date';

  @override
  String get colMeal => 'Meal\nfrom … to …';

  @override
  String get colMealType => 'Meal';

  @override
  String get colWithWhom => 'With whom';

  @override
  String get colSituationBefore =>
      'Situation before eating, thoughts, feelings, craving';

  @override
  String get colHunger => 'Hunger (in %)';

  @override
  String get colAmount => 'Amount';

  @override
  String get colFood => 'Food/ drink';

  @override
  String get colSatiety => 'Full (in %)';

  @override
  String get colBinge => 'Binge (yes/no)';

  @override
  String get colMeasures =>
      'Weight-control measures (e.g. exercise, vomiting, laxatives)';

  @override
  String get colSituationAfter => 'Situation after eating, thoughts, feelings';

  @override
  String get unitDefs =>
      'piece/pieces|slice/slices|serving/servings|cup/cups|glass/glasses|tub/tubs|bowl/bowls|plate/plates|tbsp/tbsp|tsp/tsp|handful/handfuls|bar/bars|bottle/bottles|g/g|ml/ml';

  @override
  String get unit => 'Unit';

  @override
  String get quantityHint => 'Qty';
}
