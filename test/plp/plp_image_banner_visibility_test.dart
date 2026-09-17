import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/plp/plp_image_banner_visibility.dart';

void main() {
  Map<String, dynamic> banner({
    String visibility = kImageBannerPlpVisibilityAll,
    List<String> collectionIds = const [],
  }) {
    return {
      'type': 'image_banner',
      'plpVisibility': visibility,
      'collectionIds': collectionIds,
    };
  }

  test('all visibility shows on every collection and all-products PLP', () {
    final block = banner();
    expect(imageBannerShowsForCollection(block, null), isTrue);
    expect(imageBannerShowsForCollection(block, 'all'), isTrue);
    expect(imageBannerShowsForCollection(block, 'summer-sale'), isTrue);
  });

  test('specific banner shows only on the targeted collection', () {
    final block = banner(
      visibility: kImageBannerPlpVisibilitySpecific,
      collectionIds: ['summer-sale'],
    );
    expect(imageBannerShowsForCollection(block, 'summer-sale'), isTrue);
    expect(imageBannerShowsForCollection(block, 'winter'), isFalse);
    expect(imageBannerShowsForCollection(block, 'all'), isFalse);
    expect(imageBannerShowsForCollection(block, null), isFalse);
  });

  test('specific banner with no collection ids stays hidden', () {
    final block = banner(
      visibility: kImageBannerPlpVisibilitySpecific,
    );
    expect(imageBannerShowsForCollection(block, 'summer-sale'), isFalse);
  });

  test('matches collection by slug or catalog id', () {
    final collections = [
      {'id': 'gid://shopify/Collection/1', 'title': 'Summer Sale'},
    ];
    final block = banner(
      visibility: kImageBannerPlpVisibilitySpecific,
      collectionIds: ['gid://shopify/Collection/1'],
    );
    expect(
      imageBannerShowsForCollection(
        block,
        'Summer Sale',
        collectionsRaw: collections,
      ),
      isTrue,
    );
    expect(
      imageBannerShowsForCollection(
        block,
        'summer-sale',
        collectionsRaw: collections,
      ),
      isTrue,
    );
  });

  test('filterPlpBlocksForCollection keeps non-banner blocks', () {
    final blocks = [
      {'type': 'sort_filter'},
      banner(
        visibility: kImageBannerPlpVisibilitySpecific,
        collectionIds: ['hats'],
      ),
      {'type': 'product_grid'},
    ];
    final visible = filterPlpBlocksForCollection(blocks, 'hats');
    expect(visible.map((e) => e['type']), [
      'sort_filter',
      'image_banner',
      'product_grid',
    ]);

    final hidden = filterPlpBlocksForCollection(blocks, 'shoes');
    expect(hidden.map((e) => e['type']), ['sort_filter', 'product_grid']);
  });
}
