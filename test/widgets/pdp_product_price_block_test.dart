import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/pdp/pdp_product_scope.dart';
import 'package:frontend_commons/src/responsive.dart';
import 'package:frontend_commons/src/widget_node.dart';
import 'package:frontend_commons/widgets/pdp_product_price_block.dart';

void main() {
  Map<String, dynamic> rangedProduct() => {
        'sellingPrice': 100,
        'retailPrice': 140,
        'variants': [
          {'id': 's', 'title': 'S', 'price': 100, 'compare_at_price': 140},
          {'id': 'm', 'title': 'M', 'price': 180, 'compare_at_price': 200},
        ],
      };

  Map<String, dynamic> sellingRangeOnly() => {
        'sellingPrice': 100,
        'retailPrice': 200,
        'variants': [
          {'id': 's', 'title': 'S', 'price': 100, 'compare_at_price': 200},
          {'id': 'm', 'title': 'M', 'price': 180, 'compare_at_price': 200},
        ],
      };

  Map<String, dynamic> flatProduct() => {
        'sellingPrice': 100,
        'retailPrice': 140,
        'variants': [
          {'id': 's', 'title': 'S', 'price': 100, 'compare_at_price': 140},
          {'id': 'm', 'title': 'M', 'price': 100, 'compare_at_price': 140},
        ],
      };

  Future<void> pump(
    WidgetTester tester,
    Map<String, dynamic> product,
    Map<String, dynamic> props,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return buildPdpProductPriceBlock(
                context,
                WidgetNode(
                  type: 'pdp_product_price',
                  props: {'product': product, ...props},
                ),
                AppDropBuildEnv(
                  r: R.fromConstraints(
                    context,
                    const BoxConstraints(maxWidth: 330, maxHeight: 700),
                  ),
                  renderNode: (_, __) => const SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('retail range is struck through above the selling range', (
    tester,
  ) async {
    await pump(tester, rangedProduct(), {
      'price_range': true,
      'price_order': 'secondary_first',
      'price_style': 'current_only',
    });

    final retail = tester.widget<Text>(find.text('₹140 - ₹200'));
    final selling = tester.widget<Text>(find.text('₹100 - ₹180'));
    expect(retail.style?.decoration, TextDecoration.lineThrough);
    expect(selling.style?.decoration, isNot(TextDecoration.lineThrough));

    final retailBox = tester.getRect(find.text('₹140 - ₹200'));
    final sellingBox = tester.getRect(find.text('₹100 - ₹180'));
    expect(retailBox.bottom, lessThan(sellingBox.top + 1));
    expect(retailBox.left, closeTo(sellingBox.left, 1));
  });

  testWidgets('a single retail price stays under the selling range line', (
    tester,
  ) async {
    await pump(tester, sellingRangeOnly(), {
      'price_range': true,
      'price_order': 'primary_first',
    });

    final selling = tester.getRect(find.text('₹100 - ₹180'));
    final retail = tester.getRect(find.text('₹200'));
    expect(selling.bottom, lessThan(retail.top + 1));
    expect(selling.left, closeTo(retail.left, 1));
    expect(
      tester.widget<Text>(find.text('₹200')).style?.decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('selling and retail keep separate size and weight', (
    tester,
  ) async {
    await pump(tester, flatProduct(), {
      'price_range': false,
      'font_variation': 'regular',
      'price_size': 22,
      'retail_font_variation': 'bold',
      'retail_size': 12,
      'retail_color': '#B91C1C',
    });

    final selling = tester.widget<Text>(find.text('₹100'));
    final retail = tester.widget<Text>(find.text('₹140'));
    expect(selling.style?.fontWeight, FontWeight.w400);
    expect(retail.style?.fontWeight, FontWeight.w700);
    expect(selling.style?.fontSize, greaterThan(retail.style!.fontSize!));
    expect(retail.style?.decoration, TextDecoration.lineThrough);
    expect(retail.style?.color, const Color(0xFFB91C1C));
    expect(retail.style?.decorationColor, const Color(0xFFB91C1C));
  });

  testWidgets('unselected variants show a range, then the chosen price in a row', (
    tester,
  ) async {
    final controller = PdpProductController(rangedProduct());
    expect(controller.hasSelection, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PdpProductScope(
            controller: controller,
            child: Builder(
              builder: (context) {
                return buildPdpProductPriceBlock(
                  context,
                  WidgetNode(
                    type: 'pdp_product_price',
                    props: {
                      'product': rangedProduct(),
                      'price_range': true,
                      'price_order': 'secondary_first',
                      'price_style': 'current_only',
                    },
                  ),
                  AppDropBuildEnv(
                    r: R.fromConstraints(
                      context,
                      const BoxConstraints(maxWidth: 330, maxHeight: 700),
                    ),
                    renderNode: (_, __) => const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final retailRange = tester.getRect(find.text('₹140 - ₹200'));
    final sellingRange = tester.getRect(find.text('₹100 - ₹180'));
    expect(retailRange.bottom, lessThan(sellingRange.top + 1));

    controller.selectVariant(0);
    await tester.pump();

    expect(find.text('₹100 - ₹180'), findsNothing);
    final selling = tester.getRect(find.text('₹100'));
    final retail = tester.getRect(find.text('₹140'));
    expect(retail.center.dy, closeTo(selling.center.dy, 1));
    expect(retail.right, lessThan(selling.left + 1));
  });

  testWidgets('no range stays in a row even if an old column flag is set', (
    tester,
  ) async {
    await pump(tester, flatProduct(), {
      'price_range': true,
      'price_column': true,
      'price_order': 'secondary_first',
    });

    final retail = tester.getRect(find.text('₹140'));
    final selling = tester.getRect(find.text('₹100'));
    expect(retail.right, lessThan(selling.left + 1));
    expect(retail.center.dy, closeTo(selling.center.dy, 1));
    expect(find.textContaining(' - '), findsNothing);
  });
}
