import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../export/protocol_export.dart';
import '../l10n/app_localizations.dart';
import '../lock/app_lock.dart';
import '../providers.dart';
import 'common.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, required this.initialDay});

  final DateTime initialDay;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late DateTimeRange _range = DateTimeRange(start: dateOnly(widget.initialDay), end: dateOnly(widget.initialDay));

  String get _fileBase => 'essprotokoll_${dayKey(_range.start)}_${dayKey(_range.end)}';

  void _setLastDays(int days) {
    final today = dateOnly(DateTime.now());
    setState(() => _range = DateTimeRange(start: DateTime(today.year, today.month, today.day - days + 1), end: today));
  }

  Future<List<ProtocolDay>> _load() => loadProtocol(ref.read(databaseProvider), _range.start, _range.end);

  Future<void> _shareCsv() async {
    final l = AppLocalizations.of(context);
    final csv = buildProtocolCsv(l, await _load());
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '$_fileBase.csv'));
    await file.writeAsString(csv);
    await withoutRelock(() => SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: l.protocolTitle)));
  }

  void _previewPdf() {
    final l = AppLocalizations.of(context);
    final name = ref.read(settingsProvider).patientName;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(l.protocolTitle)),
          body: PdfPreview.builder(
            build: (_) async => buildProtocolPdf(l, await _load(), name),
            pdfFileName: '$_fileBase.pdf',
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            // The default renders for screen width; zoomed-in text needs more detail.
            dpi: 150,
            // One zoomable surface for all pages; the stock preview only zooms a single page after a double tap.
            pagesBuilder: (context, pages) => LayoutBuilder(
              builder: (context, box) => InteractiveViewer(
                constrained: false,
                maxScale: 5,
                child: Container(
                  width: box.maxWidth,
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  padding: const EdgeInsets.all(8),
                  child: Column(children: [
                    for (final page in pages)
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: AspectRatio(aspectRatio: page.aspectRatio, child: Image(image: page.image)),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final format = DateFormat.yMMMd(l.localeName);
    final today = dateOnly(DateTime.now());
    final rangeText = _range.start == _range.end
        ? format.format(_range.start)
        : '${format.format(_range.start)} – ${format.format(_range.end)}';

    return Scaffold(
      appBar: AppBar(title: Text(l.export)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(title: l.exportRange, icon: Icons.date_range_rounded, children: [
            Text(rangeText, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(label: Text(l.today), onPressed: () => _setLastDays(1)),
              ActionChip(label: Text(l.lastDays(7)), onPressed: () => _setLastDays(7)),
              ActionChip(label: Text(l.lastDays(14)), onPressed: () => _setLastDays(14)),
              ActionChip(
                avatar: const Icon(Icons.edit_calendar_outlined, size: 18),
                label: Text(l.customRange),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: today,
                    initialDateRange: _range.end.isAfter(today) ? null : _range,
                  );
                  if (picked != null) setState(() => _range = picked);
                },
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: _previewPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(l.exportPdf),
          ),
          const SizedBox(height: 8),
          Text(l.exportPdfHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: _shareCsv,
            icon: const Icon(Icons.table_chart_outlined),
            label: Text(l.exportCsv),
          ),
        ],
      ),
    );
  }
}
