import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../product/product_variant_model.dart';
import '../utils/appdrop_snackbar.dart';
import '../src/responsive.dart';
import '../theme/appdrop_theme_data.dart';
import '../widgets/product_price_row.dart';

/// Horizontal PLP product row: photo on the left, title, prices, rating, and
/// the call-to-action stacked on the right.
class ProductListCard extends StatelessWidget {
  const ProductListCard({
    super.key,
    required this.image,
    required this.title,
    required this.titleColor,
    required this.titleFontWeight,
    required this.titleFontSize,
    required this.titleMaxLines,
    required this.fontFamily,
    required this.sellingPrice,
    required this.retailPrice,
    required this.product,
    required this.priceDisplay,
    required this.showRating,
    required this.rating,
    required this.showRatingCount,
    required this.ratingCount,
    required this.ratingColor,
    required this.ratingFontColor,
    required this.showAddToCart,
    required this.ctaLabel,
    this.ctaFontSize,
    this.ctaFontWeight = FontWeight.w600,
    required this.addToCartBg,
    required this.addToCartFg,
    required this.addToCartRadius,
    required this.isOutlined,
    required this.outlineColor,
    required this.envR,
    required this.onOpen,
    required this.onAddToCart,
    this.soldOut = false,
  });

  final Widget image;
  final String title;
  final Color titleColor;
  final FontWeight titleFontWeight;
  final double titleFontSize;
  final int? titleMaxLines;
  final String fontFamily;
  final double sellingPrice;
  final double retailPrice;
  final Map<String, dynamic> product;
  final ProductPriceDisplayConfig priceDisplay;
  final bool showRating;
  final double rating;
  final bool showRatingCount;
  final int ratingCount;
  final Color ratingColor;
  final Color ratingFontColor;
  final bool showAddToCart;
  final String ctaLabel;
  final double? ctaFontSize;
  final FontWeight ctaFontWeight;
  final Color addToCartBg;
  final Color addToCartFg;
  final double addToCartRadius;
  final bool isOutlined;
  final Color outlineColor;
  final R envR;
  final VoidCallback? onOpen;
  final VoidCallback? onAddToCart;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    final selling = _priceSpan(product, retail: false, fallback: sellingPrice);
    final retail = _priceSpan(product, retail: true, fallback: retailPrice);
    final showStrike = priceDisplay.showRetail &&
        priceDisplay.showStrike &&
        retail.max > selling.max + 0.009;
    final saleColor =
        showStrike ? priceDisplay.discountColor : priceDisplay.priceColor;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
        Text(
          title,
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppDropThemeData.textStyle(
            fontFamily: fontFamily,
            fontSize: titleFontSize,
            fontWeight: titleFontWeight,
            color: titleColor,
          ),
        ),
        _ListPriceBlock(
          priceDisplay: priceDisplay,
          fontFamily: fontFamily,
          sellingLabel: _spanLabel(
            priceDisplay.prefix,
            selling.min,
            selling.max,
            showRange: priceDisplay.showVariantPriceRange,
            suffix: priceDisplay.priceSuffix,
          ),
          retailLabel: _spanLabel(
            priceDisplay.prefix,
            retail.min,
            retail.max,
            showRange: priceDisplay.showVariantPriceRange,
            suffix: priceDisplay.priceSuffix,
          ),
          showSelling: priceDisplay.showSelling && selling.max > 0,
          showStrike: showStrike,
          saleColor: saleColor,
          gap: envR.dp(4),
        ),
        if (showRating && rating > 0) ...[
          SizedBox(height: envR.dp(6)),
          _RatingLine(
            rating: rating,
            ratingCount: showRatingCount ? ratingCount : 0,
            color: ratingColor,
            fontColor: ratingFontColor,
            fontFamily: fontFamily,
            r: envR,
          ),
        ],
            ],
          ),
        ),
        if (showAddToCart) ...[
          SizedBox(height: envR.dp(8)),
          _ListCtaButton(
            label: ctaLabel,
            height: envR.dp(32),
            radius: addToCartRadius,
            background: isOutlined ? Colors.transparent : addToCartBg,
            foreground: addToCartFg,
            outline: isOutlined ? outlineColor : addToCartBg,
            fontFamily: fontFamily,
            fontSize: ctaFontSize ?? envR.sp(13, min: 11, max: 14),
            fontWeight: ctaFontWeight,
            onTap: onAddToCart,
            soldOut: soldOut,
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final imageW = (maxW * 0.38).clamp(96.0, 168.0);
        return Padding(
          padding: EdgeInsets.all(envR.dp(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: imageW,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpen,
                  child: image,
                ),
              ),
              SizedBox(width: envR.dp(12)),
              Expanded(child: details),
            ],
          ),
        );
      },
    );
  }
}

class _ListPriceBlock extends StatelessWidget {
  const _ListPriceBlock({
    required this.priceDisplay,
    required this.fontFamily,
    required this.sellingLabel,
    required this.retailLabel,
    required this.showSelling,
    required this.showStrike,
    required this.saleColor,
    required this.gap,
  });

  final ProductPriceDisplayConfig priceDisplay;
  final String fontFamily;
  final String sellingLabel;
  final String retailLabel;
  final bool showSelling;
  final bool showStrike;
  final Color saleColor;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (!showSelling && !showStrike) return const SizedBox.shrink();

    final selling = Text(
      sellingLabel,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppDropThemeData.textStyle(
        fontFamily: fontFamily,
        fontSize: priceDisplay.sellingFontSize,
        fontWeight: FontWeight.w600,
        color: saleColor,
      ),
    );
    final retail = Text(
      retailLabel,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppDropThemeData.textStyle(
        fontFamily: fontFamily,
        fontSize: priceDisplay.retailFontSize,
        fontWeight: FontWeight.w400,
        color: priceDisplay.strikeColor,
      ).copyWith(
        decoration: TextDecoration.lineThrough,
        decorationColor: priceDisplay.strikeColor,
      ),
    );

    final sellingFirst = !priceDisplay.retailBeforeSelling;
    final leading = sellingFirst ? selling : retail;
    final trailing = sellingFirst ? retail : selling;
    final showLeading = sellingFirst ? showSelling : showStrike;
    final showTrailing = sellingFirst ? showStrike : showSelling;

    final stacked = priceDisplay.layout == ProductPriceRowLayout.column;
    return Padding(
      padding: EdgeInsets.only(top: gap),
      child: stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showLeading) leading,
                if (showTrailing) ...[
                  if (showLeading) SizedBox(height: gap),
                  trailing,
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showLeading) Flexible(child: leading),
                if (showTrailing) ...[
                  if (showLeading) SizedBox(width: priceDisplay.sellingRetailGap),
                  Flexible(child: trailing),
                ],
              ],
            ),
    );
  }
}

class _RatingLine extends StatelessWidget {
  const _RatingLine({
    required this.rating,
    required this.ratingCount,
    required this.color,
    required this.fontColor,
    required this.fontFamily,
    required this.r,
  });

  final double rating;
  final int ratingCount;
  final Color color;
  final Color fontColor;
  final String fontFamily;
  final R r;

  @override
  Widget build(BuildContext context) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= filled
                ? FluentIcons.star_20_filled
                : FluentIcons.star_20_regular,
            size: r.dp(14),
            color: color,
          ),
        if (ratingCount > 0) ...[
          SizedBox(width: r.dp(6)),
          Flexible(
            child: Text(
              '$ratingCount Reviews',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppDropThemeData.textStyle(
                fontFamily: fontFamily,
                fontSize: r.sp(12, min: 11, max: 14),
                fontWeight: FontWeight.w500,
                color: fontColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ListCtaButton extends StatelessWidget {
  const _ListCtaButton({
    required this.label,
    required this.height,
    required this.radius,
    required this.background,
    required this.foreground,
    required this.outline,
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.onTap,
    required this.soldOut,
  });

  final String label;
  final double height;
  final double radius;
  final Color background;
  final Color foreground;
  final Color outline;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final VoidCallback? onTap;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: soldOut
              ? () => showProductSoldOutSnackBar(context)
              : onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: outline, width: 1.2),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppDropThemeData.textStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceSpan {
  const _PriceSpan(this.min, this.max);

  final double min;
  final double max;
}

_PriceSpan _priceSpan(
  Map<String, dynamic> product, {
  required bool retail,
  required double fallback,
}) {
  final values = <double>[];
  for (final variant in rawProductVariantMaps(product)) {
    final value = retail ? _retailOf(variant) : _sellingOf(variant);
    if (value != null && value > 0) values.add(value);
  }
  if (values.isEmpty) {
    final single = fallback > 0 ? fallback : 0.0;
    return _PriceSpan(single, single);
  }
  values.sort();
  return _PriceSpan(values.first, values.last);
}

double? _sellingOf(Map<String, dynamic> variant) {
  return optionalApiPrice(variant['sellingPrice']) ??
      optionalApiPrice(variant['selling_price']) ??
      optionalApiPrice(variant['price']);
}

double? _retailOf(Map<String, dynamic> variant) {
  return optionalApiPrice(variant['retailPrice']) ??
      optionalApiPrice(variant['retail_price']) ??
      optionalApiPrice(variant['compareAtPrice']) ??
      optionalApiPrice(variant['compare_at_price']) ??
      optionalApiPrice(variant['mrp']);
}

String _spanLabel(
  String prefix,
  double min,
  double max, {
  required bool showRange,
  required String suffix,
}) {
  final low = _money(prefix, min, suffix);
  if (!showRange || (max - min).abs() < 0.009) return low;
  return '$low - ${_money(prefix, max, suffix)}';
}

String _money(String prefix, double value, String suffix) {
  final negative = value < 0;
  final abs = value.abs();
  final amount = formatProductAmount(abs, suffix);
  final dot = amount.indexOf('.');
  final wholeText = dot >= 0 ? amount.substring(0, dot) : amount;
  final fraction = dot >= 0 ? amount.substring(dot) : '';
  final digits = wholeText;
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  final text = '$prefix$grouped$fraction';
  return negative ? '-$text' : text;
}

/// List-row button label. Products with more than one variant ask the shopper
/// to choose options; everything else uses the theme add-to-cart label.
String productListCtaLabel(
  Map<String, dynamic> product,
  String themeLabel, {
  String variantLabel = 'Choose options',
}) {
  if (rawProductVariantMaps(product).length > 1) {
    final variant = variantLabel.trim();
    return variant.isEmpty ? 'Choose options' : variant;
  }
  final label = themeLabel.trim();
  return label.isEmpty ? 'Add to Cart' : label;
}
