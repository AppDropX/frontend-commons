import 'package:flutter/material.dart';

import '../cart/add_to_cart_sheet_config.dart';
import '../pdp/pdp_product_scope.dart';
import '../product/product_variant_model.dart';
import '../src/responsive.dart';
import '../src/widget_node.dart';
import '../theme/appdrop_theme_data.dart';
import '../theme/appdrop_theme_scope.dart';
import '../utils/color.dart';
import '../utils/appdrop_snackbar.dart';
import '../utils/product_block_theme_helpers.dart';
import 'pdp_product_quantity_block.dart';
import 'product_block_add_to_cart_button.dart';
import 'product_price_row.dart';
import 'product_variant.dart';

typedef ProductSheetAddCallback = void Function(
  Map<String, dynamic> product,
  int quantity,
);

/// Opens the product-grid add-to-cart sheet or popup before adding to cart.
Future<void> showProductSelectionBottomSheet({
  required BuildContext context,
  required Map<String, dynamic> product,
  required String productId,
  required VoidCallback onViewDetails,
  required ProductSheetAddCallback onAddToCart,
}) {
  final themeConfig = AppDropThemeScope.maybeOf(context);
  final sheetConfig = AddToCartSheetConfig.fromProductBlock(
    themeConfig?.productBlock ?? const {},
  );

  Widget themed(Widget child) {
    if (themeConfig == null) return child;
    return AppDropThemeScope(config: themeConfig, child: child);
  }

  if (sheetConfig.isPopup) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (sheetContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: themed(
            ProductSelectionSheet(
              product: product,
              productId: productId,
              config: sheetConfig,
              onClose: () => Navigator.of(sheetContext).pop(),
              onViewDetails: () {
                Navigator.of(sheetContext).pop();
                onViewDetails();
              },
              onAddToCart: (effectiveProduct, quantity) {
                Navigator.of(sheetContext).pop();
                onAddToCart(effectiveProduct, quantity);
              },
            ),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return themed(
        ProductSelectionSheet(
          product: product,
          productId: productId,
          config: sheetConfig,
          onViewDetails: () {
            Navigator.of(sheetContext).pop();
            onViewDetails();
          },
          onAddToCart: (effectiveProduct, quantity) {
            Navigator.of(sheetContext).pop();
            onAddToCart(effectiveProduct, quantity);
          },
        ),
      );
    },
  );
}

/// Card shown from a product grid Add to cart tap, or pinned in theme preview.
class ProductSelectionSheet extends StatefulWidget {
  const ProductSelectionSheet({
    super.key,
    required this.product,
    required this.productId,
    required this.config,
    this.onViewDetails,
    this.onAddToCart,
    this.onClose,
    this.preview = false,
  });

  final Map<String, dynamic> product;
  final String productId;
  final AddToCartSheetConfig config;
  final VoidCallback? onViewDetails;
  final ProductSheetAddCallback? onAddToCart;
  final VoidCallback? onClose;

  /// Theme-settings preview. Variant and quantity stay interactive.
  /// Add to cart and close do not leave the preview.
  final bool preview;

  @override
  State<ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<ProductSelectionSheet> {
  late PdpProductController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdpProductController(
      widget.product,
      selectFirstInStock: false,
    )..addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ProductSelectionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.product, widget.product)) return;
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _controller = PdpProductController(
      widget.product,
      selectFirstInStock: false,
    )..addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popup = widget.config.isPopup;
    final size = MediaQuery.sizeOf(context);
    final cap = size.height * (popup ? 0.72 : 0.78);
    final r = R.fromConstraints(
      context,
      BoxConstraints(maxWidth: size.width, maxHeight: size.height),
    );
    final corner = r.dp(widget.config.cornerRadius.clamp(0, 24));
    final radius = popup
        ? BorderRadius.circular(corner)
        : BorderRadius.vertical(top: Radius.circular(corner));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: cap),
        child: Material(
          color: Colors.white,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: PdpProductScope(
            controller: _controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!popup) _Handle(r: r),
                if (popup)
                  _CloseButton(
                    preview: widget.preview,
                    onClose: widget.onClose,
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (cap - r.dp(popup ? 96 : 88)).clamp(120, cap),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(
                      r.dp(16),
                      popup ? 0 : r.dp(12),
                      r.dp(16),
                      r.dp(8),
                    ),
                    children: [
                      _SheetBody(
                      product: widget.product,
                      config: widget.config,
                      controller: _controller,
                      r: r,
                      preview: widget.preview,
                      onViewDetails: widget.onViewDetails,
                    ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.dp(16),
                    r.dp(8),
                    r.dp(16),
                    r.dp(12),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Builder(
                      builder: (buttonContext) {
                        final soldOut = productSoldOutCta(
                          AppDropThemeScope.maybeOf(buttonContext)
                                  ?.productBlock ??
                              const {},
                          _controller.product,
                        );
                        final label = soldOut?.label ?? _ctaLabel(buttonContext);
                        return Semantics(
                          button: true,
                          label: label,
                          child: ProductBlockAddToCartButton(
                            r: r,
                            heightDp: 48,
                            label: label,
                            onTap: widget.preview
                                ? () {}
                                : () {
                                    if (soldOut != null) {
                                      showProductSoldOutSnackBar(buttonContext);
                                      return;
                                    }
                                    _commitAdd();
                                  },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _commitAdd() {
    if (!_controller.hasSelection && _controller.variants.length > 1) {
      final index = _controller.variants.indexWhere((v) => !v.isOutOfStock);
      if (index < 0) return;
      _controller.selectVariant(index);
    }
    final quantity = _controller.quantity;
    if (quantity < 1) return;
    widget.onAddToCart?.call(_controller.effectiveProduct, quantity);
  }

  String _ctaLabel(BuildContext context) {
    final pb = AppDropThemeScope.maybeOf(context)?.productBlock ?? const {};
    return productBlockSetting(pb, 'cta_text', 'Add to Cart');
  }
}

FontWeight _sheetFontWeight(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'bold':
      return FontWeight.w700;
    case 'regular':
      return FontWeight.w400;
    case 'semi_bold':
    case 'semibold':
      return FontWeight.w600;
    default:
      return FontWeight.w600;
  }
}

class _PriceEnds {
  const _PriceEnds(this.low, this.high);

  final double low;
  final double high;

  bool get hasSpread => (high - low).abs() > 0.009;
}

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

String _rangeLabel(_PriceEnds ends, String prefix, String suffix) {
  final low = formatProductMoney(ends.low, prefix, suffix: suffix);
  if (!ends.hasSpread) return low;
  return '$low - ${formatProductMoney(ends.high, prefix, suffix: suffix)}';
}

/// A variant price range stacks. One price stays on a single row.
class _SheetPrice extends StatelessWidget {
  const _SheetPrice({
    required this.product,
    required this.controller,
    required this.r,
    required this.family,
  });

  final Map<String, dynamic> product;
  final PdpProductController controller;
  final R r;
  final String family;

  @override
  Widget build(BuildContext context) {
    final cfg = ProductPriceDisplayConfig.fromContext(context);
    final sellingSize = cfg.sellingFontSize + r.sp(4, min: 3, max: 5);
    final retailSize = cfg.retailFontSize + r.sp(2, min: 2, max: 4);
    final sellingEnds = _variantEnds(product, retail: false);
    final retailEnds = _variantEnds(product, retail: true);
    final stack = !controller.hasSelection &&
        ((sellingEnds?.hasSpread ?? false) || (retailEnds?.hasSpread ?? false));
    if (!stack) {
      final selling = controller.hasSelection && controller.sellingPrice > 0
          ? controller.sellingPrice
          : sellingPriceFromApiProduct(product);
      final retail = controller.hasSelection && controller.retailPrice > 0
          ? controller.retailPrice
          : retailPriceFromApiProduct(product, selling);
      final discount = retail > selling && retail > 0
          ? (((retail - selling) / retail) * 100).round()
          : 0;
      return ProductPriceRow(
        sellingPrice: selling,
        retailPrice: retail,
        discountPercent: discount,
        layout: ProductPriceRowLayout.row,
        sellingFontSize: sellingSize,
        retailFontSize: retailSize,
      );
    }

    final sellingStyle = AppDropThemeData.textStyle(
      fontFamily: family,
      fontSize: sellingSize,
      fontWeight: cfg.priceFontWeight,
      color: cfg.priceColor,
    );
    final retailStyle = TextStyle(
      fontFamily: family,
      fontSize: retailSize,
      color: cfg.strikeColor,
      decoration:
          cfg.showStrike ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: cfg.strikeColor,
    );
    final sellingText = sellingEnds == null
        ? null
        : Text(
            _rangeLabel(sellingEnds, cfg.prefix, cfg.priceSuffix),
            style: sellingStyle,
          );
    final retailText = !cfg.showRetail || retailEnds == null
        ? null
        : Text(
            _rangeLabel(retailEnds, cfg.prefix, cfg.priceSuffix),
            style: retailStyle,
          );
    final lines = <Widget>[
      if (cfg.retailBeforeSelling) ...[
        if (retailText != null) retailText,
        if (cfg.showSelling && sellingText != null) sellingText,
      ] else ...[
        if (cfg.showSelling && sellingText != null) sellingText,
        if (retailText != null) retailText,
      ],
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) SizedBox(height: r.dp(4)),
          lines[i],
        ],
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.r});

  final R r;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: r.dp(8), bottom: r.dp(4)),
      child: Center(
        child: Container(
          width: r.dp(36),
          height: r.dp(4),
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(r.dp(999)),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.preview, required this.onClose});

  final bool preview;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        tooltip: 'Close',
        onPressed: preview ? () {} : onClose,
        icon: const Icon(Icons.close),
        color: const Color(0xFF111827),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.product,
    required this.config,
    required this.controller,
    required this.r,
    required this.preview,
    required this.onViewDetails,
  });

  final Map<String, dynamic> product;
  final AddToCartSheetConfig config;
  final PdpProductController controller;
  final R r;
  final bool preview;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final pb = AppDropThemeScope.maybeOf(context)?.productBlock ?? const {};
    final family =
        AppDropThemeScope.maybeOf(context)?.appStyling.fontFamily ?? 'Poppins';
    final title = (product['title'] ?? '').toString().trim();
    final shownTitle = displayProductTitle(
      title,
      productBlockSettingBool(pb, 'upper_case_title', true),
    );
    final titleColor = parseHexColor(config.titleColor) ??
        parseHexColor(pb['title_color']?.toString()) ??
        const Color(0xFF111827);
    final openProduct = preview ? null : onViewDetails;
    final env = AppDropBuildEnv(
      r: r,
      renderNode: (_, __) => const SizedBox.shrink(),
      interactiveFeaturesEnabled: true,
    );
    final variantNode = WidgetNode(
      type: 'product_variant',
      props: {
        ...config.variant,
        'enabled': true,
        'product': product,
      },
    );
    final quantityNode = WidgetNode(
      type: 'pdp_product_quantity',
      props: {
        'enabled': true,
        'max_quantity': config.maxQuantity,
        'style': config.quantityStyle,
        'style_color': config.quantityStyleColor,
        'show_title': true,
        'heading': config.quantityHeading,
        'heading_color': '#111827',
        'heading_size': 14,
        'heading_font_variation': 'semi_bold',
        'font_size': 16,
        'font_variation': 'semi_bold',
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shownTitle.isNotEmpty)
          Semantics(
            button: openProduct != null,
            label: shownTitle,
            child: InkWell(
              onTap: openProduct,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: r.dp(48)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    shownTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppDropThemeData.textStyle(
                      fontFamily: family,
                      fontSize: r.sp(config.titleSize, min: 14, max: 28),
                      fontWeight: _sheetFontWeight(config.titleFontVariation),
                      color: titleColor,
                    ).copyWith(height: 1.25),
                  ),
                ),
              ),
            ),
          ),
        if (shownTitle.isNotEmpty) SizedBox(height: r.dp(10)),
        _SheetPrice(
          product: product,
          controller: controller,
          r: r,
          family: family,
        ),
        SizedBox(height: r.dp(12)),
        buildProductVariant(context, variantNode, env),
        if (config.showQuantity) ...[
          SizedBox(height: r.dp(16)),
          buildPdpProductQuantityBlock(context, quantityNode, env),
        ],
      ],
    );
  }
}
