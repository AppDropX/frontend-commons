/// Fallback if a resize payload cannot be parsed.
const double kEmbeddedCustomBlockHeight = 300;

/// Smallest slot we keep so an empty block does not collapse the WebView.
const double kEmbeddedCustomBlockMinHeight = 8;

/// Extra pixels added to the reported HTML height so the last row is not
/// clipped and the iframe/WebView does not show an inner scrollbar.
const double kEmbeddedCustomBlockHeightSlack = 2;

/// Measuring viewport + max embedded slot (phone preview logical height).
///
/// The iframe/WebView starts at this height so HTML can layout at its natural
/// size; after the document reports `type: resize`, Flutter snaps the slot to
/// that content height (strip → short, table → tall).
const double kEmbeddedCustomBlockMaxHeight = 690;

double clampEmbeddedCustomBlockHeight(num height) {
  final value = height.toDouble();
  if (value.isNaN || value.isInfinite) return kEmbeddedCustomBlockHeight;
  return value.clamp(
    kEmbeddedCustomBlockMinHeight,
    kEmbeddedCustomBlockMaxHeight,
  );
}
