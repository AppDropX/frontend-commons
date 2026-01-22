import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';

Widget buildTextWidget(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final text = node.s('text', def: '');
  final size = node.d('sizeSp', def: 14);
  final weight = node.s('weight', def: 'regular').toLowerCase();
  final color = parseHexColor(node.s('color', def: '')) ?? const Color(0xFF111827);

  final alignStr = node.s('align', def: 'left').toLowerCase();
  final align = alignStr == 'center'
      ? TextAlign.center
      : alignStr == 'right'
      ? TextAlign.right
      : TextAlign.left;

  final maxLines = node.i('maxLines', def: 0);
  final overflow = node.s('overflow', def: 'ellipsis').toLowerCase();

  return Text(
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
}
