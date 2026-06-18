import 'package:flutter/material.dart';

import '../pdp/pdp_product_scope.dart';
import '../theme/appdrop_theme_scope.dart';
import '../theme_library.dart';
import '../utils/color.dart';

Color resolvePdpCtaBackgroundColor(BuildContext context, WidgetNode node) {
  final themeDefault =
      AppDropThemeScope.maybeOf(context)?.appStyling.defaultColor ??
          const Color(0xFFB63E3E);
  if (!node.b('cta_bg_color_custom', def: false)) {
    return themeDefault;
  }
  final raw = node.s('cta_bg_color', def: '').trim();
  return parseHexColor(raw) ?? themeDefault;
}

Widget buildPdpProductCtaBlock(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  if (!node.b('enabled', def: true)) return const SizedBox.shrink();
  final action = node.m('action');
  final buttonType = node.s('button_type', def: 'filled').toLowerCase();
  final isOutlined = buttonType == 'outlined';
  final shape = node.s('button_shape', def: 'corner').toLowerCase();
  final title = node.s('button_title', def: 'Add to Cart').trim();
  final titleSize = node.d('title_size', def: 13).clamp(12, 24).toDouble();
  final bg = resolvePdpCtaBackgroundColor(context, node);
  final fg = parseHexColor(node.s('cta_title_color', def: '#FFFFFF')) ?? Colors.white;
  final radius = _radius(shape, env.r);
  final canTap = env.interactiveFeaturesEnabled && action != null;

  final button = Ink(
    height: env.r.dp(44),
    decoration: BoxDecoration(
      color: isOutlined ? Colors.transparent : bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: bg, width: isOutlined ? 1.2 : 1),
    ),
    child: Center(
      child: Text(
        title.isEmpty ? 'Add to Cart' : title,
        style: TextStyle(
          color: isOutlined ? bg : fg,
          fontWeight: FontWeight.w600,
          fontSize: env.r.sp(titleSize, min: 11, max: 24),
        ),
      ),
    ),
  );

  if (!canTap) return button;

  return Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(radius),
    child: InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: () {
        final scope = PdpProductScope.maybeOf(context);
        final payload = scope == null
            ? action
            : {
                ...action,
                'direct': true,
                'product': scope.effectiveProduct,
              };
        env.dispatchAction(context, payload);
      },
      child: button,
    ),
  );
}

double _radius(String shape, dynamic r) {
  switch (shape) {
    case 'rounded':
      return r.dp(8);
    case 'blunt':
      return r.dp(999);
    case 'corner':
    default:
      return 0;
  }
}
