import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';
import 'radio_grid.dart';

class RestorationSection extends StatelessWidget {
  final List<String> selectedValues;
  final List<String> options;
  final ValueChanged<String> onToggled;

  const RestorationSection({
    super.key,
    required this.selectedValues,
    required this.options,
    required this.onToggled,
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
        FormMultiSelectGrid(
          selectedValues: selectedValues,
          options: options,
          onToggled: onToggled,
        ),
      ],
    );
  }
}
