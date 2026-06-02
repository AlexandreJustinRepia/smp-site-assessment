import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/assessment.dart';
import '../services/user_access_service.dart';
import 'form_sections/forest_condition_section.dart';
import 'form_sections/forest_litter_section.dart';
import 'form_sections/inventory_section.dart';
import 'form_sections/land_cover_section.dart';
import 'form_sections/restoration_section.dart';
import 'form_sections/survey_information_section.dart';
import 'form_sections/threats_section.dart';
import 'form_sections/tree_crown_cover_section.dart';

class FormScreen extends StatefulWidget {
  final Assessment? assessment;

  const FormScreen({super.key, this.assessment});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late TextEditingController _gridNoCtrl;
  late TextEditingController _centroidNoCtrl;
  late TextEditingController _elevationCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _coordsTargetCtrl;
  late TextEditingController _coordsActualCtrl;
  late TextEditingController _teamMembersCtrl;
  late TextEditingController _litterGroundCoverCtrl;
  late TextEditingController _litterAvgDepthCtrl;
  late TextEditingController _threatsCtrl;

  List<Map<String, String>> _inventoryRows = [];

  bool get _isEditing => widget.assessment != null;
  String? _landCover;
  String? _treeCrownCover;
  String? _forestCondition;
  List<String> _restorationApproaches = [];

  static const _landCoverOptions = [
    'Open Forest',
    'Annual Crop',
    'Built-up',
    'Monoculture',
    'Brushland/Shrub',
    'Perennial Crop',
    'Fishpond',
    'Plantation',
    'Grassland',
    'Open/Barren',
    'Inland Water',
  ];

  static const _treeCrownCoverOptions = [
    'Closed Forest (>=40%)',
    'Open Forest (10-39%)',
    'Non-Forest (<10%)',
  ];

  static const _forestConditionOptions = [
    'Old Growth Forest',
    'Advance Secondary Growth Forest',
    'Early Secondary Growth Forest',
    'Industrial Forest Plantation',
    'Open, Uncultivated Area',
    'Open, Cultivated Area',
  ];

  static const _restorationOptions = [
    'Assisted Natural Regeneration (ANR)',
    'Miyawaki Method',
    'Enrichment Planting',
    'Ecological Mangrove Restoration',
    'Rainforestation Farming',
    'Natural Recovery',
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.assessment;

    _gridNoCtrl = TextEditingController(text: a?.gridNo ?? '');
    _centroidNoCtrl = TextEditingController(text: a?.centroidNo ?? '');
    _elevationCtrl = TextEditingController(text: a?.elevation ?? '');
    _dateCtrl = TextEditingController(text: a?.date ?? '');
    _locationCtrl = TextEditingController(text: a?.location ?? '');
    _coordsTargetCtrl = TextEditingController(text: a?.coordsTarget ?? '');
    _coordsActualCtrl = TextEditingController(text: a?.coordsActual ?? '');
    _teamMembersCtrl = TextEditingController(text: a?.teamMembers ?? '');
    _litterGroundCoverCtrl = TextEditingController(
      text: a?.forestLitterGroundCover ?? '',
    );
    _litterAvgDepthCtrl = TextEditingController(
      text: a?.forestLitterAvgDepth ?? '',
    );
    _threatsCtrl = TextEditingController(text: a?.threats ?? '');

    _gridNoCtrl.addListener(_onCtrlChanged);
    _dateCtrl.addListener(_onCtrlChanged);
    _litterGroundCoverCtrl.addListener(_onCtrlChanged);
    _litterAvgDepthCtrl.addListener(_onCtrlChanged);

    _landCover = (a != null && a.landCover.isNotEmpty) ? a.landCover : null;
    _treeCrownCover = (a != null && a.treeCrownCover.isNotEmpty)
        ? a.treeCrownCover
        : null;
    _forestCondition = (a != null && a.forestCondition.isNotEmpty)
        ? a.forestCondition
        : null;
    _restorationApproaches = a?.restorationApproaches ?? [];
    _inventoryRows =
        a?.inventoryRows
            .map(
              (row) => {
                'id': '${row.species}_${row.dbh}_${UniqueKey()}',
                'species': row.species,
                'dbh': row.dbh,
                'mh': row.mh,
                'th': row.th,
                'remarks': row.remarks,
              },
            )
            .toList() ??
        [_emptyInventoryRow()];
  }

  @override
  void dispose() {
    _gridNoCtrl.removeListener(_onCtrlChanged);
    _dateCtrl.removeListener(_onCtrlChanged);
    _litterGroundCoverCtrl.removeListener(_onCtrlChanged);
    _litterAvgDepthCtrl.removeListener(_onCtrlChanged);

    _gridNoCtrl.dispose();
    _centroidNoCtrl.dispose();
    _elevationCtrl.dispose();
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    _coordsTargetCtrl.dispose();
    _coordsActualCtrl.dispose();
    _teamMembersCtrl.dispose();
    _litterGroundCoverCtrl.dispose();
    _litterAvgDepthCtrl.dispose();
    _threatsCtrl.dispose();
    super.dispose();
  }

  void _onCtrlChanged() {
    if (mounted) setState(() {});
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? icon,
    Widget? suffix,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF558B2F)),
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: const Color(0xFF1B5E20))
          : null,
      suffixIcon: suffix,
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B5E20),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_landCover == null ||
        _treeCrownCover == null ||
        _forestCondition == null ||
        _restorationApproaches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields'),
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final currentUser = UserAccessService.instance.currentUser;
    final createdByUid = widget.assessment?.createdByUid ?? currentUser?.uid ?? '';
    final createdByEmail = widget.assessment?.createdByEmail ?? currentUser?.email ?? '';

    final assessment = Assessment(
      id: widget.assessment?.id,
      firestoreId: widget.assessment?.firestoreId,
      updatedAt: widget.assessment?.updatedAt,
      gridNo: _gridNoCtrl.text.trim(),
      centroidNo: _centroidNoCtrl.text.trim(),
      elevation: _elevationCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      coordsTarget: _coordsTargetCtrl.text.trim(),
      coordsActual: _coordsActualCtrl.text.trim(),
      teamMembers: _teamMembersCtrl.text.trim(),
      landCover: _landCover ?? '',
      treeCrownCover: _treeCrownCover ?? '',
      forestCondition: _forestCondition ?? '',
      forestConditionNotes: '',
      forestLitterGroundCover: _litterGroundCoverCtrl.text.trim(),
      forestLitterAvgDepth: _litterAvgDepthCtrl.text.trim(),
      threats: _threatsCtrl.text.trim(),
      restorationRationale: '',
      createdByUid: createdByUid,
      createdByEmail: createdByEmail,
    );
    assessment.setRestorationApproaches(_restorationApproaches);
    assessment.setInventoryRows(
      _inventoryRows
          .map(
            (row) => InventoryRow(
              species: row['species'] ?? '',
              dbh: row['dbh'] ?? '',
              mh: row['mh'] ?? '',
              th: row['th'] ?? '',
              remarks: row['remarks'] ?? '',
            ),
          )
          .toList(),
    );

    if (_isEditing) {
      await DatabaseHelper.instance.update(assessment);
    } else {
      await DatabaseHelper.instance.create(assessment);
    }

    setState(() => _saving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Assessment updated!' : 'Assessment saved!'),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context, true);
  }

  Map<String, String> _emptyInventoryRow() => {
    'id': UniqueKey().toString(),
    'species': '',
    'dbh': '',
    'mh': '',
    'th': '',
    'remarks': '',
  };

  @override
  Widget build(BuildContext context) {
    final gridNo = _gridNoCtrl.text.trim();
    final date = _dateCtrl.text.trim();
    final breadcrumbText =
        "DENR Field Survey > Grid ${gridNo.isEmpty ? '-' : gridNo} > ${date.isEmpty ? '-' : date}";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Assessment' : 'New Assessment',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          const Icon(Icons.cloud_off, color: Colors.white70),
          const SizedBox(width: 4),
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Save',
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF1F8E9),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1B5E20),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              breadcrumbText,
              style: const TextStyle(
                color: Color(0xFFA5D6A7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
                children: [
                  SurveyInformationSection(
                    gridNoCtrl: _gridNoCtrl,
                    centroidNoCtrl: _centroidNoCtrl,
                    elevationCtrl: _elevationCtrl,
                    dateCtrl: _dateCtrl,
                    locationCtrl: _locationCtrl,
                    coordsTargetCtrl: _coordsTargetCtrl,
                    coordsActualCtrl: _coordsActualCtrl,
                    teamMembersCtrl: _teamMembersCtrl,
                    inputDecoration: _inputDecoration,
                    onPickDate: _pickDate,
                  ),
                  const SizedBox(height: 20),
                  LandCoverSection(
                    selectedValue: _landCover,
                    options: _landCoverOptions,
                    onChanged: (v) => setState(() => _landCover = v),
                  ),
                  const SizedBox(height: 20),
                  TreeCrownCoverSection(
                    selectedValue: _treeCrownCover,
                    options: _treeCrownCoverOptions,
                    onChanged: (v) => setState(() => _treeCrownCover = v),
                  ),
                  const SizedBox(height: 20),
                  ForestConditionSection(
                    selectedValue: _forestCondition,
                    options: _forestConditionOptions,
                    onChanged: (v) => setState(() => _forestCondition = v),
                  ),
                  const SizedBox(height: 20),
                  ForestLitterSection(
                    groundCoverCtrl: _litterGroundCoverCtrl,
                    avgDepthCtrl: _litterAvgDepthCtrl,
                    inputDecoration: _inputDecoration,
                  ),
                  const SizedBox(height: 20),
                  ThreatsSection(
                    threatsCtrl: _threatsCtrl,
                    inputDecoration: _inputDecoration,
                  ),
                  const SizedBox(height: 20),
                  InventorySection(
                    rows: _inventoryRows,
                    onChanged: (rows) => setState(() => _inventoryRows = rows),
                  ),
                  const SizedBox(height: 20),
                  RestorationSection(
                    selectedValues: _restorationApproaches,
                    options: _restorationOptions,
                    onToggled: (value) {
                      setState(() {
                        if (_restorationApproaches.contains(value)) {
                          _restorationApproaches = _restorationApproaches
                              .where((item) => item != value)
                              .toList();
                        } else {
                          _restorationApproaches = [
                            ..._restorationApproaches,
                            value,
                          ];
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _saving
                  ? 'Saving...'
                  : _isEditing
                  ? 'Update Assessment'
                  : 'Save Assessment',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }
}
