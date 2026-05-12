import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';

/// CTA Button block. Props: enabled, buttonStyle (filled|outlined), buttonTitle,
/// titleSize, ctaColor, ctaFontColor, style (sharp|rounded|pill), scrollStyle (inline|fixed_at_bottom), action.
///
/// Fill / label colors follow [AppDropThemeConfig.productBlock] (same as product card
/// buttons) when present, so App Styling changes apply without editing each CTA block.
/// Per-block [ctaColor] / [ctaFontColor] are used when theme does not define the
/// matching product_block keys.
Widget buildCtaButton(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final buttonStyle = node.s('buttonStyle', def: 'filled').toLowerCase();
  final isOutlined = buttonStyle == 'outlined';
  final title = node.s('buttonTitle', def: 'Button');
  final titleSize = node.d('titleSize', def: 16);

  final cfg = AppDropThemeScope.maybeOf(context);
  final pb = cfg?.productBlock ?? const <String, dynamic>{};
  final themeFillBg = parseHexColor(pb['filled_button_bg']?.toString());
  final themeFillFont = parseHexColor(pb['filled_button_color']?.toString());
  final themeOutlineStroke = parseHexColor(pb['outlined_button_color']?.toString());

  final nodeCtaStr = node.s('ctaColor', def: '').trim();
  final nodeFontStr = node.s('ctaFontColor', def: '').trim();
  final nodeCta = nodeCtaStr.isNotEmpty ? parseHexColor(nodeCtaStr) : null;
  final nodeFont = nodeFontStr.isNotEmpty ? parseHexColor(nodeFontStr) : null;

  late final Color ctaColor;
  late final Color ctaFontColor;
  if (isOutlined) {
    ctaColor = themeOutlineStroke ??
        nodeCta ??
        themeFillBg ??
        const Color(0xFFFF6A00);
    ctaFontColor = nodeFont ?? themeOutlineStroke ?? ctaColor;
  } else {
    ctaColor = themeFillBg ?? nodeCta ?? const Color(0xFFFF6A00);
    ctaFontColor = themeFillFont ?? nodeFont ?? const Color(0xFFFFFFFF);
  }

  final style = node.s('style', def: 'rounded').toLowerCase();
  final action = node.m('action');

  final radius = _radiusFromStyle(style, r);
  // Fixed height so only title text size changes when titleSize changes
  const double fixedButtonHeightDp = 52;

  Widget child = Container(
    width: double.infinity,
    constraints: BoxConstraints(minHeight: r.dp(fixedButtonHeightDp)),
    padding: EdgeInsets.symmetric(horizontal: r.dp(20)),
    decoration: BoxDecoration(
      color: isOutlined ? const Color(0x00000000) : ctaColor,
      borderRadius: BorderRadius.circular(radius),
      border: isOutlined ? Border.all(color: ctaColor, width: 2) : null,
      boxShadow: kAppDropComponentShadows,
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

double _radiusFromStyle(String style, R r) {
  switch (style) {
    case 'sharp':
      return 0;
    case 'pill':
      return r.dp(999);
    case 'rounded':
    default:
      return r.dp(12);
  }
}
