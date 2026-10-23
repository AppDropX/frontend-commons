import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

import '../pdp/pdp_product_scope.dart';
import '../product/product_variant_model.dart';
import '../src/responsive.dart';
import '../theme/appdrop_theme_data.dart';
import '../theme/appdrop_theme_scope.dart';

/// Closed field shows the hint until a choice, then the selected option.
/// Sold-out options stay in the menu, dull and disabled.
class VariantDropdown extends StatefulWidget {
  const VariantDropdown({
    super.key,
    required this.hint,
    required this.variants,
    required this.unavailableLabel,
    required this.hintFontVariation,
    required this.hintSize,
    required this.optionFontVariation,
    required this.optionSize,
    required this.cornerRadius,
    required this.r,
    required this.onSelect,
  });

  final String hint;
  final List<ProductVariantOption> variants;
  final String unavailableLabel;
  final String hintFontVariation;
  final double hintSize;
  final String optionFontVariation;
  final double optionSize;
  final double cornerRadius;
  final R r;
  final ValueChanged<int> onSelect;

  @override
  State<VariantDropdown> createState() => _VariantDropdownState();
}

class _VariantDropdownState extends State<VariantDropdown> {
  int? _picked;

  @override
  void didUpdateWidget(covariant VariantDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final picked = _picked;
    if (picked == null) return;
    if (picked < 0 ||
        picked >= widget.variants.length ||
        widget.variants[picked].isOutOfStock) {
      _picked = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final family =
        AppDropThemeScope.maybeOf(context)?.appStyling.fontFamily ?? 'Poppins';
    final hintStyle = _style(
      family: family,
      size: widget.r.sp(widget.hintSize, min: 12, max: 20),
      variation: widget.hintFontVariation,
      color: const Color(0xFF9CA3AF),
    );
    final optionStyle = _style(
      family: family,
      size: widget.r.sp(widget.optionSize, min: 12, max: 20),
      variation: widget.optionFontVariation,
      color: const Color(0xFF111827),
    );
    final dullStyle = optionStyle.copyWith(color: const Color(0xFF9CA3AF));
    final radius = BorderRadius.circular(
      widget.r.dp(widget.cornerRadius.clamp(0, 24).toDouble()),
    );
    final scope = PdpProductScope.maybeOf(context);
    final int? picked = scope != null
        ? (scope.hasSelection ? scope.selectedIndex : null)
        : _picked;

    return DropdownButtonHideUnderline(
      child: DropdownButton2<int>(
        value: picked,
        isExpanded: true,
        hint: Text(
          widget.hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: hintStyle,
        ),
        selectedItemBuilder: (context) {
          return [
            for (final variant in widget.variants)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  variant.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: optionStyle,
                ),
              ),
          ];
        },
        items: [
          for (var index = 0; index < widget.variants.length; index++)
            _menuItem(
              index: index,
              variant: widget.variants[index],
              optionStyle: optionStyle,
              dullStyle: dullStyle,
            ),
        ],
        onChanged: (index) {
          if (index == null) return;
          if (widget.variants[index].isOutOfStock) return;
          setState(() => _picked = index);
          widget.onSelect(index);
        },
        isDense: true,
        buttonStyleData: ButtonStyleData(
          height: widget.r.dp(40),
          padding: EdgeInsets.symmetric(horizontal: widget.r.dp(8)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFBDBDBD)),
          ),
          elevation: 0,
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
          iconSize: 20,
        ),
        dropdownStyleData: DropdownStyleData(
          elevation: 2,
          padding: EdgeInsets.zero,
          offset: Offset(0, widget.r.dp(4)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
          ),
        ),
        menuItemStyleData: MenuItemStyleData(
          height: widget.r.dp(36),
          padding: EdgeInsets.symmetric(horizontal: widget.r.dp(8)),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused) ||
                states.contains(WidgetState.pressed)) {
              return const Color(0xFFF3F4F6);
            }
            return null;
          }),
          selectedMenuItemBuilder: (context, child) {
            return ColoredBox(
              color: const Color(0xFFF3F4F6),
              child: child,
            );
          },
        ),
      ),
    );
  }

  DropdownMenuItem<int> _menuItem({
    required int index,
    required ProductVariantOption variant,
    required TextStyle optionStyle,
    required TextStyle dullStyle,
  }) {
    final soldOut = variant.isOutOfStock;
    final note = widget.unavailableLabel;
    return DropdownMenuItem<int>(
      value: index,
      enabled: !soldOut,
      child: Row(
        children: [
          Expanded(
            child: Text(
              variant.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: soldOut ? dullStyle : optionStyle,
            ),
          ),
          if (soldOut && note.isNotEmpty) ...[
            SizedBox(width: widget.r.dp(8)),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: dullStyle,
            ),
          ],
        ],
      ),
    );
  }
}

TextStyle _style({
  required String family,
  required double size,
  required String variation,
  required Color color,
}) {
  return AppDropThemeData.textStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: _weight(variation),
    color: color,
  );
}

FontWeight _weight(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'bold':
      return FontWeight.w700;
    case 'semi_bold':
    case 'semibold':
      return FontWeight.w600;
    case 'regular':
      return FontWeight.w400;
    default:
      return FontWeight.w400;
  }
}
