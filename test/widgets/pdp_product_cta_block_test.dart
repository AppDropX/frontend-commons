import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/pdp/pdp_page_enrichment.dart';
import 'package:frontend_commons/src/responsive.dart';
import 'package:frontend_commons/src/widget_node.dart';
import 'package:frontend_commons/widgets/pdp_product_cta_block.dart';

void main() {
  test('column layout keeps the CTA inline', () {
    expect(
      pdpCtaResolvedScrollStyle({
        'show_buy_now': true,
        'button_layout': 'column',
        'scroll_style': 'fixed_bottom',
      }),
      'inline',
    );
    expect(
      pdpCtaResolvedScrollStyle({
        'show_buy_now': true,
        'button_layout': 'row',
        'scroll_style': 'fixed_bottom',
      }),
      'fixed_at_bottom',
    );
    expect(
      pdpCtaResolvedScrollStyle({'scroll_style': 'inline'}),
      'inline',
    );
  });

  testWidgets('buy now sits in a row or a column', (tester) async {
    Future<void> pump(String layout) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: Builder(
                  builder: (context) {
                    return buildPdpProductCtaBlock(
                      context,
                      WidgetNode(
                        type: 'pdp_product_cta',
                        props: {
                          'show_buy_now': true,
                          'button_layout': layout,
                          'button_title': 'Add to Cart',
                          'buy_now_title': 'Buy Now',
                          'action': {'type': 'add_to_cart'},
                        },
                      ),
                      AppDropBuildEnv(
                        r: R.fromConstraints(
                          context,
                          const BoxConstraints(maxWidth: 320, maxHeight: 700),
                        ),
                        renderNode: (_, __) => const SizedBox.shrink(),
                        interactiveFeaturesEnabled: false,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pump('row');
    final rowCart = tester.getRect(find.text('Add to Cart'));
    final rowBuy = tester.getRect(find.text('Buy Now'));
    expect(rowBuy.left, greaterThan(rowCart.right - 1));
    expect(rowBuy.center.dy, closeTo(rowCart.center.dy, 1));

    BoxDecoration paintOf(String label) {
      final ink = tester.widget<Ink>(
        find.ancestor(of: find.text(label), matching: find.byType(Ink)).first,
      );
      return ink.decoration! as BoxDecoration;
    }

    expect(paintOf('Add to Cart').color, isNot(Colors.transparent));
    expect(paintOf('Buy Now').color, Colors.transparent);

    await pump('column');
    final columnCart = tester.getRect(find.text('Add to Cart'));
    final columnBuy = tester.getRect(find.text('Buy Now'));
    expect(columnBuy.top, greaterThan(columnCart.bottom - 1));
    expect(columnBuy.center.dx, closeTo(columnCart.center.dx, 1));
  });
}
