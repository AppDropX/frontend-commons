import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/utils/toolbar_icons.dart';

void main() {
  test('isSvgNetworkUrl detects path and query SVG URLs', () {
    expect(isSvgNetworkUrl('https://cdn.example.com/icon.svg'), isTrue);
    expect(
      isSvgNetworkUrl('https://cdn.example.com/icon.svg?v=2'),
      isTrue,
    );
    expect(
      isSvgNetworkUrl('https://cdn.example.com/icon.SVG/'),
      isTrue,
    );
    expect(
      isSvgNetworkUrl('https://cdn.example.com/x?format=image/svg+xml'),
      isTrue,
    );
    expect(
      isSvgNetworkUrl('https://cdn.example.com/icon_w1200.webp'),
      isFalse,
    );
    expect(isSvgNetworkUrl('https://cdn.example.com/icon.png'), isFalse);
    expect(isSvgNetworkUrl(''), isFalse);
  });
}
