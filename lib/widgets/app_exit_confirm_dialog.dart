import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../theme/appdrop_theme_config.dart';
import '../theme/appdrop_theme_data.dart';
import '../theme/appdrop_theme_scope.dart';
import 'variant_choice_chips.dart';

/// Confirms before leaving the storefront on the last system-back.
///
/// Pass [themeConfig] when the caller sits above [AppDropThemeScope]
/// (e.g. the storefront shell). Falls back to the nearest scope otherwise.
Future<bool> showAppExitConfirmDialog(
  BuildContext context, {
  AppDropThemeConfig? themeConfig,
}) async {
  final config = themeConfig ?? AppDropThemeScope.maybeOf(context);

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0x99000000),
    builder: (dialogContext) {
      Widget dialog = _AppExitConfirmDialog(config: config);
      if (config != null) {
        dialog = AppDropThemeScope(config: config, child: dialog);
      }
      return dialog;
    },
  );
  return result == true;
}

class _AppExitConfirmDialog extends StatelessWidget {
  const _AppExitConfirmDialog({this.config});

  final AppDropThemeConfig? config;

  @override
  Widget build(BuildContext context) {
    final styling = config?.appStyling;
    final themeColor =
        styling?.defaultColor ?? const Color(0xFF54A685);
    final onTheme = resolveAppDropOnPrimaryColor(themeColor);
    final bodyText = styling?.fontIconColor ?? const Color(0xFF374151);
    final surface = styling?.bgColor ?? Colors.white;
    final fontFamily = styling?.fontFamily ?? 'Poppins';
    final shadowColor = styling?.shadowColor ?? themeColor;

    TextStyle type({
      required double size,
      required FontWeight weight,
      required Color color,
    }) => AppDropThemeData.textStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

    return Dialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: shadowColor.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentIcons.door_arrow_right_20_regular,
                size: 26,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to exit the app?',
              textAlign: TextAlign.center,
              style: type(
                size: 16,
                weight: FontWeight.w700,
                color: bodyText,
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
                      backgroundColor: surface,
                      side: BorderSide(
                        color: bodyText.withValues(alpha: 0.18),
                      ),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: type(
                        size: 15,
                        weight: FontWeight.w600,
                        color: bodyText,
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
                    child: Text(
                      'Sure',
                      style: type(
                        size: 15,
                        weight: FontWeight.w600,
                        color: onTheme,
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
