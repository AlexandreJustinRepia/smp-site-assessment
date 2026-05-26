import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';

class TreeCrownCoverSection extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const TreeCrownCoverSection({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const unselectedColors = [
      Color(0xFFFFCDD2),
      Color(0xFFFFE0B2),
      Color(0xFFC8E6C9),
    ];
    const selectedColors = [
      Color(0xFFC62828),
      Color(0xFFE65100),
      Color(0xFF2E7D32),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Tree Crown Cover', icon: Icons.park),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: List.generate(options.length, (index) {
              final option = options[index];
              final isSelected = selectedValue == option;
              final bgColor = isSelected
                  ? selectedColors[index % selectedColors.length]
                  : unselectedColors[index % unselectedColors.length];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  child: Container(
                    height: 56,
                    color: bgColor,
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            option,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (selectedValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              selectedValue!,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
      ],
    );
  }
}
