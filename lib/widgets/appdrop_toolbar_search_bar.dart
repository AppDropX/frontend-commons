import 'package:flutter/material.dart';

import '../models/page_toolbar_config.dart';
import '../utils/color.dart';
import 'appdrop_tinted_graphic.dart';

/// Compact search field under the toolbar title row: hint + filled icon button.
class AppDropToolbarSearchBar extends StatelessWidget {
  const AppDropToolbarSearchBar({
    super.key,
    required this.config,
    required this.accentColor,
    this.onTap,
    this.height = 40,
  });

  final ToolbarSearchBarConfig config;
  final Color accentColor;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(config.cornerRadius.clamp(0, 24));
    final background = parseHexColor(config.backgroundColor) ?? Colors.white;
    final borderColor =
        parseHexColor(config.borderColor) ?? const Color(0xFFE5E7EB);
    final hintColor =
        parseHexColor(config.hintColor) ?? const Color(0xFF9CA3AF);
    final buttonColor = parseHexColor(config.iconColor) ?? accentColor;
    final iconOnButton =
        ThemeData.estimateBrightnessForColor(buttonColor) == Brightness.dark
            ? Colors.white
            : const Color(0xFF111827);
    final hint = config.resolvedHint;
    final graphicSize = (height * 0.5).clamp(16.0, 20.0);

    return Semantics(
      button: true,
      label: 'Search, $hint',
      child: Material(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: height,
                  height: height,
                  child: ColoredBox(
                    color: buttonColor,
                    child: Center(
                      child: AppDropTintedGraphic(
                        glyph: config.resolvedIcon,
                        svgUrl: config.resolvedIconUrl,
                        color: iconOnButton,
                        size: graphicSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
