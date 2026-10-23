import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/utils/product_image_frame.dart';
import 'package:frontend_commons/utils/shopify_image_url.dart';

void main() {
  test('full-bleed PDP uses the same tile width as the inset product grid', () {
    const screen = 330.0;
    const inset = kProductGridPageInsetDp;
    const spacing = 10.0;
    const maxTile = 190.0;
    final gridViewport = screen - inset * 2;
    final pdpViewport = productImageViewportWidth(
      maxWidth: screen,
      screenWidth: screen,
    );
    expect(pdpViewport, gridViewport);
    expect(
      productGridImageWidth(
        viewportWidth: pdpViewport,
        spacing: spacing,
        maxTileWidth: maxTile,
      ),
      productGridImageWidth(
        viewportWidth: gridViewport,
        spacing: spacing,
        maxTileWidth: maxTile,
      ),
    );
  });

  test('an already inset PDP keeps its measured width', () {
    expect(
      productImageViewportWidth(maxWidth: 314, screenWidth: 330),
      314,
    );
  });

  test('HD url drops only the Shopify width transform', () {
    const original =
        'https://cdn.shopify.com/s/files/1/a.jpg?v=1&width=300';
    expect(
      hdProductImageUrl(original),
      'https://cdn.shopify.com/s/files/1/a.jpg?v=1',
    );
    const other = 'https://cdn.example.com/a.jpg?width=300';
    expect(hdProductImageUrl(other), other);
  });
}
