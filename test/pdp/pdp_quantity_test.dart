import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/pdp/pdp_product_scope.dart';
import 'package:frontend_commons/product/product_variant_model.dart';

void main() {
  Map<String, dynamic> product() => {
        'title': 'Tee',
        'variants': [
          {
            'id': 's',
            'title': 'S',
            'price': 10,
            'inventory_quantity': 3,
          },
          {
            'id': 'm',
            'title': 'M',
            'price': 12,
            'inventory_quantity': 8,
          },
        ],
      };

  test('variant change resets quantity and stock caps the ceiling', () {
    final controller = PdpProductController(product());
    expect(controller.selectedVariant, isNull);
    controller.appliedCeiling = 3;
    controller.setQuantity(3);
    expect(controller.quantity, 3);

    controller.selectVariant(1);
    expect(controller.selectedVariant?.id, 'm');
    expect(controller.quantity, 1);
    expect(
      pdpQuantityCeiling(
        product: controller.product,
        variant: controller.selectedVariant,
        configuredMax: 10,
      ),
      8,
    );
    expect(
      pdpQuantityCeiling(
        product: controller.product,
        variant: controller.variants.first,
        configuredMax: 10,
      ),
      3,
    );
  });

  test('sold out selection has a zero ceiling', () {
    final soldOut = {
      'title': 'Tee',
      'variants': [
        {
          'id': 's',
          'title': 'S',
          'price': 10,
          'inventory_quantity': 0,
        },
      ],
    };
    final controller = PdpProductController(soldOut);
    expect(
      pdpSelectionIsSoldOut(
        product: controller.product,
        variant: controller.selectedVariant,
      ),
      isTrue,
    );
    expect(
      pdpQuantityCeiling(
        product: controller.product,
        variant: controller.selectedVariant,
        configuredMax: 10,
      ),
      0,
    );
  });

  test('cart add keeps a single variant line inside stock', () {
    expect(
      nextCartLineQuantity(existing: 0, requested: 3, stock: 5),
      3,
    );
    expect(
      nextCartLineQuantity(existing: 4, requested: 3, stock: 5),
      5,
    );
    expect(
      nextCartLineQuantity(existing: 5, requested: 1, stock: 5),
      5,
    );
    expect(
      cartQuantityFromAction({'quantity': 4}),
      4,
    );
  });
}
