/// Normalizes carousel block props from API / persisted JSON (camelCase + snake_case).
void normalizeCarouselProps(Map<String, dynamic> props) {
  void preferCamel(String snake, String camel) {
    final snakeVal = props[snake];
    final camelVal = props[camel];
    if (camelVal == null && snakeVal != null) {
      props[camel] = snakeVal;
    }
    props.remove(snake);
  }

  preferCamel('infinite_scroll', 'infiniteScroll');
  preferCamel('centered_peek', 'centeredPeek');
  preferCamel('peek_overlay_layout', 'peekOverlayLayout');
  preferCamel('show_slide_titles', 'showSlideTitles');
  preferCamel('slide_title_font_variation', 'slideTitleFontVariation');
  preferCamel('slide_title_font_size_dp', 'slideTitleFontSizeDp');
  preferCamel('slide_title_color', 'slideTitleColor');
  preferCamel('slide_titles', 'slideTitles');
  preferCamel('image_titles', 'imageTitles');
  preferCamel('image_urls', 'imageUrls');
  preferCamel('image_redirects', 'imageRedirects');
  preferCamel('item_width_factor', 'itemWidthFactor');
  preferCamel('spacing_dp', 'spacingDp');
  preferCamel('radius_dp', 'radiusDp');
  preferCamel('height_dp', 'heightDp');

  // Legacy peek toggle from earlier builder builds.
  if (props['centeredPeek'] == null && props['peekOverlayLayout'] != null) {
    props['centeredPeek'] = props['peekOverlayLayout'];
  }

  final imageTitles = props['imageTitles'];
  final slideTitles = props['slideTitles'];
  if ((imageTitles is! List || imageTitles.isEmpty) &&
      slideTitles is List &&
      slideTitles.isNotEmpty) {
    props['imageTitles'] = slideTitles;
  }
}

/// Applies [normalizeCarouselProps] when [type] is `carousel`.
Map<String, dynamic> normalizeCarouselBlockMap(Map<String, dynamic> block) {
  final type = (block['type'] ?? '').toString().toLowerCase();
  if (type == 'carousel') {
    normalizeCarouselProps(block);
  }
  return block;
}
