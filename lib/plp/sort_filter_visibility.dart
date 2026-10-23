/// Some glyphs sit inside a smaller ink box than others at the same font size.
double sortFilterIconScale(String glyph) {
  switch (glyph.trim()) {
    case 'filter':
      return 1.12;
    case 'list':
    case 'grid_view':
    case 'grid':
      return 1;
    case 'chevron_down':
      return 0.92;
    default:
      return 1;
  }
}

/// Which of the three Sort & Filter switches are visible.
///
/// Title, sort/filter, and grid/list are separate switches, and at most two
/// of them can be on together.
class SortFilterVisibility {
  const SortFilterVisibility({
    required this.showTitle,
    required this.showSortAndFilter,
    required this.showViewToggle,
  });

  final bool showTitle;
  final bool showSortAndFilter;
  final bool showViewToggle;

  /// [turnedOn] is `title`, `actions`, or `view` when that switch was just
  /// enabled. Saved data with all three on hides the title.
  factory SortFilterVisibility.resolve({
    required bool showTitle,
    required bool showSortAndFilter,
    required bool showViewToggle,
    String? turnedOn,
  }) {
    var title = showTitle;
    var actions = showSortAndFilter;
    var view = showViewToggle;
    if (title && actions && view) {
      if (turnedOn == 'title') {
        view = false;
      } else {
        title = false;
      }
    }
    return SortFilterVisibility(
      showTitle: title,
      showSortAndFilter: actions,
      showViewToggle: view,
    );
  }
}
