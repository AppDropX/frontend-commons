import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/pdp/pdp_product_scope.dart';
import 'package:frontend_commons/src/responsive.dart';
import 'package:frontend_commons/src/widget_node.dart';
import 'package:frontend_commons/widgets/pdp_product_cta_block.dart';
import 'package:frontend_commons/widgets/pdp_product_quantity_block.dart';

void main() {
  Map<String, dynamic> product({required int stock}) => {
        'productId': 'tee',
        'title': 'Tee',
        'variants': [
          {
            'id': 's',
            'title': 'S',
            'price': 10,
            'inventory_quantity': stock,
          },
          {
            'id': 'm',
            'title': 'M',
            'price': 12,
            'inventory_quantity': 9,
          },
        ],
      };

  Future<PdpProductController> pump(
    WidgetTester tester, {
    required int stock,
    int maxQuantity = 10,
    void Function(Map<String, dynamic> action)? onAction,
  }) async {
    final controller = PdpProductController(product(stock: stock));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PdpProductScope(
            controller: controller,
            child: Builder(
              builder: (context) {
                final env = AppDropBuildEnv(
                  r: R.fromConstraints(
                    context,
                    const BoxConstraints(maxWidth: 330, maxHeight: 700),
                  ),
                  renderNode: (_, __) => const SizedBox.shrink(),
                  onAction: onAction == null
                      ? null
                      : (_, action) => onAction(action),
                );
                return Column(
                  children: [
                    buildPdpProductQuantityBlock(
                      context,
                      WidgetNode(
                        type: 'pdp_product_quantity',
                        props: {
                          'max_quantity': maxQuantity,
                          'heading': 'Quantity',
                        },
                      ),
                      env,
                    ),
                    buildPdpProductCtaBlock(
                      context,
                      WidgetNode(
                        type: 'pdp_product_cta',
                        props: {
                          'button_title': 'Add to Cart',
                          'show_buy_now': true,
                          'buy_now_title': 'Buy Now',
                          'action': {
                            'type': 'add_to_cart',
                            'productId': 'tee',
                          },
                        },
                      ),
                      env,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('plus stops at stock and a variant change resets to 1', (
    tester,
  ) async {
    final controller = await pump(tester, stock: 2, maxQuantity: 10);
    expect(controller.selectedVariant, isNull);
    controller.selectVariant(0);
    await tester.pump();
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Increase quantity'));
    await tester.pump();
    expect(controller.quantity, 2);

    await tester.tap(find.bySemanticsLabel('Increase quantity'));
    await tester.pump();
    expect(controller.quantity, 2);

    controller.selectVariant(1);
    await tester.pump();
    expect(controller.quantity, 1);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('add to cart sends one variant quantity then resets', (
    tester,
  ) async {
    Map<String, dynamic>? sent;
    final controller = await pump(
      tester,
      stock: 6,
      onAction: (action) => sent = action,
    );
    controller.selectVariant(0);
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Increase quantity'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Increase quantity'));
    await tester.pump();

    await tester.tap(find.text('Add to Cart'));
    await tester.pump();

    expect(sent?['type'], 'add_to_cart');
    expect(sent?['quantity'], 3);
    expect(controller.quantity, 1);

    await tester.tap(find.text('Buy Now'));
    await tester.pump();
    expect(sent?['type'], 'buy_now');
    expect(sent?['quantity'], 1);
    expect(sent?['variantId'], 's');
  });

  testWidgets('sold out dulls both buttons until dull is turned off', (
    tester,
  ) async {
    Future<void> pumpSoldOut({required bool dull}) {
      final controller = PdpProductController({
        'productId': 'tee',
        'title': 'Tee',
        'variants': [
          {
            'id': 's',
            'title': 'S',
            'price': 10,
            'inventory_quantity': 0,
          },
        ],
      });
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdpProductScope(
              controller: controller,
              child: Builder(
                builder: (context) {
                  return buildPdpProductCtaBlock(
                    context,
                    WidgetNode(
                      type: 'pdp_product_cta',
                      props: {
                        'button_title': 'Add to Cart',
                        'show_buy_now': true,
                        'buy_now_title': 'Buy Now',
                        'sold_out_dull': dull,
                        'sold_out_title': 'Gone',
                        'sold_out_bg_color': '#111111',
                        'buy_now_sold_out_dull': dull,
                        'buy_now_sold_out_title': 'Unavailable',
                        'action': {'type': 'add_to_cart', 'productId': 'tee'},
                      },
                    ),
                    AppDropBuildEnv(
                      r: R.fromConstraints(
                        context,
                        const BoxConstraints(maxWidth: 330, maxHeight: 700),
                      ),
                      renderNode: (_, __) => const SizedBox.shrink(),
                      onAction: (_, __) => fail('sold out button should not fire'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    await pumpSoldOut(dull: true);
    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.text('Gone'), findsNothing);
    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    expect(find.text('This product is sold out'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1800));

    BoxDecoration paintOf(String label) {
      final ink = tester.widget<Ink>(
        find.ancestor(of: find.text(label), matching: find.byType(Ink)).first,
      );
      return ink.decoration! as BoxDecoration;
    }

    expect(paintOf('Add to Cart').color, const Color(0xFFE5E7EB));

    await pumpSoldOut(dull: false);
    expect(find.text('Gone'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(paintOf('Gone').color, const Color(0xFF111111));
  });
}
