import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/assessment.dart';
import '../widgets/section_header.dart';
import '../widgets/radio_group.dart' show CustomRadioGroup;
import '../widgets/tree_inventory_table.dart';

class FormScreen extends StatefulWidget {
  final Assessment? assessment; // null = create, non-null = edit

  const FormScreen({super.key, this.assessment});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Header controllers
  late TextEditingController _gridNoCtrl;
  late TextEditingController _centroidNoCtrl;
  late TextEditingController _elevationCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _coordsTargetCtrl;
  late TextEditingController _coordsActualCtrl;
  late TextEditingController _teamMembersCtrl;

  // Radio selections
  String? _landCover;
  String? _treeCrownCover;
  String? _forestCondition;
  String? _restorationApproach;

  // Forest condition notes controller
  late TextEditingController _forestConditionNotesCtrl;

  // Forest litter controllers
  late TextEditingController _litterGroundCoverCtrl;
  late TextEditingController _litterAvgDepthCtrl;

  // Threats
  late TextEditingController _threatsCtrl;

  // Inventory
  List<InventoryRow> _inventoryRows = [];

  bool get _isEditing => widget.assessment != null;

  // Land cover options
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

  // Tree crown cover options
  static const _treeCrownCoverOptions = [
    'Closed Forest (≥40%)',
    'Open Forest (10-39%)',
    'Non-Forest (<10%)',
  ];

  // Forest condition options
  static const _forestConditionOptions = [
    'Old Growth Forest',
    'Industrial Forest Plantation',
    'Advance Secondary Growth Forest',
    'Open, Uncultivated Area',
    'Early Secondary Growth Forest',
    'Open, Cultivated Area',
  ];

  // Restoration options
  static const _restorationOptions = [
    'Assisted Natural Regeneration (ANR)',
    'Miyawaki Method',
    'Enrichment Planting',
    'Ecological Mangrove Restoration',
    'Rainforestation Farming',
    'Natural Recovery',
  ];

  void _onCtrlChanged() {
    if (mounted) setState(() {});
  }

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
    _forestConditionNotesCtrl = TextEditingController(
      text: a?.forestConditionNotes ?? '',
    );
    _litterGroundCoverCtrl = TextEditingController(
      text: a?.forestLitterGroundCover ?? '',
    );
    _litterAvgDepthCtrl = TextEditingController(
      text: a?.forestLitterAvgDepth ?? '',
    );
    _threatsCtrl = TextEditingController(text: a?.threats ?? '');

    _gridNoCtrl.addListener(_onCtrlChanged);
    _dateCtrl.addListener(_onCtrlChanged);

    _landCover = (a != null && a.landCover.isNotEmpty) ? a.landCover : null;
    _treeCrownCover = (a != null && a.treeCrownCover.isNotEmpty)
        ? a.treeCrownCover
        : null;
    _forestCondition = (a != null && a.forestCondition.isNotEmpty)
        ? a.forestCondition
        : null;
    _restorationApproach = (a != null && a.restorationApproach.isNotEmpty)
        ? a.restorationApproach
        : null;

    _inventoryRows = a?.inventoryRows ?? [InventoryRow()];
  }

  @override
  void dispose() {
    _gridNoCtrl.removeListener(_onCtrlChanged);
    _dateCtrl.removeListener(_onCtrlChanged);
    _gridNoCtrl.dispose();
    _centroidNoCtrl.dispose();
    _elevationCtrl.dispose();
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    _coordsTargetCtrl.dispose();
    _coordsActualCtrl.dispose();
    _teamMembersCtrl.dispose();
    _forestConditionNotesCtrl.dispose();
    _litterGroundCoverCtrl.dispose();
    _litterAvgDepthCtrl.dispose();
    _threatsCtrl.dispose();
    super.dispose();
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
    // Ensure all required radio selections are made
    if (_landCover == null ||
        _treeCrownCover == null ||
        _forestCondition == null ||
        _restorationApproach == null) {
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

    final assessment = Assessment(
      id: widget.assessment?.id,
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
      forestConditionNotes: _forestConditionNotesCtrl.text.trim(),
      forestLitterGroundCover: _litterGroundCoverCtrl.text.trim(),
      forestLitterAvgDepth: _litterAvgDepthCtrl.text.trim(),
      threats: _threatsCtrl.text.trim(),
      restorationApproach: _restorationApproach ?? '',
    );
    assessment.setInventoryRows(_inventoryRows);

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

  @override
  Widget build(BuildContext context) {
    final gridNo = _gridNoCtrl.text.trim();
    final date = _dateCtrl.text.trim();
    final breadcrumbText =
        "DENR Field Survey  ›  Grid ${gridNo.isEmpty ? '—' : gridNo}  ›  ${date.isEmpty ? '—' : date}";

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
                  // ── SECTION A: Header Information ──
                  const SectionHeader(
                    title: 'Survey Information',
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: 8),

                  // Row: Grid No, Centroid No
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _gridNoCtrl,
                          decoration: _inputDecoration(
                            'Grid No.',
                            icon: Icons.grid_on,
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : null,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _centroidNoCtrl,
                          decoration: _inputDecoration(
                            'Centroid No.',
                            icon: Icons.adjust,
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : null,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row: Elevation, Date
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _elevationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Elevation',
                            icon: Icons.terrain,
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : null,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FormField<String>(
                          initialValue: _dateCtrl.text,
                          validator: (value) =>
                              _dateCtrl.text.isEmpty ? 'Required' : null,
                          builder: (FormFieldState<String> state) {
                            return InkWell(
                              onTap: () async {
                                await _pickDate();
                                state.didChange(_dateCtrl.text);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: InputDecorator(
                                decoration: _inputDecoration(
                                  'Date',
                                  icon: Icons.calendar_today,
                                ).copyWith(errorText: state.errorText),
                                child: Text(
                                  _dateCtrl.text.isEmpty
                                      ? 'Select Date'
                                      : _dateCtrl.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _dateCtrl.text.isEmpty
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: _inputDecoration('Location', icon: Icons.place),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _coordsTargetCtrl,
                    decoration: _inputDecoration(
                      'Coordinates (Target)',
                      icon: Icons.my_location,
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _coordsActualCtrl,
                    decoration: _inputDecoration(
                      'Coordinates (Actual)',
                      icon: Icons.gps_fixed,
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _teamMembersCtrl,
                    decoration: _inputDecoration(
                      'Team Members',
                      icon: Icons.group,
                      hintText: 'Enter names separated by comma',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                  ),

                  // ── SECTION B: Land Cover (Radio) ──
                  const SectionHeader(
                    title: 'Land Cover / Existing Land-Use',
                    icon: Icons.landscape,
                  ),
                  const SizedBox(height: 8),
                  _RadioGridWidget(
                    selectedValue: _landCover,
                    options: _landCoverOptions,
                    onChanged: (v) => setState(() => _landCover = v),
                  ),

                  // ── SECTION C: Tree Crown Cover (Radio) ──
                  const SectionHeader(
                    title: 'Tree Crown Cover',
                    icon: Icons.park,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: List.generate(_treeCrownCoverOptions.length, (index) {
                        final option = _treeCrownCoverOptions[index];
                        final isSelected = _treeCrownCover == option;
                        // Color palettes matching the three segments; use modulo to avoid out-of-range if list length varies
                        final List<Color> unselectedColors = const [
                          Color(0xFFFFCDD2),
                          Color(0xFFFFE0B2),
                          Color(0xFFC8E6C9),
                        ];
                        final List<Color> selectedColors = const [
                          Color(0xFFC62828),
                          Color(0xFFE65100),
                          Color(0xFF2E7D32),
                        ];
                        final bgColor = isSelected
                            ? selectedColors[index % selectedColors.length]
                            : unselectedColors[index % unselectedColors.length];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _treeCrownCover = option),
                            child: Container(
                              height: 56,
                              color: bgColor,
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      const Icon(Icons.check, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      option,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Descriptive text for selected option
                  if (_treeCrownCover != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _treeCrownCover!,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),

                  // ── SECTION D: Forest Condition (Radio + Notes) ──
                  const SectionHeader(
                    title: 'Forest Condition',
                    icon: Icons.forest,
                  ),
                  const SizedBox(height: 8),
                  CustomRadioGroup(
                    selectedValue: _forestCondition,
                    options: _forestConditionOptions,
                    crossAxisCount: 2,
                    onChanged: (v) => setState(() => _forestCondition = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _forestConditionNotesCtrl,
                    decoration: _inputDecoration(
                      'Additional Notes / Description',
                      icon: Icons.edit_note,
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                  ),

                  // ── SECTION E: Forest Litter (Fillable) ──
                  const SectionHeader(
                    title: 'Forest Litter',
                    icon: Icons.grass,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _litterGroundCoverCtrl,
                              decoration: _inputDecoration(
                                'Ground Cover %',
                                icon: Icons.percent,
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _litterAvgDepthCtrl,
                              decoration: _inputDecoration(
                                'Avg Depth (cm)',
                                icon: Icons.straighten,
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── SECTION F: Threats ──
                  const SectionHeader(
                    title: 'Threats',
                    icon: Icons.warning_amber,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _threatsCtrl,
                    decoration: _inputDecoration(
                      'Describe any threats observed',
                      icon: Icons.report_problem,
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                  ),

                  // ── SECTION G: Inventory ──
                  const SectionHeader(
                    title: 'Inventory of Regenerants & Existing Trees',
                    icon: Icons.table_chart,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9A825).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Saplings (5–14 cm diameter) and Trees (≥ 15 cm diameter)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF33691E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TreeInventoryTable(
                    rows: _inventoryRows,
                    onChanged: (rows) => setState(() => _inventoryRows = rows),
                  ),

                  // ── SECTION H: Restoration Approaches (Radio) ──
                  const SectionHeader(
                    title: 'Recommended Restoration Approaches',
                    icon: Icons.eco,
                  ),
                  const SizedBox(height: 8),
                  CustomRadioGroup(
                    selectedValue: _restorationApproach,
                    options: _restorationOptions,
                    crossAxisCount: 2,
                    onChanged: (v) => setState(() => _restorationApproach = v),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      // Save button at bottom
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

class _RadioGridWidget extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _RadioGridWidget({
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  IconData _getIconForOption(String option) {
    switch (option) {
      case 'Open Forest':
        return Icons.forest;
      case 'Annual Crop':
        return Icons.agriculture;
      case 'Built-up':
        return Icons.home_work;
      case 'Monoculture':
        return Icons.agriculture;
      case 'Brushland/Shrub':
        return Icons.nature;
      case 'Perennial Crop':
        return Icons.agriculture;
      case 'Fishpond':
        return Icons.water;
      case 'Plantation':
        return Icons.forest;
      case 'Grassland':
        return Icons.grass;
      case 'Open/Barren':
        return Icons.terrain;
      case 'Inland Water':
        return Icons.water;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item width for a 2-column grid inside Wrap (spacing is 8)
        final itemWidth = (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;

            return GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: itemWidth,
                height: 85,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF388E3C),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Content
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconForOption(option),
                              size: 26,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF388E3C),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              option,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Check Badge
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B5E20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
