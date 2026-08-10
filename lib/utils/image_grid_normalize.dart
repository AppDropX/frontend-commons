/// Normalizes image_grid block props from API / persisted JSON (camelCase + snake_case).
void normalizeImageGridProps(Map<String, dynamic> props) {
  void preferCamel(String snake, String camel) {
    final snakeVal = props[snake];
    final camelVal = props[camel];
    if (camelVal == null && snakeVal != null) {
      props[camel] = snakeVal;
    }
    props.remove(snake);
  }

  preferCamel('layout_mode', 'layoutMode');
  preferCamel('image_names', 'imageNames');
  preferCamel('show_image_names', 'showImageNames');
  preferCamel('image_name_font_variation', 'imageNameFontVariation');
  preferCamel('image_name_color', 'imageNameColor');
  preferCamel('max_tile_width_dp', 'maxTileWidthDp');
  preferCamel('spacing_dp', 'spacingDp');
  preferCamel('radius_dp', 'radiusDp');
  preferCamel('tile_aspect_ratio', 'tileAspectRatio');
  preferCamel('image_bg_color', 'imageBgColor');
  preferCamel('image_redirects', 'imageRedirects');

  final images = props['images'];
  if (images is! List) return;

  final rawNames = props['imageNames'];
  final names = rawNames is List ? List<dynamic>.from(rawNames) : <dynamic>[];
  while (names.length < images.length) {
    names.add('');
  }
  while (names.length > images.length) {
    names.removeLast();
  }
  props['imageNames'] = names;
}

/// Applies [normalizeImageGridProps] when [type] is `image_grid`.
Map<String, dynamic> normalizeImageGridBlockMap(Map<String, dynamic> block) {
  final type = (block['type'] ?? '').toString().toLowerCase();
  if (type == 'image_grid') {
    normalizeImageGridProps(block);
  }
  return block;
}
