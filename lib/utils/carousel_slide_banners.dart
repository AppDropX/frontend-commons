/// Drops root image banners that repeat a photo already used as a carousel slide.
///
/// [allWidgets] is the flat or nested API list, used to discover slide URLs.
/// [roots] is the page-level list that will be rendered. Nested slide rows stay
/// on the carousel; a second copy sitting on the page is removed.
List<Map<String, dynamic>> rootsWithoutOrphanCarouselSlideBanners({
  required List<Map<String, dynamic>> roots,
  required List<Map<String, dynamic>> allWidgets,
}) {
  final slideUrls = <String>{};
  final carouselIds = <String>{};

  void addUrl(Object? raw) {
    final url = raw?.toString().trim() ?? '';
    if (url.isNotEmpty) slideUrls.add(url);
  }

  String typeOf(Map<String, dynamic> widget) =>
      (widget['block_type'] ?? widget['type'] ?? '').toString().toLowerCase();

  Map<String, dynamic> configOf(Map<String, dynamic> widget) {
    final config = widget['config'];
    if (config is Map) return Map<String, dynamic>.from(config);
    return widget;
  }

  void collect(Map<String, dynamic> widget, {bool underCarousel = false}) {
    final type = typeOf(widget);
    if (type == 'carousel') {
      final id = widget['id']?.toString().trim() ?? '';
      if (id.isNotEmpty) carouselIds.add(id);
      final source = configOf(widget);
      final raw = source['imageUrls'] ?? source['image_urls'];
      if (raw is List) {
        for (final entry in raw) {
          addUrl(entry);
        }
      }
    } else if (underCarousel && type == 'image_banner') {
      addUrl(configOf(widget)['url']);
    }
    final nestUnderCarousel = underCarousel || type == 'carousel';
    for (final key in ['children', 'child_widgets']) {
      final nested = widget[key];
      if (nested is! List) continue;
      for (final child in nested) {
        if (child is Map) {
          collect(
            Map<String, dynamic>.from(child),
            underCarousel: nestUnderCarousel,
          );
        }
      }
    }
  }

  for (final widget in allWidgets) {
    collect(widget);
  }
  for (final widget in allWidgets) {
    if (typeOf(widget) != 'image_banner') continue;
    final parent = (widget['parent_id'] ??
            widget['parent_widget_id'] ??
            widget['parentId'])
        ?.toString()
        .trim();
    if (parent == null || parent.isEmpty || !carouselIds.contains(parent)) {
      continue;
    }
    addUrl(configOf(widget)['url']);
  }
  if (slideUrls.isEmpty) return roots;

  return [
    for (final widget in roots)
      if (!(typeOf(widget) == 'image_banner' &&
          slideUrls.contains(configOf(widget)['url']?.toString().trim())))
        widget,
  ];
}
