import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

import '../src/widget_node.dart';
import '../theme/appdrop_theme_config.dart';
import '../theme/appdrop_theme_scope.dart';
import 'media_block_padding.dart';

/// Legacy default — used when [AppDropThemeScope] is unavailable.
const List<BoxShadow> kAppDropComponentShadows = [
  BoxShadow(
    color: Color(0x24000000),
    blurRadius: 6,
    offset: Offset(0, 2),
    spreadRadius: 0,
  ),
];

/// Block/card elevation from theme `app_styling.shadow_color` + `shadow_visible`.
List<BoxShadow> appDropBlockShadows(AppStylingConfig styling) {
  if (!styling.shadowVisible) return const [];
  return [
    BoxShadow(
      color: styling.shadowColor.withValues(alpha: 0.22),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
}

/// Renderer-level elevation (slightly larger blur).
List<BoxShadow> appDropRendererBlockShadows(AppStylingConfig styling) {
  if (!styling.shadowVisible) return const [];
  return [
    BoxShadow(
      color: styling.shadowColor.withValues(alpha: 0.22),
      blurRadius: 8,
      offset: const Offset(0, 3),
      spreadRadius: 0,
    ),
  ];
}

List<BoxShadow> appDropBlockShadowsOf(BuildContext context) {
  final styling = AppDropThemeScope.maybeOf(context)?.appStyling;
  if (styling == null) return kAppDropComponentShadows;
  return appDropBlockShadows(styling);
}

List<BoxShadow> appDropRendererBlockShadowsOf(BuildContext context) {
  final styling = AppDropThemeScope.maybeOf(context)?.appStyling;
  if (styling == null) {
    return const [
      BoxShadow(
        color: Color(0x24000000),
        blurRadius: 8,
        offset: Offset(0, 3),
        spreadRadius: 0,
      ),
    ];
  }
  return appDropRendererBlockShadows(styling);
}

/// Image / video blocks: vertical padding controls bottom shadow; horizontal
/// padding controls left/right shadow — each axis is independent.
List<BoxShadow> appDropMediaBlockShadowsOf(
  BuildContext context,
  WidgetNode node,
) {
  final styling = AppDropThemeScope.maybeOf(context)?.appStyling;
  if (styling != null && !styling.shadowVisible) return const [];

  final color = styling?.shadowColor.withValues(alpha: 0.22) ??
      const Color(0x24000000);
  const blur = 6.0;

  final shadows = <BoxShadow>[];

  if (mediaBlockVerticalPaddingEnabled(node)) {
    shadows.add(
      BoxShadow(
        color: color,
        blurRadius: blur,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    );
  }

  if (mediaBlockHorizontalPaddingEnabled(node)) {
    shadows.add(
      BoxShadow(
        color: color,
        blurRadius: blur,
        offset: const Offset(-2, 0),
        spreadRadius: 0,
      ),
    );
    shadows.add(
      BoxShadow(
        color: color,
        blurRadius: blur,
        offset: const Offset(2, 0),
        spreadRadius: 0,
      ),
    );
  }

  if (shadows.isNotEmpty) return shadows;

  if (styling == null &&
      mediaBlockHorizontalPaddingEnabled(node) &&
      mediaBlockVerticalPaddingEnabled(node)) {
    return kAppDropComponentShadows;
  }

  return const [];
}

/// Cart line cards — light elevation so they sit cleanly on cream backgrounds.
const List<BoxShadow> kAppDropCartItemShadows = [
  BoxShadow(
    color: Color(0x14000000),
    blurRadius: 12,
    spreadRadius: 0,
    offset: Offset(0, 3),
  ),
];
