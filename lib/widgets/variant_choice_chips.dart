import 'package:flutter/material.dart';

import '../src/responsive.dart';
import '../theme/appdrop_theme_scope.dart';
import '../utils/color.dart';

/// Theme-aware accent for variant chips, CTAs, and product selection sheet.
Color resolveAppDropPrimaryColor(BuildContext context) {
  final themeScope = AppDropThemeScope.maybeOf(context);
  if (themeScope != null) {
    final defaultColor = themeScope.appStyling.defaultColor;
    if (defaultColor != Colors.transparent) return defaultColor;

    final pb = themeScope.productBlock;
    final buttonStyleRaw = (pb['button_style'] ?? '').toString().toLowerCase();
    final buttonParts = buttonStyleRaw
        .split(RegExp(r'[_\-\s]+'))
        .where((e) => e.isNotEmpty)
        .toList();
    final buttonType = buttonParts.length > 1 ? buttonParts[1] : 'filled';
    final isOutlined = buttonType == 'outlined';

    if (isOutlined) {
      final outlined = parseHexColor(pb['outlined_button_color']?.toString());
      if (outlined != null) return outlined;
    }

    final filled = parseHexColor(pb['filled_button_bg']?.toString());
    if (filled != null) return filled;

    final bottomSelected = themeScope.appStyling.bottomSelected;
    if (bottomSelected != Colors.transparent) return bottomSelected;
  }

  return const Color(0xFF54A685);
}

Color resolveAppDropOnPrimaryColor(Color background) {
  return background.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
}

/// Material 3 pill chip for product variant selection.
class VariantChoiceChip extends StatelessWidget {
  const VariantChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.r,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final R r;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(r.dp(999));
    final textStyle = TextStyle(
      fontSize: r.sp(12, min: 11, max: 14),
      fontWeight: FontWeight.w500,
      color: isSelected ? Colors.white : const Color(0xFF374151),
    );

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : surfaceColor,
            borderRadius: radius,
            border: Border.all(
              color: isSelected ? primaryColor : borderColor,
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: r.dp(12),
            vertical: r.dp(6),
          ),
          child: Text(label, style: textStyle),
        ),
      ),
    );
  }
}

/// Responsive wrap of [VariantChoiceChip] rows for a variant dimension.
class VariantChoiceChipWrap extends StatelessWidget {
  const VariantChoiceChipWrap({
    super.key,
    required this.groupLabel,
    required this.variantLabels,
    required this.selectedIndex,
    required this.labelColor,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.r,
    required this.onSelect,
  });

  final String groupLabel;
  final List<String> variantLabels;
  final int selectedIndex;
  final Color labelColor;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final R r;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    if (variantLabels.isEmpty) return const SizedBox.shrink();

    final spacing = r.dp(6);
    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: r.sp(13, min: 12, max: 15),
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          groupLabel.isEmpty ? 'Variant' : groupLabel,
          style: labelStyle,
        ),
        SizedBox(height: r.dp(8)),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(variantLabels.length, (index) {
            return VariantChoiceChip(
              label: variantLabels[index],
              isSelected: index == selectedIndex,
              primaryColor: primaryColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              r: r,
              onSelected: () => onSelect(index),
            );
          }),
        ),
      ],
    );
  }
}
