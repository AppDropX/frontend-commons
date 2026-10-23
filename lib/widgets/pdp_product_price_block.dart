import 'package:flutter/material.dart';

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
  final rangeOn = node.b('price_range');
  final rawProduct = scope?.product ?? product;
  final sellingEnds = _variantEnds(rawProduct, retail: false);
  final retailEnds = _variantEnds(rawProduct, retail: true);
  final variantChosen = scope?.hasSelection ?? false;
  final sellingSpread = rangeOn && !variantChosen && (sellingEnds?.hasSpread ?? false);
  final retailSpread = rangeOn && !variantChosen && (retailEnds?.hasSpread ?? false);
  if (!sellingSpread && !retailSpread && selling <= 0 && (sellingEnds == null || sellingEnds.low <= 0)) {
    return const SizedBox.shrink();
  }

  final style = node.s('price_style', def: 'current_compare_discount').toLowerCase();
  final align = _alignFromIndex(node.i('alignment_index', def: 0));
  final priceColor =
      parseHexColor(node.s('price_color', def: '#111827')) ?? Colors.black87;
  final retailColor =
      parseHexColor(node.s('retail_color', def: '#757575')) ??
      const Color(0xFF757575);
  final badgeBg = parseHexColor(
        node.s('discount_badge_bg_color', def: '#F3F4F6'),
      ) ??
      const Color(0xFFF3F4F6);

  final priceCfg = ProductPriceDisplayConfig.fromContext(context);
  final prefix = priceCfg.prefix;
  final secondaryFirst =
      node.s('price_order', def: 'primary_first') == 'secondary_first';
  final fontFamily =
      AppDropThemeScope.maybeOf(context)?.appStyling.fontFamily ?? 'Poppins';
  final sellingSize = node.d('price_size', def: 16).clamp(12, 24).toDouble();
  final retailSize = node.d('retail_size', def: 13).clamp(12, 24).toDouble();
  final primaryStyle = AppDropThemeData.textStyle(
    fontFamily: fontFamily,
    fontSize: env.r.sp(sellingSize, min: 12, max: 24),
    fontWeight: _priceWeight(node.s('font_variation', def: 'bold')),
    color: priceColor,
  );
  final compareStyle = AppDropThemeData.textStyle(
    fontFamily: fontFamily,
    fontSize: env.r.sp(retailSize, min: 12, max: 24),
    fontWeight: _priceWeight(
      node.s('retail_font_variation', def: 'regular'),
      fallback: FontWeight.w400,
    ),
    color: retailColor,
  ).copyWith(
    decoration: TextDecoration.lineThrough,
    decorationColor: retailColor,
  );

  final pieces = <Widget>[];
  final stackRanges = sellingSpread || retailSpread;
  if (stackRanges) {
    final sellingPiece = sellingEnds == null || sellingEnds.high <= 0
        ? null
        : Text(
            _rangeLabel(sellingEnds, prefix, priceCfg.priceSuffix),
            style: primaryStyle,
          );
    final retailPiece = retailEnds == null || retailEnds.high <= 0
        ? null
        : Text(
            _rangeLabel(retailEnds, prefix, priceCfg.priceSuffix),
            style: compareStyle,
          );
    final first = secondaryFirst ? (retailPiece ?? sellingPiece) : sellingPiece;
    final second = secondaryFirst
        ? (retailPiece == null ? null : sellingPiece)
        : retailPiece;
    if (first != null) pieces.add(first);
    if (second != null) pieces.add(second);
  } else {
    final shownSelling =
        !variantChosen && rangeOn && sellingEnds != null ? sellingEnds.low : selling;
    final shownRetail =
        !variantChosen && rangeOn && retailEnds != null ? retailEnds.low : retail;
    if (shownSelling <= 0) return const SizedBox.shrink();
    final shownCompare = shownRetail > shownSelling &&
        shownRetail > 0 &&
        (variantChosen && rangeOn ||
            style == 'current_compare' ||
            style == 'current_compare_discount');
    final shownDiscount = _discount(
      shownSelling,
      shownRetail,
      fallback: _toInt(product['discountPercent']),
    );
    final shownBadge = shownCompare &&
        style == 'current_compare_discount' &&
        shownDiscount > 0;
    final current = Text(
      formatProductMoney(shownSelling, prefix, suffix: priceCfg.priceSuffix),
      style: primaryStyle,
    );
    final compare = shownCompare
        ? Text(
            formatProductMoney(shownRetail, prefix, suffix: priceCfg.priceSuffix),
            style: compareStyle,
          )
        : null;
    final first = secondaryFirst ? (compare ?? current) : current;
    final second = secondaryFirst ? (compare == null ? null : current) : compare;
    pieces.add(first);
    if (second != null) pieces.add(second);
    if (shownBadge) {
      pieces.add(
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
            'Save $shownDiscount%',
            style: TextStyle(
              fontSize: env.r.sp(11, min: 10, max: 14),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }
  }

  if (stackRanges) {
    return Column(
      crossAxisAlignment: _cross(align),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < pieces.length; i++) ...[
          if (i > 0) SizedBox(height: env.r.dp(4)),
          pieces[i],
        ],
      ],
    );
  }

  return Row(
    mainAxisAlignment: _main(align),
    children: [
      for (var i = 0; i < pieces.length; i++) ...[
        if (i > 0) SizedBox(width: env.r.dp(8)),
        pieces[i],
      ],
    ],
  );
}

FontWeight _priceWeight(
  String raw, {
  FontWeight fallback = FontWeight.w700,
}) {
  switch (raw.trim().toLowerCase()) {
    case 'regular':
      return FontWeight.w400;
    case 'semi_bold':
    case 'semibold':
      return FontWeight.w600;
    case 'bold':
      return FontWeight.w700;
    default:
      return fallback;
  }
}

/// Lowest - highest on one line. A single price stays as one amount.
String _rangeLabel(_PriceEnds ends, String prefix, String suffix) {
  final low = formatProductMoney(ends.low, prefix, suffix: suffix);
  if (!ends.hasSpread) return low;
  return '$low - ${formatProductMoney(ends.high, prefix, suffix: suffix)}';
}

class _PriceEnds {
  const _PriceEnds(this.low, this.high);

  final double low;
  final double high;

  bool get hasSpread => (high - low).abs() > 0.009;
}

/// Lowest and highest variant price. Retail uses only an explicit compare price.
_PriceEnds? _variantEnds(Map<String, dynamic> product, {required bool retail}) {
  final prices = <double>[];
  for (final variant in rawProductVariantMaps(product)) {
    final value = retail ? _explicitRetail(variant) : _explicitSelling(variant);
    if (value != null && value > 0) prices.add(value);
  }
  if (prices.isEmpty) return null;
  prices.sort();
  return _PriceEnds(prices.first, prices.last);
}

double? _explicitSelling(Map<String, dynamic> variant) {
  return optionalApiPrice(variant['sellingPrice']) ??
      optionalApiPrice(variant['selling_price']) ??
      optionalApiPrice(variant['price']);
}

double? _explicitRetail(Map<String, dynamic> variant) {
  return optionalApiPrice(variant['retailPrice']) ??
      optionalApiPrice(variant['retail_price']) ??
      optionalApiPrice(variant['compareAtPrice']) ??
      optionalApiPrice(variant['compare_at_price']) ??
      optionalApiPrice(variant['mrp']);
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

CrossAxisAlignment _cross(TextAlign a) => a == TextAlign.center
    ? CrossAxisAlignment.center
    : a == TextAlign.right
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

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
