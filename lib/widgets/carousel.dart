import 'package:flutter/widgets.dart';
import '../theme_library.dart';

List<String>? _carouselImageUrlsFromProps(WidgetNode node) {
  final raw = node.props['imageUrls'] ?? node.props['image_urls'];
  if (raw is! List) return null;
  return [
    for (final e in raw) e?.toString() ?? '',
  ];
}

Map<String, dynamic> _syntheticSlideJson(String url, int i, List<dynamic>? imageRedirects) {
  final json = <String, dynamic>{
    'type': 'image_banner',
    'url': url,
    'aspectRatio': 16 / 9,
    'radiusDp': 16.0,
    'bgColor': '#E5E7EB',
    'enabled': true,
  };
  if (imageRedirects != null &&
      i < imageRedirects.length &&
      imageRedirects[i] is Map) {
    json['redirect'] = Map<String, dynamic>.from(imageRedirects[i] as Map);
  }
  return json;
}

Widget buildCarousel(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final itemWidthFactor = node.d('itemWidthFactor', def: 0.82).clamp(0.2, 1.0);
  final spacingDp = node.d('spacingDp', def: 12);
  final paddingDp = node.d('paddingDp', def: 0);
  final heightDp = node.d('heightDp', def: 0);

  final urlList = _carouselImageUrlsFromProps(node);
  final slideRedirects = imageRedirectsListFromNode(node);
  if (node.children.isEmpty && urlList != null && urlList.isNotEmpty) {
    final h = heightDp > 0 ? env.r.dp(heightDp) : env.r.w * 0.55;
    return SizedBox(
      height: h,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: env.r.dp(paddingDp)),
        itemCount: urlList.length,
        separatorBuilder: (_, __) => SizedBox(width: env.r.dp(spacingDp)),
        itemBuilder: (ctx, i) {
          return SizedBox(
            width: env.r.w * itemWidthFactor,
            child: env.renderNode(
              ctx,
              WidgetNode.fromJson(_syntheticSlideJson(urlList[i], i, slideRedirects)),
            ) as Widget,
          );
        },
      ),
    );
  }

  if (node.children.isEmpty) return const SizedBox.shrink();

  // Always bounded height (fix for RenderBox not laid out)
  final h = heightDp > 0 ? env.r.dp(heightDp) : env.r.w * 0.55;

  return SizedBox(
    height: h,
    child: ListView.separated(
      clipBehavior: Clip.none,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: env.r.dp(paddingDp)),
      itemCount: node.children.length,
      separatorBuilder: (_, __) => SizedBox(width: env.r.dp(spacingDp)),
      itemBuilder: (ctx, i) {
        return SizedBox(
          width: env.r.w * itemWidthFactor,
          child: env.renderNode(ctx, node.children[i]) as Widget,
        );
      },
    ),
  );
}
