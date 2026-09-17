import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/theme_library.dart';
import 'package:frontend_commons/utils/media_block_padding.dart';

void main() {
  test('custom_block supports the same padding toggles as image banners', () {
    final node = WidgetNode(
      type: 'custom_block',
      props: {
        'horizontalPadding': false,
        'verticalPadding': true,
      },
    );

    expect(isMediaPaddingToggleBlock(node), isTrue);
    expect(mediaBlockHorizontalPaddingEnabled(node), isFalse);
    expect(mediaBlockVerticalPaddingEnabled(node), isTrue);
  });

  test('custom_block padding defaults on when flags are omitted', () {
    final node = WidgetNode(type: 'custom_block');

    expect(mediaBlockHorizontalPaddingEnabled(node), isTrue);
    expect(mediaBlockVerticalPaddingEnabled(node), isTrue);
  });
}
