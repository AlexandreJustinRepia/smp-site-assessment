import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';
import 'form_section_input.dart';

class ForestLitterSection extends StatelessWidget {
  final TextEditingController groundCoverCtrl;
  final TextEditingController avgDepthCtrl;
  final InputDecorationBuilder inputDecoration;

  const ForestLitterSection({
    super.key,
    required this.groundCoverCtrl,
    required this.avgDepthCtrl,
    required this.inputDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Forest Litter', icon: Icons.grass),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2E7D32), width: 1),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: groundCoverCtrl,
                        decoration: inputDecoration(
                          'Ground Cover %',
                          icon: Icons.percent,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final intVal = int.tryParse(value);
                          if (intVal == null) return 'Invalid number';
                          if (intVal > 100) return 'Max 100';
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (() {
                          final v = double.tryParse(groundCoverCtrl.text);
                          if (v == null) return 0.0;
                          return (v / 100).clamp(0.0, 1.0);
                        })(),
                        color: const Color(0xFF2E7D32),
                        backgroundColor: const Color(0xFFE8F5E9),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: avgDepthCtrl,
                        decoration: inputDecoration(
                          'Avg Depth (cm)',
                          icon: Icons.straighten,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (() {
                          final v = double.tryParse(avgDepthCtrl.text);
                          if (v == null) return 0.0;
                          return (v / 20).clamp(0.0, 1.0);
                        })(),
                        color: const Color(0xFF2E7D32),
                        backgroundColor: const Color(0xFFE8F5E9),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
