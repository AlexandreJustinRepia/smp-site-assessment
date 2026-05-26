import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';
import 'radio_grid.dart';

class RestorationSection extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const RestorationSection({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Recommended Restoration Approaches',
          icon: Icons.eco,
        ),
        const SizedBox(height: 8),
        FormRadioGrid(
          selectedValue: selectedValue,
          options: options,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
