import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';

/// CTA Button block. Props: enabled, buttonStyle (filled|outlined), buttonTitle,
/// titleSize, ctaColor, ctaFontColor, ctaColorCustom,
/// buttonShape / style (sharp|rounded|pill),
/// scrollStyle (inline|fixed_at_bottom), action.
///
/// When [ctaColorCustom] is false, fill/outline follow the theme default color
/// (same as PDP Add to Bag). When the merchant picks a color in the builder,
/// [ctaColorCustom] is set and those hexes are used instead.
Widget buildCtaButton(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final buttonStyle = _nodeStr(node, const ['buttonStyle', 'button_style'], 'filled')
      .toLowerCase();
  final isOutlined = buttonStyle == 'outlined';
  final title = _nodeStr(node, const ['buttonTitle', 'button_title'], 'Button');
  final titleSize = node.d('titleSize', def: 16);
  final useCustom = node.b('ctaColorCustom', def: false) ||
      node.b('cta_color_custom', def: false);

  final nodeCta = parseHexColor(
    _nodeStr(node, const ['ctaColor', 'cta_color'], ''),
  );
  final nodeFont = parseHexColor(
    _nodeStr(node, const ['ctaFontColor', 'cta_font_color'], ''),
  );

  final themeAccent = resolveAppDropPrimaryColor(context);
  final cfg = AppDropThemeScope.maybeOf(context);
  final pb = cfg?.productBlock ?? const <String, dynamic>{};
  final themeFillFont = parseHexColor(pb['filled_button_color']?.toString());

  late final Color ctaColor;
  late final Color ctaFontColor;
  if (isOutlined) {
    ctaColor = (useCustom ? nodeCta : null) ?? themeAccent;
    ctaFontColor = (useCustom ? nodeFont : null) ?? ctaColor;
  } else {
    ctaColor = (useCustom ? nodeCta : null) ?? themeAccent;
    ctaFontColor = (useCustom ? nodeFont : null) ??
        themeFillFont ??
        const Color(0xFFFFFFFF);
  }

  final action = node.m('action');
  final radius = _ctaCornerRadius(node, r, pb);
  final isCartCheckout = (action?['type']?.toString() ?? '') == 'checkout_cart';
  final buttonHeightDp = isCartCheckout ? 44.0 : 52.0;

  Widget child = Container(
    width: double.infinity,
    constraints: BoxConstraints(minHeight: r.dp(buttonHeightDp)),
    padding: EdgeInsets.symmetric(horizontal: r.dp(20)),
    decoration: BoxDecoration(
      color: isOutlined ? const Color(0x00000000) : ctaColor,
      borderRadius: BorderRadius.circular(radius),
      border: isOutlined ? Border.all(color: ctaColor, width: 2) : null,
      boxShadow: appDropBlockShadowsOf(context),
    ),
    alignment: Alignment.center,
    child: Text(
      title.isEmpty ? 'Button' : title,
      style: TextStyle(
        color: ctaFontColor,
        fontSize: r.sp(titleSize.clamp(12, 24).toDouble(), min: 12, max: 24),
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  if (action != null) {
    child = GestureDetector(
      onTap: () => env.dispatchAction(context, action),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  return child;
}

String _nodeStr(WidgetNode node, List<String> keys, String def) {
  for (final k in keys) {
    if (!node.props.containsKey(k)) continue;
    final v = node.s(k, def: '').trim();
    if (v.isNotEmpty && v.toLowerCase() != 'null') return v;
  }
  return def;
}

double _ctaCornerRadius(WidgetNode node, R r, Map<String, dynamic> pb) {
  for (final key in const ['cornerRadius', 'borderRadius', 'corner_radius']) {
    if (!node.props.containsKey(key)) continue;
    final v = node.d(key, def: -1);
    if (v >= 0) return r.dp(v);
  }

  final named = _nodeStr(
    node,
    const ['buttonShape', 'button_shape', 'style'],
    '',
  ).toLowerCase();
  if (named.isNotEmpty) return _radiusFromStyle(named, r);

  final themeStyle = (pb['button_style'] ?? '').toString().toLowerCase();
  final themeShape = themeStyle.split(RegExp(r'[_\-\s]+')).where((p) => p.isNotEmpty);
  if (themeShape.isNotEmpty) return _radiusFromStyle(themeShape.first, r);

  final themeRadius = pb['corner_radius'];
  if (themeRadius is num && themeRadius >= 0) return r.dp(themeRadius.toDouble());

  return r.dp(12);
}

double _radiusFromStyle(String style, R r) {
  switch (style) {
    case 'sharp':
    case 'corner':
      return 0;
    case 'pill':
    case 'blunt':
      return r.dp(999);
    case 'rounded':
    default:
      return r.dp(12);
  }
}
