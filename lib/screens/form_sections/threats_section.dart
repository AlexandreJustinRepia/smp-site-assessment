import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';
import 'form_section_input.dart';

class ThreatsSection extends StatelessWidget {
  final TextEditingController threatsCtrl;
  final InputDecorationBuilder inputDecoration;

  const ThreatsSection({
    super.key,
    required this.threatsCtrl,
    required this.inputDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Threats', icon: Icons.warning_amber),
        const SizedBox(height: 8),
        TextFormField(
          controller: threatsCtrl,
          decoration: inputDecoration(
            'Describe any threats observed',
            icon: Icons.report_problem,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          maxLines: 3,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
