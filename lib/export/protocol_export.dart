import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/database.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../ui/common.dart';

class ProtocolDay {
  const ProtocolDay(this.day, this.entries, this.note);

  final DateTime day;
  final List<MealEntry> entries;
  final DayNote? note;
}

/// Days without entries and without a note are skipped.
Future<List<ProtocolDay>> loadProtocol(AppDatabase db, DateTime from, DateTime to) async {
  final entries = await db.entriesBetween(dayKey(from), dayKey(to));
  final notes = {for (final n in await db.notesBetween(dayKey(from), dayKey(to))) n.day: n};
  return [
    for (var d = dateOnly(from); !d.isAfter(to); d = DateTime(d.year, d.month, d.day + 1))
      if (entries.any((e) => e.day == dayKey(d)) || _hasContent(notes[dayKey(d)]))
        ProtocolDay(d, entries.where((e) => e.day == dayKey(d)).toList(), notes[dayKey(d)]),
  ];
}

bool _hasContent(DayNote? n) => n != null && (n.diet || n.sick || n.note.isNotEmpty);

String _percent(int? v) => v == null ? '' : '$v %';

String _situationBefore(AppLocalizations l, MealEntry e) => [
      if (e.situationBefore.isNotEmpty) e.situationBefore,
      if (e.appetiteFor.isNotEmpty) '${l.appetiteFor}: ${e.appetiteFor}',
    ].join('\n');

String _noteText(AppLocalizations l, DayNote? n) => n == null
    ? ''
    : [if (n.diet) l.noteDiet, if (n.sick) l.noteSick, if (n.note.isNotEmpty) n.note].join(' · ');

/// Proportions of the paper form's columns.
const _columnFlex = <double>[70, 56, 135, 50, 62, 118, 50, 60, 137, 122];

List<String> _headers(AppLocalizations l) => [
      l.colMeal,
      l.colWithWhom,
      l.colSituationBefore,
      l.colHunger,
      l.colAmount,
      l.colFood,
      l.colSatiety,
      l.colBinge,
      l.colMeasures,
      l.colSituationAfter,
    ];

Future<Uint8List> buildProtocolPdf(AppLocalizations l, List<ProtocolDay> days, String patientName) async {
  final base = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  final dateFormat = DateFormat.yMd(l.localeName);
  final doc = pw.Document(title: l.protocolTitle, author: patientName);
  const border = PdfColors.grey700;
  const small = pw.TextStyle(fontSize: 8);

  final pageFormat = PdfPageFormat.a4.landscape;
  const margin = pw.EdgeInsets.fromLTRB(32, 28, 32, 28);
  const cellPadding = pw.EdgeInsets.all(4);

  pw.Widget cell(String text, {pw.TextStyle? style}) =>
      pw.Padding(padding: cellPadding, child: pw.Text(text, style: style ?? small));

  double textWidth(int column) =>
      (pageFormat.width - margin.horizontal) * _columnFlex[column] / _columnFlex.reduce((a, b) => a + b) -
      cellPadding.horizontal;

  double textHeight(pw.Context context, String text, int column) =>
      (pw.Text(text, style: small)..layout(context, pw.BoxConstraints(maxWidth: textWidth(column)))).box!.height;

  // Amount and food are separate cells: each item gets the same height in both, so a wrapped name pushes the
  // following amounts down with it.
  List<pw.Widget> itemCells(pw.Context context, MealEntry e) {
    final amounts = <pw.Widget>[];
    final foods = <pw.Widget>[];
    for (final item in e.items) {
      final amount = formatAmount(l, item);
      final food = itemLabel(item);
      final height = math.max(textHeight(context, amount, 4), textHeight(context, food, 5));
      for (final (texts, text) in [(amounts, amount), (foods, food)]) {
        texts.add(pw.ConstrainedBox(
          constraints: pw.BoxConstraints(minHeight: height),
          child: pw.Text(text, style: small),
        ));
      }
    }
    return [
      for (final texts in [amounts, foods])
        pw.Padding(
          padding: cellPadding,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: texts),
        ),
    ];
  }

  pw.Widget headerField(String label, String value) => pw.Row(children: [
        pw.Text('$label ', style: const pw.TextStyle(fontSize: 11)),
        pw.Container(
          width: 200,
          padding: const pw.EdgeInsets.only(bottom: 1),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: border, width: 0.5, style: pw.BorderStyle.dotted)),
          ),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ),
      ]);

  // Pages with no data still print an empty form, like the paper original.
  final printable = days.isEmpty ? [ProtocolDay(dateOnly(DateTime.now()), const [], null)] : days;

  for (final day in printable) {
    final note = _noteText(l, day.note);
    doc.addPage(pw.MultiPage(
      pageFormat: pageFormat,
      margin: margin,
      theme: pw.ThemeData.withFont(base: base, bold: bold),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(children: [
          headerField(l.pdfName, patientName),
          pw.SizedBox(width: 40),
          headerField(l.pdfDate, days.isEmpty ? '' : dateFormat.format(day.day)),
          pw.Spacer(),
          pw.Text(l.protocolTitle, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('${context.pageNumber} / ${context.pagesCount}', style: small),
      ),
      build: (context) => [
        pw.Table(
          border: pw.TableBorder.all(color: border, width: 0.6),
          columnWidths: {for (final (i, flex) in _columnFlex.indexed) i: pw.FlexColumnWidth(flex)},
          children: [
            pw.TableRow(
              repeat: true,
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [for (final h in _headers(l)) cell(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))],
            ),
            for (final e in day.entries)
              pw.TableRow(children: [
                cell('${entryLabel(l, e)}\n${timeRange(e.startMinutes, e.endMinutes)}'),
                cell(e.withWhom),
                cell(_situationBefore(l, e)),
                cell(_percent(e.hunger)),
                ...itemCells(context, e),
                cell(_percent(e.satiety)),
                cell(e.binge ? l.yes : l.no),
                cell(measuresText(e)),
                cell(e.situationAfter),
              ]),
            for (var i = day.entries.length; i < 8; i++)
              pw.TableRow(children: [for (var c = 0; c < 10; c++) pw.SizedBox(height: 30)]),
          ],
        ),
        if (note.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text('${l.dayNote}: $note', style: const pw.TextStyle(fontSize: 9)),
          ),
      ],
    ));
  }
  return doc.save();
}

String buildProtocolCsv(AppLocalizations l, List<ProtocolDay> days) {
  final rows = <List<Object>>[
    [
      l.pdfDate,
      l.colMealType,
      l.timeFrom,
      l.timeTo,
      l.colWithWhom,
      l.colSituationBefore,
      l.appetiteFor,
      l.colHunger,
      l.colAmount,
      l.colFood,
      l.colSatiety,
      l.colBinge,
      l.colMeasures,
      l.colSituationAfter,
      l.dayNote,
    ],
    for (final day in days)
      if (day.entries.isEmpty)
        [dayKey(day.day), for (var i = 0; i < 13; i++) '', _noteText(l, day.note)]
      else
        for (final e in day.entries)
        [
          e.day,
          entryLabel(l, e),
          formatMinutes(e.startMinutes),
          e.endMinutes == null ? '' : formatMinutes(e.endMinutes!),
          e.withWhom,
          e.situationBefore,
          e.appetiteFor,
          e.hunger ?? '',
          e.items.map((i) => formatAmount(l, i)).join('; '),
          e.items.map(itemLabel).join('; '),
          e.satiety ?? '',
          e.binge ? l.yes : l.no,
          measuresText(e),
          e.situationAfter,
          _noteText(l, day.note),
        ],
  ];
  // Excel variant: BOM and ';' delimiter, which German Excel expects.
  return excel.encode([
    for (final row in rows) [for (final cell in row) cell is String ? _csvText(cell) : cell],
  ]);
}

/// Excel evaluates cells starting with these as formulas; the leading apostrophe keeps them plain text.
String _csvText(String value) => value.startsWith(RegExp(r'[=+\-@\t\r]')) ? "'$value" : value;
