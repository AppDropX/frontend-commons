import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/network_image_url.dart';
import '../utils/component_shadow.dart';
import 'cart_remove_confirm_dialog.dart';

/// Cart item row for cart page. Fixed block on cart page (not in add-block library).
/// Shared by pilot, appdrop_preview, and builder mobile preview via [WidgetRegistry].
///
/// Props: enabled, imageUrl, productTitle, price (line subtotal), variant, quantity,
/// optional productId + product map for quantity stepper ([decrement_cart] / [add_to_cart]).
Widget buildCartItem(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final rawImage = node.s('imageUrl', def: '');
  Map<String, dynamic>? productMap;
  final rawProduct = node.props['product'];
  if (rawProduct is Map) {
    productMap = Map<String, dynamic>.from(rawProduct);
  }
  final imageUrl = sanitizedNetworkImageUrl(
        productMap != null ? productThumbnailUrl(productMap) : rawImage,
      ) ??
      sanitizedNetworkImageUrl(rawImage);

  final productTitle = node.s('productTitle', def: 'Product title');
  final price = node.s('price', def: '₹999');
  final variant = node.s('variant', def: '');
  final quantity = node.i('quantity', def: 1);
  final productId = node.s('productId', def: '').trim();
  final lineKey = node.s('lineKey', def: '').trim();
  final isFirst = node.b('isFirst', def: false);

  final variantLabel = variant.trim().isNotEmpty
      ? variant.trim()
      : (productMap != null ? variantLabelFromProductMap(productMap) : '');

  return _CartItemWidget(
    r: r,
    env: env,
    imageUrl: imageUrl,
    productTitle: productTitle,
    price: price,
    variant: variantLabel,
    quantity: quantity,
    productId: productId,
    lineKey: lineKey.isNotEmpty
        ? lineKey
        : cartLineKey(productId: productId, product: productMap),
    isFirst: isFirst,
    productMap: productMap,
  );
}

class _CartItemWidget extends StatelessWidget {
  const _CartItemWidget({
    required this.r,
    required this.env,
    required this.imageUrl,
    required this.productTitle,
    required this.price,
    required this.variant,
    required this.quantity,
    required this.productId,
    required this.lineKey,
    required this.isFirst,
    required this.productMap,
  });

  final R r;
  final AppDropBuildEnv env;
  final String? imageUrl;
  final String productTitle;
  final String price;
  final String variant;
  final int quantity;
  final String productId;
  final String lineKey;
  final bool isFirst;
  final Map<String, dynamic>? productMap;

  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _borderColor = Color(0xFFE8E4DC);

  /// Prominent but compact thumbnail.
  static const double _imageSizeDp = 80;

  static const double _cardRadiusDp = 16;
  static const double _outerHorizontalDp = 4;
  static const double _outerTopFirstDp = 16;
  static const double _innerPadDp = 12;
  static const double _imageGapDp = 12;

  /// Middle row between title and price — variant and optional unit price.
  String _middleLine(double unitPrice) {
    final parts = <String>[];
    if (variant.isNotEmpty) parts.add(variant);
    if (unitPrice > 0 && quantity > 1) {
      final formatted = unitPrice == unitPrice.roundToDouble()
          ? unitPrice.toStringAsFixed(0)
          : unitPrice.toStringAsFixed(2);
      parts.add('₹$formatted each');
    }
    return parts.join(' · ');
  }

  Future<void> _confirmAndRemove(BuildContext context) async {
    final confirmed = await showCartRemoveConfirmDialog(context);
    if (!confirmed || !context.mounted) return;
    env.dispatchAction(context, {
      'type': 'remove_from_cart',
      'productId': productId,
      'lineKey': lineKey,
    });
  }

  Future<void> _onDecrement(BuildContext context) async {
    if (quantity <= 1) {
      await _confirmAndRemove(context);
      return;
    }
    env.dispatchAction(context, {
      'type': 'decrement_cart',
      'productId': productId,
      'lineKey': lineKey,
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = resolveAppDropPrimaryColor(context);
    final titleColor = AppDropThemeScope.maybeOf(context)?.appStyling.fontIconColor ??
        const Color(0xFF111827);
    final imageSize = r.dp(_imageSizeDp);
    final unitPrice = productMap != null
        ? sellingPriceFromApiProduct(productMap!)
        : 0.0;
    final canOpenProduct = productId.isNotEmpty && productMap != null;
    final middleLine = _middleLine(unitPrice);
    final radius = BorderRadius.circular(r.dp(_cardRadiusDp));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        r.dp(_outerHorizontalDp),
        isFirst ? r.dp(_outerTopFirstDp) : 0,
        r.dp(_outerHorizontalDp),
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: radius,
          border: Border.all(color: _borderColor),
          boxShadow: kAppDropCartItemShadows,
        ),
        child: Material(
          color: _cardColor,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: canOpenProduct
                  ? () => env.dispatchAction(context, {
                        'type': 'open_product',
                        'productId': productId,
                        'product': productMap,
                      })
                  : null,
              child: Padding(
                padding: EdgeInsets.all(r.dp(_innerPadDp)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(r.dp(12)),
                      child: SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: _CartThumbnail(imageUrl: imageUrl),
                      ),
                    ),
                    SizedBox(width: r.dp(_imageGapDp)),
                    Expanded(
                      child: SizedBox(
                        height: imageSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: r.dp(28)),
                                  child: Text(
                                    productTitle.isEmpty
                                        ? 'Product title'
                                        : productTitle,
                                    style: TextStyle(
                                      fontSize: r.sp(14, min: 13, max: 15),
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                      color: titleColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  height: r.dp(15),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      middleLine,
                                      style: TextStyle(
                                        fontSize: r.sp(12, min: 11, max: 13),
                                        fontWeight: FontWeight.w500,
                                        height: 1.15,
                                        color: const Color(0xFF6B7280),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        price.isEmpty ? '₹0' : price,
                                        style: TextStyle(
                                          fontSize: r.sp(15, min: 14, max: 16),
                                          fontWeight: FontWeight.w700,
                                          height: 1.0,
                                          color: titleColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (productId.isNotEmpty || lineKey.isNotEmpty)
                                      _CartQtyStepper(
                                        r: r,
                                        quantity: quantity,
                                        accentColor: primaryColor,
                                        onDecrement: () => _onDecrement(context),
                                        onIncrement: () =>
                                            env.dispatchAction(context, {
                                          'type': 'add_to_cart',
                                          'direct': true,
                                          'productId': productId,
                                          'lineKey': lineKey,
                                          'product':
                                              productMap ?? <String, dynamic>{},
                                        }),
                                      )
                                    else
                                      Text(
                                        'Qty: $quantity',
                                        style: TextStyle(
                                          fontSize: r.sp(12),
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            if (productId.isNotEmpty || lineKey.isNotEmpty)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: _CartDeleteButton(
                                  r: r,
                                  onTap: () => _confirmAndRemove(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _CartThumbnail extends StatelessWidget {
  const _CartThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const ColoredBox(
        color: Color(0xFFF3F4F6),
        child: Center(
          child: Icon(
            FluentIcons.image_off_20_regular,
            size: 22,
            color: Color(0xFF9CA3AF),
          ),
        ),
      );
    }
    return AppDropNetworkImage(
      url: imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFF3F4F6),
        child: Center(
          child: Icon(
            FluentIcons.image_off_20_regular,
            size: 22,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

class _CartDeleteButton extends StatelessWidget {
  const _CartDeleteButton({required this.r, required this.onTap});

  final R r;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove from cart',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r.dp(18)),
          child: SizedBox(
            width: r.dp(32),
            height: r.dp(32),
            child: Icon(
              FluentIcons.delete_24_regular,
              size: r.dp(17),
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartQtyStepper extends StatelessWidget {
  const _CartQtyStepper({
    required this.r,
    required this.quantity,
    required this.accentColor,
    required this.onDecrement,
    required this.onIncrement,
  });

  final R r;
  final int quantity;
  final Color accentColor;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  static const double _buttonDp = 32;
  static const double _minTouchDp = 36;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(r.dp(18)),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            r: r,
            icon: FluentIcons.subtract_20_regular,
            onTap: onDecrement,
            accentColor: accentColor,
            isLeading: true,
            sizeDp: _buttonDp,
            minTouchDp: _minTouchDp,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.dp(6)),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: r.dp(16)),
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.sp(13, min: 12, max: 14),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ),
          _QtyButton(
            r: r,
            icon: FluentIcons.add_20_regular,
            onTap: onIncrement,
            accentColor: accentColor,
            isLeading: false,
            sizeDp: _buttonDp,
            minTouchDp: _minTouchDp,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.r,
    required this.icon,
    required this.onTap,
    required this.accentColor,
    required this.isLeading,
    required this.sizeDp,
    required this.minTouchDp,
  });

  final R r;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;
  final bool isLeading;
  final double sizeDp;
  final double minTouchDp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: isLeading ? Radius.circular(r.dp(18)) : Radius.zero,
          right: !isLeading ? Radius.circular(r.dp(18)) : Radius.zero,
        ),
        child: SizedBox(
          width: r.dp(minTouchDp),
          height: r.dp(sizeDp),
          child: Icon(icon, size: r.dp(16), color: accentColor),
        ),
      ),
    );
  }
}
