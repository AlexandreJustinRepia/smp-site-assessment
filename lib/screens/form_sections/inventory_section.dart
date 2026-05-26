import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';

class InventorySection extends StatelessWidget {
  final List<Map<String, String>> rows;
  final ValueChanged<List<Map<String, String>>> onChanged;

  const InventorySection({
    super.key,
    required this.rows,
    required this.onChanged,
  });



  void _updateRow(int index, String key, String value) {
    final updatedRows = rows
        .map((row) => Map<String, String>.from(row))
        .toList();
    updatedRows[index][key] = value;
    onChanged(updatedRows);
  }

  void _addRow() {
    onChanged([
      ...rows,
      _emptyRow(),
    ]);
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete row?'),
          content: Text('Remove inventory row ${index + 1}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    final updatedRows =
        rows.map((row) => Map<String, String>.from(row)).toList()
          ..removeAt(index);
    onChanged(updatedRows.isEmpty ? [_emptyRow()] : updatedRows);
  }

  Map<String, String> _emptyRow() => {
    'id': UniqueKey().toString(),
    'species': '',
    'dbh': '',
    'mh': '',
    'th': '',
    'remarks': '',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Inventory of Regenerants (Saplings w/ 5-14 cm diameter) and Existing Trees (≥ 15 cm diameter)',
          icon: Icons.table_chart,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.orange[900]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saplings: 5–14 cm DBH   |   Trees: ≥ 15 cm DBH',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: List.generate(rows.length, (index) {
                    final row = rows[index];
                    return _InventoryRowCard(
                      key: ValueKey(row['id'] ?? index.toString()),
                      index: index,
                      row: row,
                      onChanged: (key, value) => _updateRow(index, key, value),
                      onDelete: () => _confirmDelete(context, index),
                    );
                  }),
                ),
              ),
            ),
          ),

        TextButton.icon(
          onPressed: _addRow,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Row'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B5E20)),
        ),
      ],
    );
  }
}

class _InventoryRowCard extends StatelessWidget {
  final int index;
  final Map<String, String> row;
  final void Function(String key, String value) onChanged;
  final VoidCallback onDelete;

  const _InventoryRowCard({
    super.key,
    required this.index,
    required this.row,
    required this.onChanged,
    required this.onDelete,
  });

  String? get _dbhError {
    final value = row['dbh'] ?? '';
    if (value.trim().isEmpty) return null;
    final dbh = double.tryParse(value);
    if (dbh == null) return null;
    return dbh < 5 ? 'Min 5cm' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _InventoryField(
                value: row['species'] ?? '',
                hint: 'Species',
                onChanged: (value) => onChanged('species', value),
              ),
            ),
            Expanded(
              flex: 2,
              child: _InventoryField(
                value: row['dbh'] ?? '',
                hint: 'DBH',
                keyboardType: TextInputType.number,
                errorText: _dbhError,
                onChanged: (value) => onChanged('dbh', value),
              ),
            ),
            Expanded(
              flex: 2,
              child: _InventoryField(
                value: row['mh'] ?? '',
                hint: 'MH',
                keyboardType: TextInputType.number,
                onChanged: (value) => onChanged('mh', value),
              ),
            ),
            Expanded(
              flex: 2,
              child: _InventoryField(
                value: row['th'] ?? '',
                hint: 'TH',
                keyboardType: TextInputType.number,
                onChanged: (value) => onChanged('th', value),
              ),
            ),
            Expanded(
              flex: 2,
              child: _InventoryField(
                value: row['remarks'] ?? '',
                hint: 'Remarks',
                onChanged: (value) => onChanged('remarks', value),
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.remove_circle_outline, color: Colors.red[300]),
              tooltip: 'Delete row',
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryField extends StatelessWidget {
  final String value;
  final String hint;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _InventoryField({
    required this.value,
    required this.hint,
    this.keyboardType,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
          errorStyle: TextStyle(color: Colors.red[700], fontSize: 10),
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: errorText == null ? Colors.grey.shade300 : Colors.red,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: errorText == null ? const Color(0xFF1B5E20) : Colors.red,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
