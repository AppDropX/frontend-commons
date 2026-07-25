import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

/// Placeholder shown when a product has no image URL or the network load fails.
class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({
    super.key,
    required this.backgroundColor,
    this.iconColor,
    this.label = 'No Image',
  });

  final Color backgroundColor;
  final Color? iconColor;
  final String label;

  Color get _mutedIconColor {
    if (iconColor != null) return iconColor!;
    return backgroundColor.computeLuminance() > 0.55
        ? const Color(0xFF9CA3AF)
        : const Color(0xFFD1D5DB);
  }

  Color get _mutedTextColor => _mutedIconColor.withValues(alpha: 0.92);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortest = constraints.biggest.shortestSide;
          final boundedShortest =
              shortest.isFinite && shortest > 0 ? shortest : 120.0;
          final showLabel = boundedShortest >= 72 && label.isNotEmpty;
          final iconSize = (boundedShortest * 0.28).clamp(24.0, 48.0);
          final fontSize = (boundedShortest * 0.11).clamp(10.0, 13.0);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(iconSize * 0.28),
                  decoration: BoxDecoration(
                    color: _mutedIconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FluentIcons.image_20_regular,
                    size: iconSize,
                    color: _mutedIconColor,
                  ),
                ),
                if (showLabel) ...[
                  SizedBox(height: iconSize * 0.2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: _mutedTextColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
