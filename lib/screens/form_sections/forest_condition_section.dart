import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';
import 'form_section_input.dart';
import 'radio_grid.dart';

class ForestConditionSection extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final TextEditingController notesCtrl;
  final InputDecorationBuilder inputDecoration;
  final bool isListening;
  final VoidCallback onListen;

  const ForestConditionSection({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    required this.notesCtrl,
    required this.inputDecoration,
    required this.isListening,
    required this.onListen,
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
        const SizedBox(height: 12),
        TextFormField(
          controller: notesCtrl,
          decoration: inputDecoration(
            'Forest Condition Notes',
            icon: Icons.notes,
            hintText: 'Add observations',
            suffix: IconButton(
              onPressed: onListen,
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: isListening
                    ? const Color(0xFFC62828)
                    : const Color(0xFF1B5E20),
              ),
              tooltip: isListening ? 'Stop listening' : 'Add notes by voice',
            ),
          ),
          maxLines: 3,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
