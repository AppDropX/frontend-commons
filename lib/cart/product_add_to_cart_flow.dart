import 'package:flutter/material.dart';

import '../widgets/product_selection_bottom_sheet.dart';

typedef ProductActionResolver = Map<String, dynamic> Function(
  Map<String, dynamic> action,
  String productId,
);

typedef AddToCartCommitter = void Function(
  Map<String, dynamic> action,
  Map<String, dynamic> product,
);

typedef OpenProductNavigator = void Function(Map<String, dynamic> openAction);

/// Routes add-to-cart through the product selection sheet unless [direct] is true.
Future<void> presentAddToCartFlow({
  required BuildContext context,
  required Map<String, dynamic> action,
  required ProductActionResolver resolveProduct,
  required AddToCartCommitter commitAddToCart,
  required OpenProductNavigator openProduct,
}) async {
  final id = action['productId']?.toString() ?? '';
  if (id.isEmpty) return;

  final product = resolveProduct(action, id);
  if (product.isEmpty) return;

  if (action['direct'] == true) {
    commitAddToCart({...action, 'product': product}, product);
    return;
  }

  if (!context.mounted) return;

  await showProductSelectionBottomSheet(
    context: context,
    product: product,
    productId: id,
    onViewDetails: () {
      openProduct({
        'type': 'open_product',
        'productId': id,
        'product': product,
        if (action['heroTag'] != null) 'heroTag': action['heroTag'],
      });
    },
    onAddToCart: (effectiveProduct) {
      commitAddToCart(
        {
          ...action,
          'direct': true,
          'productId': id,
          'product': effectiveProduct,
        },
        effectiveProduct,
      );
    },
  );
}
