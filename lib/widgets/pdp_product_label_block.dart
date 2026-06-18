import 'package:flutter/material.dart';

import '../pdp/pdp_product_scope.dart';
import '../theme_library.dart';
import '../utils/color.dart';

Widget buildPdpProductLabelBlock(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  if (!node.b('enabled', def: true)) return const SizedBox.shrink();
  final product = _effectiveProduct(context, node);
  final labelType = node.s('label_type', def: 'product_name').toLowerCase();
  final text = labelType == 'vendor_name'
      ? (product['vendor'] ?? '').toString()
      : (product['title'] ?? '').toString();
  if (text.trim().isEmpty) return const SizedBox.shrink();

  final align = _alignFromIndex(node.i('alignment_index', def: 0));
  final color = parseHexColor(node.s('label_color', def: '#111827')) ??
      Theme.of(context).textTheme.titleMedium?.color ??
      Colors.black87;
  final size = node.d('label_size', def: 16).clamp(12, 24).toDouble();
  final weight = _weight(node.s('font_weight', def: 'semi_bold'));

  return Text(
      text,
      textAlign: align,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: env.r.sp(size, min: 12, max: 24),
        fontWeight: weight,
      ),
    );
}

Map<String, dynamic> _effectiveProduct(BuildContext context, WidgetNode node) {
  final fromScope = PdpProductScope.maybeOf(context)?.effectiveProduct;
  if (fromScope != null) return Map<String, dynamic>.from(fromScope);
  final fromNode = node.m('product');
  if (fromNode == null) return <String, dynamic>{};
  return Map<String, dynamic>.from(fromNode);
}

TextAlign _alignFromIndex(int idx) {
  switch (idx) {
    case 1:
      return TextAlign.center;
    case 2:
      return TextAlign.right;
    default:
      return TextAlign.left;
  }
}

FontWeight _weight(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'regular':
      return FontWeight.w400;
    case 'bold':
      return FontWeight.w700;
    case 'semi_bold':
    case 'semibold':
    default:
      return FontWeight.w600;
  }
}
