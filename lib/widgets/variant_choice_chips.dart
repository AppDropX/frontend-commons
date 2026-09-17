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
    this.cornerRadiusDp = 24,
    this.innerTextColor = const Color(0xFF374151),
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.isOutOfStock = false,
  });

  final String label;
  final bool isSelected;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final R r;
  final VoidCallback onSelected;
  final double cornerRadiusDp;
  final Color innerTextColor;
  final Color? selectedBackgroundColor;
  final Color? selectedForegroundColor;
  final bool isOutOfStock;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(r.dp(cornerRadiusDp.clamp(0, 24).toDouble()));
    final selectedBg = selectedBackgroundColor ?? primaryColor;
    final selectedFg =
        selectedForegroundColor ?? resolveAppDropOnPrimaryColor(selectedBg);
    final showSelected = isSelected && !isOutOfStock;
    final muted = innerTextColor.withValues(alpha: 0.55);
    final textStyle = TextStyle(
      fontSize: r.sp(12, min: 11, max: 14),
      fontWeight: FontWeight.w500,
      color: isOutOfStock ? muted : (showSelected ? selectedFg : innerTextColor),
      decoration: isOutOfStock ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: muted,
    );

    return Semantics(
      button: !isOutOfStock,
      enabled: !isOutOfStock,
      selected: showSelected,
      label: isOutOfStock ? '$label, out of stock' : label,
      child: Opacity(
        opacity: isOutOfStock ? 0.45 : 1,
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          child: InkWell(
            onTap: isOutOfStock ? null : onSelected,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                color: showSelected ? selectedBg : surfaceColor,
                borderRadius: radius,
                border: Border.all(
                  color: showSelected ? selectedBg : borderColor,
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
    this.cornerRadiusDp = 24,
    this.innerTextColor = const Color(0xFF374151),
    this.remainingLabels,
    this.remainingStockColor = const Color(0xFFDC2626),
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.outOfStockFlags,
    this.showOutOfStock = true,
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
  final double cornerRadiusDp;
  final Color innerTextColor;
  final List<String?>? remainingLabels;
  final Color remainingStockColor;
  final Color? selectedBackgroundColor;
  final Color? selectedForegroundColor;
  final List<bool>? outOfStockFlags;
  final bool showOutOfStock;

  bool _isOutOfStock(int index) {
    final flags = outOfStockFlags;
    if (flags == null || index < 0 || index >= flags.length) return false;
    return flags[index];
  }

  @override
  Widget build(BuildContext context) {
    if (variantLabels.isEmpty) return const SizedBox.shrink();

    final spacing = r.dp(6);
    final hasAnyRemaining = remainingLabels?.any(
          (label) => label != null && label.isNotEmpty,
        ) ??
        false;
    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: r.sp(11, min: 10, max: 13),
      fontWeight: FontWeight.w400,
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
          runSpacing: hasAnyRemaining ? r.dp(12) : spacing,
          children: [
            for (var index = 0; index < variantLabels.length; index++)
              if (showOutOfStock || !_isOutOfStock(index))
                _chipColumn(index),
          ],
        ),
      ],
    );
  }

  Widget _chipColumn(int index) {
    final remaining = remainingLabels != null && index < remainingLabels!.length
        ? remainingLabels![index]
        : null;
    final hasRemaining = remaining != null && remaining.isNotEmpty;
    final oos = _isOutOfStock(index);
    return GestureDetector(
      onTap: oos ? null : () => onSelect(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VariantChoiceChip(
            label: variantLabels[index],
            isSelected: index == selectedIndex,
            primaryColor: primaryColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            r: r,
            onSelected: () => onSelect(index),
            cornerRadiusDp: cornerRadiusDp,
            innerTextColor: innerTextColor,
            selectedBackgroundColor: selectedBackgroundColor,
            selectedForegroundColor: selectedForegroundColor,
            isOutOfStock: oos,
          ),
          if (hasRemaining) ...[
            SizedBox(height: r.dp(4)),
            Semantics(
              label: remaining,
              child: Text(
                remaining,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.sp(10, min: 9, max: 12),
                  fontWeight: FontWeight.w600,
                  color: remainingStockColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
