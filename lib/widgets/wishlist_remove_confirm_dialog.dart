import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../theme/appdrop_theme_scope.dart';
import 'variant_choice_chips.dart';

/// Asks before removing a product from the wishlist.
Future<bool> showWishlistRemoveConfirmDialog(BuildContext context) async {
  final themeConfig = AppDropThemeScope.maybeOf(context);

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      Widget dialog = const _WishlistRemoveConfirmDialog();
      if (themeConfig != null) {
        dialog = AppDropThemeScope(config: themeConfig, child: dialog);
      }
      return dialog;
    },
  );
  return result == true;
}

class _WishlistRemoveConfirmDialog extends StatelessWidget {
  const _WishlistRemoveConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final cfg = AppDropThemeScope.maybeOf(context);
    final themeColor = cfg?.appStyling.defaultColor ?? const Color(0xFF54A685);
    final onTheme = resolveAppDropOnPrimaryColor(themeColor);
    final bodyText = cfg?.appStyling.fontIconColor ?? const Color(0xFF374151);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      shadowColor: themeColor.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentIcons.heart_off_24_regular,
                size: 24,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Remove from wishlist?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: bodyText,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remove this item from your wishlist?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: bodyText.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: bodyText,
                      side: BorderSide(
                        color: themeColor.withValues(alpha: 0.28),
                      ),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: onTheme,
                      minimumSize: const Size(0, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
