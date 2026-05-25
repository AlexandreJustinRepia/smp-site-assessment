import 'package:flutter/material.dart';

class CustomRadioGroup extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final int crossAxisCount;

  const CustomRadioGroup({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: _buildRows(),
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];
    for (int i = 0; i < options.length; i += crossAxisCount) {
      final end = (i + crossAxisCount > options.length)
          ? options.length
          : i + crossAxisCount;
      final rowOptions = options.sublist(i, end);

      rows.add(
        Row(
          children: rowOptions.map((option) {
            final isSelected = selectedValue == option;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onChanged(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1B5E20)
                                : Colors.grey.shade400,
                            width: isSelected ? 2 : 1.5,
                          ),
                          color: isSelected
                              ? const Color(0xFF1B5E20).withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF1B5E20)
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
    return rows;
  }
}
