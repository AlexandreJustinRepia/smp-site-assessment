import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';
import 'form_section_input.dart';

class SurveyInformationSection extends StatelessWidget {
  final TextEditingController gridNoCtrl;
  final TextEditingController centroidNoCtrl;
  final TextEditingController elevationCtrl;
  final TextEditingController dateCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController coordsTargetCtrl;
  final TextEditingController coordsActualCtrl;
  final TextEditingController teamMembersCtrl;
  final InputDecorationBuilder inputDecoration;
  final Future<void> Function() onPickDate;

  const SurveyInformationSection({
    super.key,
    required this.gridNoCtrl,
    required this.centroidNoCtrl,
    required this.elevationCtrl,
    required this.dateCtrl,
    required this.locationCtrl,
    required this.coordsTargetCtrl,
    required this.coordsActualCtrl,
    required this.teamMembersCtrl,
    required this.inputDecoration,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Survey Information',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: gridNoCtrl,
                decoration: inputDecoration('Grid No.', icon: Icons.grid_on),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: centroidNoCtrl,
                decoration: inputDecoration('Centroid No.', icon: Icons.adjust),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: elevationCtrl,
                keyboardType: TextInputType.number,
                decoration: inputDecoration('Elevation', icon: Icons.terrain),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormField<String>(
                initialValue: dateCtrl.text,
                validator: (value) => dateCtrl.text.isEmpty ? 'Required' : null,
                builder: (state) {
                  return InkWell(
                    onTap: () async {
                      await onPickDate();
                      state.didChange(dateCtrl.text);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: inputDecoration(
                        'Date',
                        icon: Icons.calendar_today,
                      ).copyWith(errorText: state.errorText),
                      child: Text(
                        dateCtrl.text.isEmpty ? 'Select Date' : dateCtrl.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: dateCtrl.text.isEmpty
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
          controller: locationCtrl,
          decoration: inputDecoration('Location', icon: Icons.place),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: coordsTargetCtrl,
          decoration: inputDecoration(
            'Coordinates (Target)',
            icon: Icons.my_location,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: coordsActualCtrl,
          decoration: inputDecoration(
            'Coordinates (Actual)',
            icon: Icons.gps_fixed,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: teamMembersCtrl,
          decoration: inputDecoration(
            'Team Members',
            icon: Icons.group,
            hintText: 'Enter names separated by comma',
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
