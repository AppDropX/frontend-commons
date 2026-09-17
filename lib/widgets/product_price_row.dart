import 'package:flutter/material.dart';

import '../src/responsive.dart';
import '../theme/appdrop_theme_data.dart';
import '../theme/appdrop_theme_scope.dart';
import '../utils/color.dart';

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
    required this.priceFontWeight,
    required this.sellingFontSize,
    required this.retailFontSize,
    required this.discountFontSize,
    this.fontFamily = 'Poppins',
    this.prefix = '₹',
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

    final priceFont = s('price_font', 'Regular').toLowerCase();
    final discountSize = s('discount_size', 'Small').toLowerCase();
    final priceColor =
        parseHexColor(s('price_color', '#000000')) ?? Colors.black;
    final discountColor =
        parseHexColor(s('discount_color', '#FF0000')) ?? Colors.red;

    return ProductPriceDisplayConfig(
      showSelling: b('show_selling_price', true),
      showRetail: b('show_retail_price', true),
      showStrike: b('show_strike_through', true),
      showDiscount: b('show_discount', true),
      priceColor: priceColor,
      discountColor: discountColor,
      priceFontWeight: productPriceFontWeight(priceFont),
      sellingFontSize: r?.sp(14, min: 12, max: 18) ?? 14,
      retailFontSize: r?.sp(12, min: 10, max: 16) ?? 12,
      discountFontSize: productDiscountFontSize(discountSize, r),
      fontFamily: fontFamily,
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
  final FontWeight priceFontWeight;
  final double sellingFontSize;
  final double retailFontSize;
  final double discountFontSize;
  final String fontFamily;
  final String prefix;
  final double sellingRetailGap;
  final double discountGap;
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
    this.layout = ProductPriceRowLayout.row,
  });

  final double sellingPrice;
  final double retailPrice;
  final int discountPercent;
  final ProductPriceDisplayConfig? config;
  final TextAlign align;
  final ProductPriceRowLayout layout;

  @override
  Widget build(BuildContext context) {
    final cfg = config ?? ProductPriceDisplayConfig.fromContext(context);
    final children = _priceChildren(cfg);
    if (children.isEmpty) return const SizedBox.shrink();

    switch (layout) {
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
    }
  }

  List<Widget> _priceChildren(ProductPriceDisplayConfig cfg) {
    final sellingStyle = AppDropThemeData.textStyle(
      fontFamily: cfg.fontFamily,
      fontSize: cfg.sellingFontSize,
      fontWeight: cfg.priceFontWeight,
      color: cfg.priceColor,
    );

    final children = <Widget>[];

    if (cfg.showSelling && sellingPrice > 0) {
      children.add(
        Text(
          '${cfg.prefix}${sellingPrice.toStringAsFixed(0)}',
          style: sellingStyle,
        ),
      );
    }

    if (cfg.showRetail && retailPrice > sellingPrice) {
      if (layout == ProductPriceRowLayout.row && children.isNotEmpty) {
        children.add(SizedBox(width: cfg.sellingRetailGap));
      }
      children.add(
        Text(
          '${cfg.prefix}${retailPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: cfg.retailFontSize,
            color: Colors.black54,
            decoration: cfg.showStrike
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
      );
    }

    if (cfg.showDiscount && discountPercent > 0) {
      if (layout == ProductPriceRowLayout.row && children.isNotEmpty) {
        children.add(SizedBox(width: cfg.discountGap));
      }
      children.add(
        Text(
          '$discountPercent% OFF',
          style: TextStyle(
            fontSize: cfg.discountFontSize,
            fontWeight: FontWeight.w700,
            color: cfg.discountColor,
          ),
        ),
      );
    }

    return children;
  }

  MainAxisAlignment _mainAxis(TextAlign align) {
    if (align == TextAlign.center) return MainAxisAlignment.center;
    if (align == TextAlign.right) return MainAxisAlignment.end;
    return MainAxisAlignment.start;
  }
}

enum ProductPriceRowLayout { row, wrap }
