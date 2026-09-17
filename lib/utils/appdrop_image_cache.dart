import 'package:flutter/painting.dart';

/// Gives storefront images enough room to stay warm during normal navigation.
///
/// Flutter's default decoded-image cache is intentionally conservative. AppDrop
/// pages often combine product grids, banners, sliders, and toolbar logos; when
/// large remote images are decoded, the default cache can evict recently seen
/// slides before the user returns to the page. This helper only raises the
/// budget when the current values are lower, so platform/test overrides can
/// still choose a larger cache.
void configureAppDropImageCache({
  int maximumSize = 700,
  int maximumSizeBytes = 180 * 1024 * 1024,
}) {
  final cache = PaintingBinding.instance.imageCache;
  if (cache.maximumSize < maximumSize) {
    cache.maximumSize = maximumSize;
  }
  if (cache.maximumSizeBytes < maximumSizeBytes) {
    cache.maximumSizeBytes = maximumSizeBytes;
  }
}
