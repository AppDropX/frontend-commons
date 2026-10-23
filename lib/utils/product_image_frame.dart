/// Largest logical tile width before a product grid adds another column.
const double kProductGridMaxTileDp = 190;

/// Page inset used by the product grid. Matches the page content inset of 8.
const double kProductGridPageInsetDp = 8;

/// Width the product grid lays out in. A full-bleed PDP image is measured
/// against the screen, so subtract the page inset before sharing that width.
double productImageViewportWidth({
  required double maxWidth,
  required double screenWidth,
  double pageInset = kProductGridPageInsetDp,
}) {
  if (maxWidth <= 0) return 0;
  if (screenWidth > 0 && (maxWidth - screenWidth).abs() < 1) {
    final inner = screenWidth - pageInset * 2;
    if (inner > 0 && inner < maxWidth) return inner;
  }
  return maxWidth;
}

/// Width of one product-grid tile for a [viewportWidth] already in logical pixels.
double productGridImageWidth({
  required double viewportWidth,
  required double spacing,
  required double maxTileWidth,
}) {
  if (viewportWidth <= 0) return 0;
  if (maxTileWidth <= 0) return viewportWidth;
  final columns = (viewportWidth / maxTileWidth).floor().clamp(2, 3);
  final width = (viewportWidth - spacing * (columns - 1)) / columns;
  if (width <= 0 || width > viewportWidth) return viewportWidth;
  return width;
}
