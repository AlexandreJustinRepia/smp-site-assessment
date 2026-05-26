import 'package:flutter/material.dart';

class FormRadioGrid extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const FormRadioGrid({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  IconData _getIconForOption(String option) {
    switch (option) {
      case 'Old Growth Forest':
        return Icons.park;
      case 'Industrial Forest Plantation':
        return Icons.precision_manufacturing;
      case 'Community-Based Forest':
        return Icons.people;
      case 'Agroforestry':
        return Icons.spa;
      case 'Degraded Forest':
        return Icons.warning_amber;
      case 'Residual Forest':
        return Icons.nature;
      case 'Open Forest':
        return Icons.forest;
      case 'Annual Crop':
        return Icons.agriculture;
      case 'Built-up':
        return Icons.home_work;
      case 'Monoculture':
        return Icons.agriculture;
      case 'Brushland/Shrub':
        return Icons.nature;
      case 'Perennial Crop':
        return Icons.agriculture;
      case 'Fishpond':
        return Icons.water;
      case 'Plantation':
        return Icons.forest;
      case 'Grassland':
        return Icons.grass;
      case 'Open/Barren':
        return Icons.terrain;
      case 'Inland Water':
        return Icons.water;
      case 'Assisted Natural Regeneration (ANR)':
        return Icons.auto_awesome;
      case 'Miyawaki Method':
        return Icons.grain;
      case 'Enrichment Planting':
        return Icons.forest;
      case 'Ecological Mangrove Restoration':
        return Icons.water;
      case 'Rainforestation Farming':
        return Icons.spa;
      case 'Natural Recovery':
        return Icons.restore;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;

            return GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: itemWidth,
                height: 85,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF388E3C),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconForOption(option),
                              size: 26,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF388E3C),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              option,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B5E20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
