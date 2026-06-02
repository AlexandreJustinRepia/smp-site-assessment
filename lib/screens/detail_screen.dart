import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../db/database_helper.dart';
import '../models/assessment.dart';
import '../services/user_access_service.dart';
import 'form_screen.dart';

class DetailScreen extends StatefulWidget {
  final Assessment assessment;
  final AppUserAccess access;

  const DetailScreen({
    super.key,
    required this.assessment,
    required this.access,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Assessment _assessment;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _assessment = widget.assessment;
  }

  Future<void> _refresh() async {
    final updated = await DatabaseHelper.instance.read(_assessment.id!);
    if (!mounted) return;
    if (updated != null) {
      setState(() => _assessment = updated);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Assessment'),
          ],
        ),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.delete(_assessment.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  Widget _buildFieldRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF1B5E20).withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData headerIcon,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.6),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(headerIcon, size: 18, color: const Color(0xFFF9A825)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label.isNotEmpty ? label : '—',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B5E20),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);

    final pdf = pw.Document();
    final a = _assessment;
    final inventory = a.inventoryRows;

    try {
      final logoBytes = await rootBundle.load('assets/images/logo/logo.png');
      final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
      const green = PdfColor.fromInt(0xFF1B5E20);
      const lightGreen = PdfColor.fromInt(0xFFE8F5E9);
      const gold = PdfColor.fromInt(0xFFF9A825);
      const muted = PdfColor.fromInt(0xFF607D66);
      const border = PdfColor.fromInt(0xFFD8E6D9);

      String valueOrDash(String value) => value.isNotEmpty ? value : '-';

      pw.Widget sectionTitle(String title) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            children: [
              pw.Container(width: 4, height: 14, color: gold),
              pw.SizedBox(width: 7),
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: green,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      pw.Widget fieldTile(String label, String value) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: border, width: 0.7),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label.toUpperCase(),
                style: pw.TextStyle(
                  color: muted,
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                valueOrDash(value),
                maxLines: 2,
                style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }

      pw.Widget infoGrid(List<List<String>> items) {
        return pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => pw.SizedBox(
                  width: 156,
                  child: fieldTile(item[0], item[1]),
                ),
              )
              .toList(),
        );
      }

      pw.Widget badge(String label, String value) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: lightGreen,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: border, width: 0.8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label.toUpperCase(),
                style: pw.TextStyle(
                  color: muted,
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                valueOrDash(value),
                style: pw.TextStyle(
                  color: green,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      pw.Widget noteBox(String title, String value) {
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFFFF8E1),
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFFFECB3)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF8A6D00),
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(valueOrDash(value), style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(30, 26, 30, 30),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SMP Site Assessment',
                style: pw.TextStyle(fontSize: 7, color: muted),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: muted),
              ),
            ],
          ),
          build: (pw.Context context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: green,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 46,
                    height: 46,
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SMP Site Assessment',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Site Monitoring Platform field assessment report',
                          style: const pw.TextStyle(
                            color: PdfColor.fromInt(0xFFA5D6A7),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(7),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ASSESSMENT DATE',
                          style: pw.TextStyle(
                            color: muted,
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          valueOrDash(a.date),
                          style: pw.TextStyle(
                            color: green,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            sectionTitle('Survey Information'),
            infoGrid([
              ['Grid No.', a.gridNo],
              ['Centroid No.', a.centroidNo],
              ['Elevation', a.elevation],
              ['Location', a.location],
              ['Target Coordinates', a.coordsTarget],
              ['Actual Coordinates', a.coordsActual],
              ['Team Members', a.teamMembers],
            ]),
            pw.SizedBox(height: 14),

            sectionTitle('Site Classification'),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: badge('Land Cover / Existing Land-Use', a.landCover),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: badge('Tree Crown Cover', a.treeCrownCover)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: badge('Forest Condition', a.forestCondition),
                ),
              ],
            ),
            if (a.forestConditionNotes.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              noteBox('Forest Condition Notes', a.forestConditionNotes),
            ],
            pw.SizedBox(height: 14),

            sectionTitle('Forest Litter'),
            infoGrid([
              ['Ground Cover %', a.forestLitterGroundCover],
              ['Average Depth (cm)', a.forestLitterAvgDepth],
            ]),
            pw.SizedBox(height: 12),

            noteBox('Threats', a.threats),
            pw.SizedBox(height: 14),

            sectionTitle('Inventory of Regenerants & Trees'),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: border, width: 0.6),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: pw.BoxDecoration(color: lightGreen),
              headerStyle: pw.TextStyle(
                color: green,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              headers: ['No.', 'Species', 'DBH', 'MH', 'TH', 'Remarks'],
              data: inventory.isEmpty
                  ? [
                      ['-', 'No inventory entries', '-', '-', '-', '-'],
                    ]
                  : inventory
                        .asMap()
                        .entries
                        .map(
                          (e) => [
                            '${e.key + 1}',
                            valueOrDash(e.value.species),
                            valueOrDash(e.value.dbh),
                            valueOrDash(e.value.mh),
                            valueOrDash(e.value.th),
                            valueOrDash(e.value.remarks),
                          ],
                        )
                        .toList(),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(2.6),
                2: const pw.FixedColumnWidth(42),
                3: const pw.FixedColumnWidth(34),
                4: const pw.FixedColumnWidth(34),
                5: const pw.FlexColumnWidth(2.2),
              },
            ),
            pw.SizedBox(height: 14),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: green,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 6, height: 26, color: gold),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RECOMMENDED RESTORATION APPROACHES',
                          style: const pw.TextStyle(
                            color: PdfColor.fromInt(0xFFA5D6A7),
                            fontSize: 7,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          valueOrDash(a.restorationApproaches.join(', ')),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      // Show preview / share using printing package
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Widget _buildPdfExportPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: Color(0xFFF9A825),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Preview, print, or share this assessment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFA5D6A7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _exportingPdf ? null : _exportPdf,
            icon: _exportingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.ios_share, size: 18),
            label: Text(_exportingPdf ? 'Preparing' : 'Export'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF9A825),
              disabledBackgroundColor: const Color(0xFFF9A825).withValues(
                alpha: 0.55,
              ),
              foregroundColor: const Color(0xFF1B5E20),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _assessment;
    final inventory = a.inventoryRows;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Details'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: _exportingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: _exportingPdf ? null : _exportPdf,
          ),
          if (widget.access.canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FormScreen(assessment: a)),
                );
                if (!mounted) return;
                _refresh();
              },
            ),
          if (widget.access.canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF1F8E9),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPdfExportPanel(),

          // Survey Information
          _buildSectionCard('Survey Information', Icons.info_outline, [
            _buildFieldRow('Grid No.', a.gridNo, Icons.grid_on),
            _buildFieldRow('Centroid No.', a.centroidNo, Icons.adjust),
            _buildFieldRow('Elevation', a.elevation, Icons.terrain),
            _buildFieldRow('Date', a.date, Icons.calendar_today),
            _buildFieldRow('Location', a.location, Icons.location_on),
            _buildFieldRow(
              'Coordinates (Target)',
              a.coordsTarget,
              Icons.my_location,
            ),
            _buildFieldRow(
              'Coordinates (Actual)',
              a.coordsActual,
              Icons.gps_fixed,
            ),
            _buildFieldRow('Team Members', a.teamMembers, Icons.group),
            if (a.createdByEmail.isNotEmpty)
              _buildFieldRow('Created By', a.createdByEmail, Icons.account_circle_outlined),
          ]),

          // Land Cover
          _buildSectionCard('Land Cover / Existing Land-Use', Icons.landscape, [
            _buildChip(a.landCover),
          ]),

          // Tree Crown Cover
          _buildSectionCard('Tree Crown Cover', Icons.park, [
            _buildChip(a.treeCrownCover),
          ]),

          // Forest Condition
          _buildSectionCard('Forest Condition', Icons.forest, [
            _buildChip(a.forestCondition),
            if (a.forestConditionNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildFieldRow('Notes', a.forestConditionNotes, Icons.edit_note),
            ],
          ]),

          // Forest Litter
          _buildSectionCard('Forest Litter', Icons.grass, [
            _buildFieldRow(
              'Ground Cover %',
              a.forestLitterGroundCover,
              Icons.percent,
            ),
            _buildFieldRow(
              'Average Depth (cm)',
              a.forestLitterAvgDepth,
              Icons.straighten,
            ),
          ]),

          // Threats
          _buildSectionCard('Threats', Icons.warning_amber, [
            _buildFieldRow('Threats', a.threats, Icons.report_problem),
          ]),

          // Inventory
          _buildSectionCard(
            'Inventory of Regenerants & Trees',
            Icons.table_chart,
            [
              if (inventory.isEmpty)
                const Text(
                  'No entries',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              else ...[
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          'No.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Species',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'DBH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'MH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'TH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Remarks',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ...List.generate(inventory.length, (i) {
                  final row = inventory[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF33691E),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            row.species.isNotEmpty ? row.species : '—',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            row.dbh.isNotEmpty ? row.dbh : '—',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            row.mh.isNotEmpty ? row.mh : '—',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            row.th.isNotEmpty ? row.th : '—',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            row.remarks.isNotEmpty ? row.remarks : '—',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),

          // Restoration
          _buildSectionCard('Recommended Restoration Approaches', Icons.eco, [
            if (a.restorationApproaches.isEmpty)
              _buildChip('-')
            else
              for (final approach in a.restorationApproaches)
                _buildChip(approach),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
