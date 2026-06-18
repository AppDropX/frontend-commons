import 'package:flutter/material.dart';

import '../pdp/pdp_product_scope.dart';
import '../src/responsive.dart';
import '../theme/appdrop_theme_scope.dart';
import 'variant_choice_chips.dart';

/// Opens a Material 3 product selection sheet before adding to cart.
Future<void> showProductSelectionBottomSheet({
  required BuildContext context,
  required Map<String, dynamic> product,
  required String productId,
  required VoidCallback onViewDetails,
  required ValueChanged<Map<String, dynamic>> onAddToCart,
}) {
  final themeConfig = AppDropThemeScope.maybeOf(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      Widget sheet = ProductSelectionBottomSheet(
        product: product,
        productId: productId,
        onViewDetails: () {
          Navigator.of(sheetContext).pop();
          onViewDetails();
        },
        onAddToCart: (effectiveProduct) {
          Navigator.of(sheetContext).pop();
          onAddToCart(effectiveProduct);
        },
      );
      if (themeConfig != null) {
        sheet = AppDropThemeScope(config: themeConfig, child: sheet);
      }
      return sheet;
    },
  );
}

class ProductSelectionBottomSheet extends StatefulWidget {
  const ProductSelectionBottomSheet({
    super.key,
    required this.product,
    required this.productId,
    required this.onViewDetails,
    required this.onAddToCart,
  });

  final Map<String, dynamic> product;
  final String productId;
  final VoidCallback onViewDetails;
  final ValueChanged<Map<String, dynamic>> onAddToCart;

  @override
  State<ProductSelectionBottomSheet> createState() =>
      _ProductSelectionBottomSheetState();
}

class _ProductSelectionBottomSheetState
    extends State<ProductSelectionBottomSheet> {
  late final PdpProductController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdpProductController(widget.product)
      ..addListener(_onControllerChanged);
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
    final size = MediaQuery.sizeOf(context);
    final r = R.fromConstraints(
      context,
      BoxConstraints(maxWidth: size.width, maxHeight: size.height),
    );
    final theme = Theme.of(context);
    final primaryColor = resolveAppDropPrimaryColor(context);
    final onPrimaryColor = resolveAppDropOnPrimaryColor(primaryColor);
    const surfaceColor = Colors.white;
    final borderColor = theme.dividerColor.withValues(alpha: 0.35);
    final title = (widget.product['title'] ?? '').toString().trim();
    final selling = _controller.sellingPrice;
    final retail = _controller.retailPrice;
    final discount = _controller.discountPercent;
    final showRetail = retail > selling && retail > 0;
    final showDiscount = discount > 0;
    final showVariants = _controller.variants.length > 1;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(r.dp(20)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: r.dp(8)),
            Center(
              child: Container(
                width: r.dp(36),
                height: r.dp(4),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(r.dp(999)),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  r.dp(16),
                  r.dp(12),
                  r.dp(16),
                  r.dp(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.sp(16, min: 15, max: 18),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                          height: 1.25,
                        ),
                      ),
                    if (title.isNotEmpty) SizedBox(height: r.dp(10)),
                    _PriceRow(
                      r: r,
                      selling: selling,
                      retail: retail,
                      discount: discount,
                      showRetail: showRetail,
                      showDiscount: showDiscount,
                      accentColor: primaryColor,
                    ),
                    SizedBox(height: r.dp(6)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.dp(4),
                            vertical: r.dp(2),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: primaryColor,
                        ),
                        onPressed: widget.onViewDetails,
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: r.sp(13, min: 12, max: 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (showVariants) ...[
                      SizedBox(height: r.dp(10)),
                      VariantChoiceChipWrap(
                        groupLabel: _controller.variantGroupLabel,
                        variantLabels: [
                          for (final v in _controller.variants) v.label,
                        ],
                        selectedIndex: _controller.selectedIndex,
                        labelColor: const Color(0xFF111827),
                        primaryColor: primaryColor,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        r: r,
                        onSelect: _controller.selectVariant,
                      ),
                    ],
                  ],
                ),
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
                child: SizedBox(
                  width: double.infinity,
                  height: r.dp(40),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: onPrimaryColor,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: r.dp(8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(r.dp(10)),
                      ),
                    ),
                    onPressed: () =>
                        widget.onAddToCart(_controller.effectiveProduct),
                    child: Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: r.sp(15, min: 14, max: 16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.r,
    required this.selling,
    required this.retail,
    required this.discount,
    required this.showRetail,
    required this.showDiscount,
    required this.accentColor,
  });

  final R r;
  final double selling;
  final double retail;
  final int discount;
  final bool showRetail;
  final bool showDiscount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: r.dp(8),
      runSpacing: r.dp(4),
      children: [
        if (selling > 0)
          Text(
            _formatRupee(selling),
            style: TextStyle(
              fontSize: r.sp(18, min: 16, max: 20),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
        if (showRetail)
          Text(
            _formatRupee(retail),
            style: TextStyle(
              fontSize: r.sp(13, min: 12, max: 14),
              color: const Color(0xFF9CA3AF),
              decoration: TextDecoration.lineThrough,
              decorationColor: const Color(0xFF9CA3AF),
            ),
          ),
        if (showDiscount)
          Text(
            '$discount% OFF',
            style: TextStyle(
              fontSize: r.sp(12, min: 11, max: 13),
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
      ],
    );
  }

  String _formatRupee(double value) {
    final rounded = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '₹$rounded';
  }
}
