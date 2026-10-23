import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/utils/carousel_slide_banners.dart';

void main() {
  test('root banners that repeat carousel slides are omitted', () {
    final widgets = [
      {
        'id': 'banner-keep',
        'block_type': 'IMAGE_BANNER',
        'config': {'url': 'https://cdn.example.com/hero.jpg'},
      },
      {
        'id': 'carousel-1',
        'block_type': 'CAROUSEL',
        'config': {
          'imageUrls': [
            'https://cdn.example.com/slide-a.jpg',
            'https://cdn.example.com/slide-b.jpg',
          ],
        },
      },
      {
        'id': 'leak-a',
        'block_type': 'IMAGE_BANNER',
        'config': {'url': 'https://cdn.example.com/slide-a.jpg'},
      },
      {
        'id': 'leak-b',
        'block_type': 'IMAGE_BANNER',
        'config': {'url': 'https://cdn.example.com/slide-b.jpg'},
      },
      {
        'id': 'banner-after',
        'block_type': 'IMAGE_BANNER',
        'config': {'url': 'https://cdn.example.com/other.jpg'},
      },
    ];

    final visible = rootsWithoutOrphanCarouselSlideBanners(
      roots: widgets,
      allWidgets: widgets,
    );

    expect(
      visible.map((widget) => widget['id']).toList(),
      ['banner-keep', 'carousel-1', 'banner-after'],
    );
  });

  test('a slide nested under the carousel is not treated as a page banner', () {
    final widgets = [
      {
        'id': 'carousel-1',
        'block_type': 'CAROUSEL',
        'config': {'imageUrls': <String>[]},
        'children': [
          {
            'id': 'slide-1',
            'block_type': 'IMAGE_BANNER',
            'config': {'url': 'https://cdn.example.com/slide-a.jpg'},
          },
        ],
      },
    ];

    final visible = rootsWithoutOrphanCarouselSlideBanners(
      roots: widgets,
      allWidgets: widgets,
    );

    expect(visible, hasLength(1));
    expect(visible.single['id'], 'carousel-1');
  });
}
