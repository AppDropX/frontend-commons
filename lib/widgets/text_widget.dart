import 'package:flutter/widgets.dart';
import '../pdp/pdp_product_scope.dart';
import '../theme_library.dart';
import '../transitions/pdp_enter_animation.dart';
import '../utils/color.dart';

Widget buildTextWidget(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final slot = pdpStaggerSlotFromString(node.s('pdpStaggerSlot', def: ''));
  final pdpScope = slot == PdpStaggerSlot.price
      ? PdpProductScope.maybeOf(context)
      : null;
  final text = pdpScope != null && pdpScope.formattedPriceLine.isNotEmpty
      ? pdpScope.formattedPriceLine
      : node.s('text', def: '');
  final size = node.d('sizeSp', def: 14);
  final weight = node.s('weight', def: 'regular').toLowerCase();
  final scope = AppDropThemeScope.maybeOf(context);
  final fallback = scope?.appStyling.fontIconColor ?? const Color(0xFF111827);
  final color = parseHexColor(node.s('color', def: '')) ?? fallback;

  final alignStr = node.s('align', def: 'left').toLowerCase();
  final align = alignStr == 'center'
      ? TextAlign.center
      : alignStr == 'right'
      ? TextAlign.right
      : TextAlign.left;

  final maxLines = node.i('maxLines', def: 0);
  final overflow = node.s('overflow', def: 'ellipsis').toLowerCase();

  Widget result = Text(
    text,
    textAlign: align,
    maxLines: maxLines <= 0 ? null : maxLines,
    overflow: overflow == 'clip' ? TextOverflow.clip : TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: env.r.sp(size, min: 10, max: 30),
      fontWeight: weight == 'bold'
          ? FontWeight.w700
          : weight == 'semibold'
          ? FontWeight.w600
          : FontWeight.w400,
      color: color,
    ),
  );

  if (slot != null) {
    result = wrapPdpStagger(context, slot, result);
  }
  return result;
}
