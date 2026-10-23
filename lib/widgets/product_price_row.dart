import 'package:flutter/material.dart';

import '../src/responsive.dart';
import '../theme/appdrop_theme_data.dart';
import '../theme/appdrop_theme_scope.dart';
import '../utils/color.dart';
import '../utils/product_block_theme_helpers.dart';

/// Visibility + typography for product prices, resolved from [product_block] theme
/// settings (same keys as [buildProductBlock]).
@immutable
class ProductPriceDisplayConfig {
  const ProductPriceDisplayConfig({
    required this.showSelling,
    required this.showRetail,
    required this.showStrike,
    required this.showDiscount,
    required this.priceColor,
    required this.discountColor,
    required this.strikeColor,
    required this.priceFontWeight,
    required this.sellingFontSize,
    required this.retailFontSize,
    required this.discountFontSize,
    this.retailBeforeSelling = false,
    this.showVariantPriceRange = true,
    this.priceSuffix = 'default',
    this.fontFamily = 'Poppins',
    this.prefix = '₹',
    this.layout = ProductPriceRowLayout.row,
    this.sellingRetailGap = 8,
    this.discountGap = 5,
  });

  factory ProductPriceDisplayConfig.fromProductBlock(
    Map<String, dynamic> productBlock, {
    String fontFamily = 'Poppins',
    R? r,
  }) {
    bool b(String k, bool def) {
      final v = productBlock[k];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return def;
    }

    String s(String k, String def) => (productBlock[k] ?? def).toString();
    String ext(String k, String def) => productBlockSetting(productBlock, k, def);

    final priceFont = s('price_font', 'Regular').toLowerCase();
    final priceSize = ext('price_size', 'Medium');
    final discountSize = s('discount_size', 'Small').toLowerCase();
    final priceColor =
        parseHexColor(s('price_color', '#000000')) ?? Colors.black;
    final discountColor =
        parseHexColor(s('discount_color', '#FF0000')) ?? Colors.red;
    final strikeColor =
        parseHexColor(ext('strike_price_color', '#757575')) ??
            const Color(0xFF757575);

    return ProductPriceDisplayConfig(
      showSelling: b('show_selling_price', true),
      showRetail: b('show_retail_price', true),
      showStrike: b('show_strike_through', true),
      showDiscount: b('show_discount', true),
      priceColor: priceColor,
      discountColor: discountColor,
      strikeColor: strikeColor,
      priceFontWeight: productPriceFontWeight(priceFont),
      sellingFontSize: productSellingFontSize(priceSize, r),
      retailFontSize: productRetailFontSize(priceSize, r),
      discountFontSize: productDiscountFontSize(discountSize, r),
      retailBeforeSelling:
          productBlockSetting(productBlock, 'price_order', 'selling_first')
              .toLowerCase()
              .contains('retail'),
      showVariantPriceRange: productBlockSettingBool(
        productBlock,
        'show_variant_price_range',
        true,
      ),
      priceSuffix: productBlockSetting(productBlock, 'price_suffix', 'default'),
      fontFamily: fontFamily,
      prefix: productPricePrefix(ext('price_currency', 'symbol')),
      layout: productPriceLayout(ext('price_layout', 'row')),
      sellingRetailGap: r?.dp(8) ?? 8,
      discountGap: r?.dp(5) ?? 5,
    );
  }

  factory ProductPriceDisplayConfig.fromContext(
    BuildContext context, {
    R? r,
  }) {
    final cfg = AppDropThemeScope.maybeOf(context);
    return ProductPriceDisplayConfig.fromProductBlock(
      cfg?.productBlock ?? const {},
      fontFamily: cfg?.appStyling.fontFamily ?? 'Poppins',
      r: r,
    );
  }

  final bool showSelling;
  final bool showRetail;
  final bool showStrike;
  final bool showDiscount;
  final Color priceColor;
  final Color discountColor;
  final Color strikeColor;
  final FontWeight priceFontWeight;
  final double sellingFontSize;
  final double retailFontSize;
  final double discountFontSize;
  final bool retailBeforeSelling;
  final bool showVariantPriceRange;
  final String priceSuffix;
  final String fontFamily;
  final String prefix;
  final ProductPriceRowLayout layout;
  final double sellingRetailGap;
  final double discountGap;
}

String productPricePrefix(String raw) {
  final v = raw.trim().toLowerCase().replaceAll('.', '').replaceAll(' ', '');
  if (v == 'rs' || v == 'inr' || v == 'text') return 'Rs.\u2009';
  return '₹';
}

/// Currency prefix from a theme `product_block` map, including `config`.
String productPricePrefixFromBlock(Map<String, dynamic>? productBlock) {
  if (productBlock == null || productBlock.isEmpty) return '₹';
  return productPricePrefix(
    productBlockSetting(productBlock, 'price_currency', 'symbol'),
  );
}

/// Decimal suffix from a theme `product_block` map, including `config`.
String productPriceSuffixFromBlock(Map<String, dynamic>? productBlock) {
  if (productBlock == null || productBlock.isEmpty) return 'default';
  return productBlockSetting(productBlock, 'price_suffix', 'default');
}

String formatProductAmount(double value, String suffix) {
  final v = suffix.trim().toLowerCase().replaceAll('.', '');
  if (v == '000' || v == '3') return value.toStringAsFixed(3);
  if (v == '00' || v == '2') return value.toStringAsFixed(2);
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String formatProductMoney(
  double value,
  String prefix, {
  String suffix = 'default',
}) {
  return '$prefix${formatProductAmount(value, suffix)}';
}

ProductPriceRowLayout productPriceLayout(String raw) {
  final v = raw.trim().toLowerCase();
  if (v == 'column' || v == 'vertical' || v == 'stack') {
    return ProductPriceRowLayout.column;
  }
  if (v == 'wrap') return ProductPriceRowLayout.wrap;
  return ProductPriceRowLayout.row;
}

double productSellingFontSize(String size, R? r) {
  final normalized = size.trim().toLowerCase();
  if (r != null) {
    if (normalized == 'large') return r.sp(18, min: 16, max: 22);
    if (normalized == 'small') return r.sp(12, min: 11, max: 14);
    return r.sp(14, min: 12, max: 18);
  }
  if (normalized == 'large') return 18;
  if (normalized == 'small') return 12;
  return 14;
}

double productRetailFontSize(String size, R? r) {
  final normalized = size.trim().toLowerCase();
  if (r != null) {
    if (normalized == 'large') return r.sp(14, min: 12, max: 16);
    if (normalized == 'small') return r.sp(10, min: 9, max: 12);
    return r.sp(12, min: 10, max: 16);
  }
  if (normalized == 'large') return 14;
  if (normalized == 'small') return 10;
  return 12;
}

FontWeight productPriceFontWeight(String raw) {
  final normalized =
      raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  switch (normalized) {
    case 'bold':
      return FontWeight.w700;
    case 'semibold':
      return FontWeight.w600;
    case 'regular':
    default:
      return FontWeight.w400;
  }
}

double productDiscountFontSize(String size, R? r) {
  final normalized = size.trim().toLowerCase();
  if (r != null) {
    if (normalized == 'large') return r.sp(14, min: 12, max: 16);
    if (normalized == 'medium') return r.sp(12, min: 10, max: 14);
    return r.sp(10, min: 9, max: 12);
  }
  if (normalized == 'large') return 14;
  if (normalized == 'medium') return 12;
  return 10;
}

/// Selling, retail, and discount row — mirrors [buildProductBlock] price rules.
class ProductPriceRow extends StatelessWidget {
  const ProductPriceRow({
    super.key,
    required this.sellingPrice,
    required this.retailPrice,
    required this.discountPercent,
    this.config,
    this.align = TextAlign.start,
    this.layout,
    this.sellingFontSize,
    this.retailFontSize,
  });

  final double sellingPrice;
  final double retailPrice;
  final int discountPercent;
  final ProductPriceDisplayConfig? config;
  final TextAlign align;
  final ProductPriceRowLayout? layout;
  final double? sellingFontSize;
  final double? retailFontSize;

  @override
  Widget build(BuildContext context) {
    final cfg = config ?? ProductPriceDisplayConfig.fromContext(context);
    final resolvedLayout = layout ?? cfg.layout;
    final children = _priceChildren(
      cfg,
      inlineGaps: resolvedLayout == ProductPriceRowLayout.row,
      sellingFontSize: sellingFontSize,
      retailFontSize: retailFontSize,
    );
    if (children.isEmpty) return const SizedBox.shrink();

    switch (resolvedLayout) {
      case ProductPriceRowLayout.row:
        return Row(
          mainAxisAlignment: _mainAxis(align),
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      case ProductPriceRowLayout.wrap:
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: cfg.sellingRetailGap,
          runSpacing: 2,
          children: children,
        );
      case ProductPriceRowLayout.column:
        return Column(
          crossAxisAlignment: _crossAxis(align),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 2),
              children[i],
            ],
          ],
        );
    }
  }

  List<Widget> _priceChildren(
    ProductPriceDisplayConfig cfg, {
    required bool inlineGaps,
    double? sellingFontSize,
    double? retailFontSize,
  }) {
    final sellingStyle = AppDropThemeData.textStyle(
      fontFamily: cfg.fontFamily,
      fontSize: sellingFontSize ?? cfg.sellingFontSize,
      fontWeight: cfg.priceFontWeight,
      color: cfg.priceColor,
    );

    final children = <Widget>[];

    void addPiece(Widget piece, double gap) {
      if (inlineGaps && children.isNotEmpty) {
        children.add(SizedBox(width: gap));
      }
      children.add(piece);
    }

    final sellingPiece = cfg.showSelling && sellingPrice > 0
        ? Text(
            formatProductMoney(
              sellingPrice,
              cfg.prefix,
              suffix: cfg.priceSuffix,
            ),
            softWrap: false,
            style: sellingStyle,
          )
        : null;

    final retailPiece = cfg.showRetail && retailPrice > sellingPrice
        ? Text(
            formatProductMoney(
              retailPrice,
              cfg.prefix,
              suffix: cfg.priceSuffix,
            ),
            softWrap: false,
            style: TextStyle(
              fontFamily: cfg.fontFamily,
              fontSize: retailFontSize ?? cfg.retailFontSize,
              color: cfg.strikeColor,
              decoration: cfg.showStrike
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: cfg.strikeColor,
            ),
          )
        : null;

    final first = cfg.retailBeforeSelling ? retailPiece : sellingPiece;
    final second = cfg.retailBeforeSelling ? sellingPiece : retailPiece;
    if (first != null) addPiece(first, cfg.sellingRetailGap);
    if (second != null) addPiece(second, cfg.sellingRetailGap);

    if (cfg.showDiscount && discountPercent > 0) {
      addPiece(
        Text(
          '$discountPercent% OFF',
          softWrap: false,
          style: TextStyle(
            fontSize: cfg.discountFontSize,
            fontWeight: FontWeight.w700,
            color: cfg.discountColor,
          ),
        ),
        cfg.discountGap,
      );
    }

    return children;
  }

  MainAxisAlignment _mainAxis(TextAlign align) {
    if (align == TextAlign.center) return MainAxisAlignment.center;
    if (align == TextAlign.right) return MainAxisAlignment.end;
    return MainAxisAlignment.start;
  }

  CrossAxisAlignment _crossAxis(TextAlign align) {
    if (align == TextAlign.center) return CrossAxisAlignment.center;
    if (align == TextAlign.right) return CrossAxisAlignment.end;
    return CrossAxisAlignment.start;
  }
}

enum ProductPriceRowLayout { row, wrap, column }
