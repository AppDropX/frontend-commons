import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/color.dart';

/// Empty cart placeholder: large cart icon, message below, vertically centered in the body.
/// Props: message, iconSizeDp, iconColor (hex optional).
Widget buildEmptyCartState(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final r = env.r;
  final message = node.s('message', def: 'Cart is empty');
  final emptyVariant = node.s('emptyStateVariant', def: 'cart').toLowerCase();
  final iconDp = node.d('iconSizeDp', def: 72).clamp(40, 120);
  final iconHex = node.s('iconColor', def: '');
  final iconColor = iconHex.isNotEmpty
      ? (parseHexColor(iconHex) ?? Colors.grey.shade400)
      : Colors.grey.shade400;
  final textHex = node.s('textColor', def: '');
  final scope = AppDropThemeScope.maybeOf(context);
  final fallbackText = scope?.appStyling.fontIconColor ?? const Color(0xFF6B7280);
  final textColor = textHex.isNotEmpty ? (parseHexColor(textHex) ?? fallbackText) : fallbackText;

  return LayoutBuilder(
    builder: (context, constraints) {
      final mq = MediaQuery.of(context);
      final h = mq.size.height;
      final minH = (h - mq.padding.vertical - kToolbarHeight - 100).clamp(240.0, h);
      return SizedBox(
        width: double.infinity,
        height: minH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              emptyVariant == 'wishlist' ? Icons.favorite_border : Icons.shopping_cart_outlined,
              size: r.dp(iconDp),
              color: iconColor,
            ),
            SizedBox(height: r.dp(20)),
            Text(
              message.isEmpty ? 'Cart is empty' : message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.sp(17, min: 14, max: 20),
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    },
  );
}
