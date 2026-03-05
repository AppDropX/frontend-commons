import 'package:flutter/material.dart';
import '../theme_library.dart';

/// Cart item row for cart page. Fixed block on cart page (not in add-block library).
/// Props: enabled, imageUrl, productTitle, price, variant, quantity.
Widget buildCartItem(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final imageUrl = node.s('imageUrl', def: '');
  final productTitle = node.s('productTitle', def: 'Product title');
  final price = node.s('price', def: '₹999');
  final variant = node.s('variant', def: 'Variant');
  final quantity = node.i('quantity', def: 1);

  return _CartItemWidget(
    r: r,
    imageUrl: imageUrl,
    productTitle: productTitle,
    price: price,
    variant: variant,
    quantity: quantity,
  );
}

class _CartItemWidget extends StatelessWidget {
  const _CartItemWidget({
    required this.r,
    required this.imageUrl,
    required this.productTitle,
    required this.price,
    required this.variant,
    required this.quantity,
  });

  final R r;
  final String imageUrl;
  final String productTitle;
  final String price;
  final String variant;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.dp(16), vertical: r.dp(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(r.dp(8)),
            child: Container(
              width: r.dp(80),
              height: r.dp(80),
              color: Colors.grey.shade200,
              child: imageUrl.isEmpty
                  ? null
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: r.dp(80),
                      height: r.dp(80),
                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: r.dp(32), color: Colors.grey.shade400),
                    ),
            ),
          ),
          SizedBox(width: r.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productTitle.isEmpty ? 'Product title' : productTitle,
                  style: TextStyle(
                    fontSize: r.sp(14, min: 12, max: 16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: r.dp(4)),
                Text(
                  variant.isEmpty ? 'Variant' : variant,
                  style: TextStyle(
                    fontSize: r.sp(12, min: 10, max: 14),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: r.dp(8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price.isEmpty ? '₹0' : price,
                      style: TextStyle(
                        fontSize: r.sp(14, min: 12, max: 16),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Qty: $quantity',
                      style: TextStyle(
                        fontSize: r.sp(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
