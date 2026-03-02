import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';

/// CTA Button block. Props: enabled, buttonStyle (filled|outlined), buttonTitle,
/// titleSize, ctaColor, ctaFontColor, style (sharp|rounded|pill), scrollStyle (inline|fixed_at_bottom), action.
Widget buildCtaButton(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final buttonStyle = node.s('buttonStyle', def: 'filled').toLowerCase();
  final isOutlined = buttonStyle == 'outlined';
  final title = node.s('buttonTitle', def: 'Button');
  final titleSize = node.d('titleSize', def: 16);
  final ctaColor = parseHexColor(node.s('ctaColor', def: '#FF6A00')) ?? const Color(0xFFFF6A00);
  final ctaFontColor = parseHexColor(node.s('ctaFontColor', def: '#FFFFFF')) ?? const Color(0xFFFFFFFF);
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
