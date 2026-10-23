import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/plp/plp_layout_scope.dart';
import 'package:frontend_commons/plp/sort_filter_visibility.dart';
import 'package:frontend_commons/utils/product_block_theme_helpers.dart';
import 'package:frontend_commons/widgets/product_list_card.dart';
import 'package:flutter/material.dart';

void main() {
  test('view toggle stays on grid until the shopper picks list', () {
    final controller = PlpLayoutController();
    expect(controller.isList, isFalse);

    controller.setMode('list');
    expect(controller.mode, 'grid');

    controller.syncEnabled(true);
    expect(controller.isList, isFalse);

    controller.setMode('list');
    expect(controller.isList, isTrue);

    controller.setMode('grid');
    expect(controller.isList, isFalse);

    controller.syncEnabled(false);
    controller.setMode('list');
    expect(controller.isList, isFalse);
  });

  test('only two sort-filter toggles stay on', () {
    final withView = SortFilterVisibility.resolve(
      showTitle: true,
      showSortAndFilter: true,
      showViewToggle: true,
      turnedOn: 'view',
    );
    expect(withView.showTitle, isFalse);
    expect(withView.showSortAndFilter, isTrue);
    expect(withView.showViewToggle, isTrue);

    final withTitle = SortFilterVisibility.resolve(
      showTitle: true,
      showSortAndFilter: true,
      showViewToggle: true,
      turnedOn: 'title',
    );
    expect(withTitle.showTitle, isTrue);
    expect(withTitle.showViewToggle, isFalse);

    final twoOnly = SortFilterVisibility.resolve(
      showTitle: true,
      showSortAndFilter: false,
      showViewToggle: true,
      turnedOn: 'view',
    );
    expect(twoOnly.showTitle, isTrue);
    expect(twoOnly.showViewToggle, isTrue);
  });

  test('multi-variant products use Choose options on the list card', () {
    expect(
      productListCtaLabel(
        {
          'variants': [
            {'id': '1'},
            {'id': '2'},
          ],
        },
        'Add to Cart',
      ),
      'Choose options',
    );
    expect(
      productListCtaLabel(const {'title': 'Bag'}, 'Add to cart'),
      'Add to cart',
    );
  });

  test('sold out products use the product block button text and colors', () {
    final inStock = productSoldOutCta(
      const {},
      const {'title': 'Bag', 'available': true},
    );
    expect(inStock, isNull);

    final soldOut = productSoldOutCta(
      const {
        'config': {
          'sold_out_cta_text': 'Gone',
          'sold_out_button_bg': '#111111',
          'sold_out_button_color': '#EEEEEE',
        },
      },
      const {'title': 'Bag', 'available': false},
    );
    expect(soldOut?.label, 'Gone');
    expect(soldOut?.background, const Color(0xFF111111));
    expect(soldOut?.foreground, const Color(0xFFEEEEEE));
  });
}
