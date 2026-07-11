import 'package:flutter/material.dart';

import '../pdp/pdp_product_scope.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/network_image_url.dart';
import 'fullscreen_image_viewer.dart';
import 'product_image_placeholder.dart';

Widget buildPdpProductImageBlock(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  if (!node.b('enabled', def: true)) return const SizedBox.shrink();
  final product = _effectiveProduct(context, node);
  final imageUrl = sanitizedNetworkImageUrl((product['imageUrl'] ?? '').toString());
  final images = _productImages(product, imageUrl);

  final aspect = _aspectFromIndex(node.i('aspect_ratio_index', def: 0));
  final indicatorColor = parseHexColor(
        node.s('indicator_color', def: '#FFFFFF'),
      ) ??
      Colors.white;
  final imageRadius = BorderRadius.circular(env.r.dp(12));
  final imageBg = const Color(0xFFE0E0E0);
  final productId =
      (product['productId'] ?? product['id'])?.toString().trim() ?? '';
  final heroTag = () {
    final fromNode = node.s('heroTag', def: '').trim();
    if (fromNode.isNotEmpty) return fromNode;
    return (product['heroTag']?.toString() ?? '').trim();
  }();

  Widget image = images.isEmpty
      ? AspectRatio(
          aspectRatio: aspect,
          child: ProductImagePlaceholder(backgroundColor: imageBg),
        )
      : Stack(
          children: [
            AspectRatio(
              aspectRatio: aspect,
              child: _ImagePager(
                images: images,
                indicatorColor: indicatorColor,
                interactiveEnabled: env.interactiveFeaturesEnabled,
                aspectRatio: aspect,
                imageBg: imageBg,
                imageRadius: imageRadius,
                productId: productId,
                heroTag: heroTag,
              ),
            ),
          ],
        );

  image = ClipRRect(
    borderRadius: BorderRadius.circular(env.r.dp(12)),
    child: image,
  );
  return image;
}

Map<String, dynamic> _effectiveProduct(BuildContext context, WidgetNode node) {
  final fromScope = PdpProductScope.maybeOf(context)?.effectiveProduct;
  if (fromScope != null) return Map<String, dynamic>.from(fromScope);
  final fromNode = node.m('product');
  if (fromNode == null) return <String, dynamic>{};
  return Map<String, dynamic>.from(fromNode);
}

List<String> _productImages(Map<String, dynamic> product, String? fallbackUrl) {
  final images = <String>[];
  final raw = product['images'];
  if (raw is List) {
    for (final item in raw) {
      final candidate = sanitizedNetworkImageUrl(item?.toString() ?? '');
      if (candidate != null && candidate.isNotEmpty) images.add(candidate);
    }
  }
  final fallback = sanitizedNetworkImageUrl(fallbackUrl ?? '');
  if (fallback != null && fallback.isNotEmpty && !images.contains(fallback)) {
    images.insert(0, fallback);
  }
  return images;
}

double _aspectFromIndex(int idx) {
  switch (idx) {
    case 2:
      return 4 / 5;
    case 3:
      return 16 / 9;
    case 0:
    case 1:
    default:
      return 1.0;
  }
}

class _ImagePager extends StatefulWidget {
  const _ImagePager({
    required this.images,
    required this.indicatorColor,
    required this.aspectRatio,
    required this.imageBg,
    required this.imageRadius,
    required this.productId,
    required this.heroTag,
    this.interactiveEnabled = true,
  });

  final List<String> images;
  final Color indicatorColor;
  final double aspectRatio;
  final Color imageBg;
  final BorderRadius imageRadius;
  final String productId;
  final String heroTag;
  final bool interactiveEnabled;

  @override
  State<_ImagePager> createState() => _ImagePagerState();
}

class _ImagePagerState extends State<_ImagePager> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) {
            final Widget image;
            if (i == 0 &&
                widget.productId.isNotEmpty &&
                widget.heroTag.isNotEmpty) {
              image = buildProductHeroImage(
                productId: widget.productId,
                imageUrl: widget.images[i],
                aspectRatio: widget.aspectRatio,
                boxFit: BoxFit.cover,
                imageBg: widget.imageBg,
                borderRadius: widget.imageRadius,
                heroTag: widget.heroTag,
              );
            } else {
              image = Image.network(
                widget.images[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    ProductImagePlaceholder(backgroundColor: widget.imageBg),
              );
            }
            if (!widget.interactiveEnabled) return image;
            return GestureDetector(
              onTap: () => openFullscreenImageViewer(
                context,
                images: widget.images,
                initialIndex: i,
              ),
              behavior: HitTestBehavior.opaque,
              child: image,
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              return Container(
                width: i == _index ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _index
                      ? widget.indicatorColor
                      : widget.indicatorColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
