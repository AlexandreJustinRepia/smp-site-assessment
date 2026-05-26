import 'package:flutter/material.dart';
import '../models/assessment.dart';

class TreeInventoryTable extends StatelessWidget {
  final List<InventoryRow> rows;
  final ValueChanged<List<InventoryRow>> onChanged;

  const TreeInventoryTable({
    super.key,
    required this.rows,
    required this.onChanged,
  });

  void _updateRow(int index, InventoryRow updated) {
    final newRows = List<InventoryRow>.from(rows);
    newRows[index] = updated;
    onChanged(newRows);
  }

  void _addRow() {
    final newRows = List<InventoryRow>.from(rows)..add(InventoryRow());
    onChanged(newRows);
  }


  void _removeRow(int index) {
    final newRows = List<InventoryRow>.from(rows)..removeAt(index);
    onChanged(newRows);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 32, child: Text('No.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1B5E20)))),
                  Expanded(flex: 3, child: Text('Species', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1B5E20)))),
                  Expanded(flex: 2, child: Text('DBH', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1B5E20)))),
                  Expanded(flex: 2, child: Text('MH', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1B5E20)))),
                  Expanded(flex: 2, child: Text('TH', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1B5E20)))),
                  Expanded(flex: 3, child: Text('Remarks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1B5E20)))),
                  SizedBox(width: 32),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Rows
            ...List.generate(rows.length, (i) {
              final row = rows[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF33691E)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _MiniField(
                        value: row.species,
                        hint: 'Species',
                        onChanged: (v) => _updateRow(i, InventoryRow(species: v, dbh: row.dbh, mh: row.mh, th: row.th, remarks: row.remarks)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _MiniField(
                        value: row.dbh,
                        hint: 'cm',
                        onChanged: (v) => _updateRow(i, InventoryRow(species: row.species, dbh: v, mh: row.mh, th: row.th, remarks: row.remarks)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _MiniField(
                        value: row.mh,
                        hint: 'm',
                        onChanged: (v) => _updateRow(i, InventoryRow(species: row.species, dbh: row.dbh, mh: v, th: row.th, remarks: row.remarks)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _MiniField(
                        value: row.th,
                        hint: 'm',
                        onChanged: (v) => _updateRow(i, InventoryRow(species: row.species, dbh: row.dbh, mh: row.mh, th: v, remarks: row.remarks)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _MiniField(
                        value: row.remarks,
                        hint: 'Remarks',
                        onChanged: (v) => _updateRow(i, InventoryRow(species: row.species, dbh: row.dbh, mh: row.mh, th: row.th, remarks: v)),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.redAccent),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _removeRow(i),
                        tooltip: 'Remove row',
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            // Add row button
            TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Row'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  const _MiniField({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
          ),
        ),
      ),
    );
  }
}
