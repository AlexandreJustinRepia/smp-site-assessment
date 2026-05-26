import 'package:flutter/material.dart';

import '../../models/assessment.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tree_inventory_table.dart';

class InventorySection extends StatelessWidget {
  final List<InventoryRow> rows;
  final ValueChanged<List<InventoryRow>> onChanged;

  const InventorySection({
    super.key,
    required this.rows,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Inventory of Regenerants & Existing Trees',
          icon: Icons.table_chart,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF9A825).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Saplings (5-14 cm diameter) and Trees (>= 15 cm diameter)',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF33691E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TreeInventoryTable(rows: rows, onChanged: onChanged),
      ],
    );
  }
}
