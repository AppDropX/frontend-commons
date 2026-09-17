import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/appdrop_theme_scope.dart';

/// Shimmer colors derived from the storefront screen background (`bg_color`).
class AppDropShimmerColors {
  const AppDropShimmerColors({
    required this.base,
    required this.highlight,
    required this.fill,
  });

  final Color base;
  final Color highlight;
  final Color fill;

  factory AppDropShimmerColors.of(BuildContext context) {
    final bg = AppDropThemeScope.maybeOf(context)?.appStyling.bgColor ??
        Theme.of(context).scaffoldBackgroundColor;
    final isLight = bg.computeLuminance() > 0.5;
    if (isLight) {
      return AppDropShimmerColors(
        base: Color.lerp(bg, const Color(0xFF000000), 0.07) ?? bg,
        highlight: Color.lerp(bg, const Color(0xFFFFFFFF), 0.55) ?? bg,
        fill: Color.lerp(bg, const Color(0xFF000000), 0.04) ?? bg,
      );
    }
    return AppDropShimmerColors(
      base: Color.lerp(bg, const Color(0xFFFFFFFF), 0.08) ?? bg,
      highlight: Color.lerp(bg, const Color(0xFFFFFFFF), 0.2) ?? bg,
      fill: Color.lerp(bg, const Color(0xFFFFFFFF), 0.05) ?? bg,
    );
  }
}

/// Full-bleed shimmer used while a block's media is loading.
class AppDropMediaShimmer extends StatelessWidget {
  const AppDropMediaShimmer({
    super.key,
    this.borderRadius = 0,
  });

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppDropShimmerColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0;
        final hasHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0;
        return Shimmer.fromColors(
          baseColor: colors.base,
          highlightColor: colors.highlight,
          child: Container(
            width: hasWidth ? constraints.maxWidth : double.infinity,
            height: hasHeight ? constraints.maxHeight : 120,
            decoration: BoxDecoration(
              color: colors.fill,
              borderRadius: borderRadius > 0
                  ? BorderRadius.circular(borderRadius)
                  : BorderRadius.zero,
            ),
          ),
        );
      },
    );
  }
}

/// Wraps [child] in a screen-background shimmer while [enabled] is true.
class AppDropBlockShimmer extends StatelessWidget {
  const AppDropBlockShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final colors = AppDropShimmerColors.of(context);
    return Shimmer.fromColors(
      baseColor: colors.base,
      highlightColor: colors.highlight,
      child: child,
    );
  }
}

class AppDropShimmerBox extends StatelessWidget {
  const AppDropShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppDropShimmerColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Placeholder grid shown while the first PLP page loads.
class AppDropProductGridShimmer extends StatelessWidget {
  const AppDropProductGridShimmer({
    super.key,
    this.columns = 2,
    this.rows = 2,
  });

  final int columns;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return AppDropBlockShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: 10),
                    const Expanded(child: _ProductCardShimmer()),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductCardShimmer extends StatelessWidget {
  const _ProductCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AspectRatio(
          aspectRatio: 0.92,
          child: AppDropShimmerBox(width: double.infinity, borderRadius: 12),
        ),
        SizedBox(height: 8),
        AppDropShimmerBox(width: 72, height: 10, borderRadius: 4),
        SizedBox(height: 6),
        AppDropShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
        SizedBox(height: 6),
        AppDropShimmerBox(width: 88, height: 12, borderRadius: 4),
      ],
    );
  }
}
