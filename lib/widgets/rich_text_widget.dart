import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';

Widget buildRichTextWidget(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final spans = node.l('spans') ?? const [];
  final baseSize = node.d('baseSizeSp', def: 14);
  final baseColor = parseHexColor(node.s('baseColor', def: '')) ?? const Color(0xFF374151);

  final alignStr = node.s('align', def: 'left').toLowerCase();
  final align = alignStr == 'center'
      ? TextAlign.center
      : alignStr == 'right'
      ? TextAlign.right
      : TextAlign.left;

  final maxLines = node.i('maxLines', def: 0);
  final overflow = node.s('overflow', def: 'ellipsis').toLowerCase();

  final children = <TextSpan>[];
  for (final s in spans) {
    final m = Map<String, dynamic>.from(s as Map);
    final txt = (m['text'] ?? '').toString();
    final w = (m['weight'] ?? 'regular').toString().toLowerCase();
    final c = parseHexColor(m['color']?.toString()) ?? baseColor;

    children.add(TextSpan(
      text: txt,
      style: TextStyle(
        fontSize: env.r.sp(baseSize, min: 10, max: 28),
        fontWeight: w == 'bold'
            ? FontWeight.w700
            : w == 'semibold'
            ? FontWeight.w600
            : FontWeight.w400,
        color: c,
      ),
    ));
  }

  return RichText(
    textAlign: align,
    maxLines: maxLines <= 0 ? null : maxLines,
    overflow: overflow == 'clip' ? TextOverflow.clip : TextOverflow.ellipsis,
    text: TextSpan(children: children),
  );
}
