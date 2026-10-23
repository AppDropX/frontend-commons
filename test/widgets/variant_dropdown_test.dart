import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/src/responsive.dart';
import 'package:frontend_commons/src/widget_node.dart';
import 'package:frontend_commons/widgets/product_variant.dart';

void main() {
  Map<String, dynamic> product() => {
        'options': [
          {'name': 'Size'},
        ],
        'variants': [
          {
            'id': 'inch16',
            'title': '16 Inch',
            'price': 100,
            'inventory_quantity': 4,
          },
          {
            'id': 'inch18',
            'title': '18 Inch',
            'price': 120,
            'inventory_quantity': 0,
          },
        ],
      };

  Future<void> pump(WidgetTester tester, Map<String, dynamic> props) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return buildProductVariant(
                context,
                WidgetNode(
                  type: 'product_variant',
                  props: {'product': product(), ...props},
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

  testWidgets('dropdown starts with the hint and keeps sold out disabled', (
    tester,
  ) async {
    await pump(tester, {
      'variantStyle': 'dropdown',
      'dropdownHint': 'Choose a Size',
      'dropdownUnavailableText': 'Unavailable',
    });

    expect(find.text('Choose a Size'), findsOneWidget);
    expect(find.text('Size'), findsNothing);

    await tester.tap(find.byType(DropdownButton2<int>));
    await tester.pumpAndSettle();

    expect(find.text('Unavailable'), findsOneWidget);
    final soldOut = tester.widget<Text>(find.text('18 Inch'));
    expect(soldOut.style?.color, const Color(0xFF9CA3AF));

    await tester.tap(find.text('Unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a Size'), findsOneWidget);

    await tester.tap(find.text('16 Inch'));
    await tester.pumpAndSettle();

    expect(find.text('Size'), findsNothing);
    expect(find.text('16 Inch'), findsOneWidget);
    expect(find.text('Choose a Size'), findsNothing);
  });

  testWidgets('buttons stay the default when dropdown is off', (tester) async {
    await pump(tester, {'variantStyle': 'buttons'});

    expect(find.text('Size'), findsOneWidget);
    expect(find.text('16 Inch'), findsOneWidget);
    expect(find.byType(DropdownButton2<int>), findsNothing);
  });
}
