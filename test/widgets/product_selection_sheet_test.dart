import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/cart/add_to_cart_sheet_config.dart';
import 'package:frontend_commons/theme/appdrop_theme_config.dart';
import 'package:frontend_commons/theme/appdrop_theme_scope.dart';
import 'package:frontend_commons/widgets/product_selection_bottom_sheet.dart';

void main() {
  test('sheet config round-trips inside product block config', () {
    const raw = {
      'config': {
        'add_to_cart_sheet': {
          'presentation': 'popup',
          'show_quantity': false,
          'max_quantity': 4,
          'variant': {'variantStyle': 'buttons', 'groupTitle': 'Size'},
        },
      },
    };

    final sheet = AddToCartSheetConfig.fromProductBlock(raw);
    expect(sheet.isPopup, isTrue);
    expect(sheet.showQuantity, isFalse);
    expect(sheet.maxQuantity, 4);
    expect(sheet.variantDropdown, isFalse);
    expect(sheet.variantString('groupTitle', ''), 'Size');
    expect(sheet.variantString('dropdownHint', ''), 'Choose a Size');

    final again = AddToCartSheetConfig.fromJson(sheet.toJson());
    expect(again.toJson(), sheet.toJson());
  });

  test('missing sheet config uses the reference defaults', () {
    final sheet = AddToCartSheetConfig.fromProductBlock(const {});
    expect(sheet.presentation, 'bottom_sheet');
    expect(sheet.showQuantity, isTrue);
    expect(sheet.variantDropdown, isTrue);
    expect(sheet.cornerRadius, 16);
    expect(sheet.titleSize, 20);
    expect(sheet.titleFontVariation, 'semi_bold');
    expect(sheet.titleColor, isEmpty);
  });

  testWidgets('a price range stacks and one price stays in a row', (
    tester,
  ) async {
    Future<void> pump(Map<String, dynamic> product) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductSelectionSheet(
              product: product,
              productId: 'p',
              config: AddToCartSheetConfig.defaults(),
              preview: true,
            ),
          ),
        ),
      );
    }

    await pump(addToCartSheetPreviewProduct());
    await tester.pumpAndSettle();
    expect(find.textContaining(' - '), findsWidgets);

    await pump({
      'id': 'p',
      'title': 'Plain Belt',
      'sellingPrice': 1399,
      'retailPrice': 2000,
      'variants': [
        {
          'id': 'only',
          'title': '32',
          'price': 1399,
          'compare_at_price': 2000,
          'inventory_quantity': 4,
        },
      ],
    });
    await tester.pumpAndSettle();
    expect(find.textContaining(' - '), findsNothing);
    expect(find.textContaining('1399'), findsOneWidget);
    expect(find.textContaining('2000'), findsOneWidget);
  });

  testWidgets('popup closes after add and the preview button does not', (
    tester,
  ) async {
    var added = 0;
    var opened = 0;
    final product = addToCartSheetPreviewProduct();
    final theme = AppDropThemeConfig.fromJson({
      'product_block': {
        'upper_case_title': false,
        'config': {
          'add_to_cart_sheet': {'presentation': 'popup'},
        },
      },
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppDropThemeScope(
          config: theme,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    showProductSelectionBottomSheet(
                      context: context,
                      product: product,
                      productId: product['productId'].toString(),
                      onViewDetails: () => opened++,
                      onAddToCart: (_, __) => added++,
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close'), findsOneWidget);
    expect(find.text('Bison Dark Brown Leather Belt'), findsOneWidget);
    expect(find.text('Choose a Size'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('View Details'), findsNothing);

    await tester.tap(find.text('Bison Dark Brown Leather Belt'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(find.byTooltip('Close'), findsNothing);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();

    expect(added, 1);
    expect(find.byTooltip('Close'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductSelectionSheet(
            product: product,
            productId: product['productId'].toString(),
            config: AddToCartSheetConfig.fromJson(const {
              'presentation': 'popup',
            }),
            preview: true,
            onAddToCart: (_, __) => added++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    expect(added, 1);
    expect(find.byTooltip('Close'), findsOneWidget);
  });
}
