import 'package:flutter/material.dart';

import '../pdp/pdp_product_scope.dart';
import '../theme_library.dart';
import '../utils/color.dart';

Widget buildPdpProductPriceBlock(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  if (!node.b('enabled', def: true)) return const SizedBox.shrink();
  final product = _effectiveProduct(context, node);
  final scope = PdpProductScope.maybeOf(context);
  final selling = scope?.sellingPrice ?? _toDouble(product['sellingPrice']);
  final retail = scope?.retailPrice ?? _toDouble(product['retailPrice']);
  if (selling <= 0) return const SizedBox.shrink();

  final style = node.s('price_style', def: 'current_compare_discount').toLowerCase();
  final align = _alignFromIndex(node.i('alignment_index', def: 0));
  final priceColor =
      parseHexColor(node.s('price_color', def: '#111827')) ?? Colors.black87;
  final badgeBg = parseHexColor(
        node.s('discount_badge_bg_color', def: '#F3F4F6'),
      ) ??
      const Color(0xFFF3F4F6);

  final hasCompare = retail > selling && retail > 0;
  final showCompare = hasCompare &&
      (style == 'current_compare' || style == 'current_compare_discount');
  final discount = _discount(selling, retail, fallback: _toInt(product['discountPercent']));
  final showBadge = showCompare && style == 'current_compare_discount' && discount > 0;

  return Row(
    mainAxisAlignment: _main(align),
    children: [
        Text(
          '₹${selling.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: env.r.sp(16, min: 13, max: 20),
            fontWeight: FontWeight.w700,
            color: priceColor,
          ),
        ),
        if (showCompare) ...[
          SizedBox(width: env.r.dp(8)),
          Text(
            '₹${retail.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: env.r.sp(13, min: 11, max: 16),
              color: Colors.black54,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
        if (showBadge) ...[
          SizedBox(width: env.r.dp(8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: env.r.dp(8),
              vertical: env.r.dp(3),
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(env.r.dp(999)),
            ),
            child: Text(
              'Save $discount%',
              style: TextStyle(
                fontSize: env.r.sp(11, min: 10, max: 14),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ],
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

MainAxisAlignment _main(TextAlign a) => a == TextAlign.center
    ? MainAxisAlignment.center
    : a == TextAlign.right
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int _discount(double selling, double retail, {int fallback = 0}) {
  if (retail > selling && retail > 0) {
    return (((retail - selling) / retail) * 100).round();
  }
  return fallback > 0 ? fallback : 0;
}
