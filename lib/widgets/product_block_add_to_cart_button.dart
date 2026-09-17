import 'package:flutter/material.dart';

import '../src/responsive.dart';
import '../theme/appdrop_theme_scope.dart';
import '../utils/color.dart';

/// Compact Add to Cart button styled like [buildProductBlock] CTAs.
class ProductBlockAddToCartButton extends StatelessWidget {
  const ProductBlockAddToCartButton({
    super.key,
    required this.r,
    required this.onTap,
    this.label = 'Add to Cart',
    this.heightDp = 34,
    this.enabled = true,
    this.isLoading = false,
  });

  final R r;
  final VoidCallback? onTap;
  final String label;
  final double heightDp;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cfg = AppDropThemeScope.maybeOf(context);
    final pb = cfg?.productBlock ?? const <String, dynamic>{};

    String s(String k, String def) => (pb[k] ?? def).toString();
    final buttonStyleRaw = s('button_style', 'sharp_filled').toLowerCase();
    final buttonParts = buttonStyleRaw.split(RegExp(r'[_\-\s]+'));
    final buttonShape =
        buttonParts.isNotEmpty ? buttonParts.first : 'sharp';
    final buttonType =
        buttonParts.length > 1 ? buttonParts[1] : 'filled';
    final isOutlined = buttonType == 'outlined';

    final filledButtonBg = parseHexColor(s('filled_button_bg', '#B63E3E')) ??
        const Color(0xFFB63E3E);
    final filledButtonColor =
        parseHexColor(s('filled_button_color', '#FFFFFF')) ?? Colors.white;
    final outlinedButtonBg =
        parseHexColor(s('outlined_button_bg', '#FFFFFF')) ?? Colors.white;
    final outlinedButtonColor =
        parseHexColor(s('outlined_button_color', '#B63E3E')) ??
            const Color(0xFFB63E3E);

    final bg = isOutlined ? Colors.transparent : filledButtonBg;
    final fg = isOutlined ? outlinedButtonColor : filledButtonColor;
    final borderColor = isOutlined ? outlinedButtonBg : filledButtonBg;
    final radius = _radius(buttonShape, r);
    final active = enabled && !isLoading && onTap != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          height: r.dp(heightDp),
          decoration: BoxDecoration(
            color: active ? bg : bg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: active ? borderColor : borderColor.withValues(alpha: 0.5),
              width: isOutlined ? 1.2 : 1,
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: r.dp(18),
                    height: r.dp(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: r.sp(13, min: 11, max: 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  double _radius(String shape, R r) {
    switch (shape) {
      case 'rounded':
        return r.dp(8);
      case 'blunt':
      case 'pill':
        return r.dp(999);
      case 'corner':
      case 'sharp':
      default:
        return 0;
    }
  }
}
