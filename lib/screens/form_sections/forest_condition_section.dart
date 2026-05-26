import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';
import 'radio_grid.dart';

class ForestConditionSection extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const ForestConditionSection({
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
        const SectionHeader(title: 'Forest Condition', icon: Icons.forest),
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
