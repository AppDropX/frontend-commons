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
  final imageUrl = sanitizedNetworkImageUrl(bestApiProductImageUrl(product));
  final images = _productImages(product, imageUrl);

  final aspect = _aspectFromIndex(node.i('aspect_ratio_index', def: 0));
  final radiusDp = node.d('radiusDp', def: 12);
  final indicatorColor = parseHexColor(
        node.s('indicator_color', def: '#FFFFFF'),
      ) ??
      Colors.white;
  final thumbnailBorderColor = parseHexColor(
        node.s('thumbnail_border_color', def: '#111827'),
      ) ??
      const Color(0xFF111827);
  final galleryStyle = _galleryStyle(node.s('gallery_style', def: 'indicator'));
  final gallerySize = _thumbnailSizeName(node.s('gallery_size', def: 'square'));
  final removeThumbnailSpacing = node.b('remove_thumbnail_spacing', def: false);
  final imageFit = _imageFit(node.s('image_position', def: 'crop'));
  final heroImageUrl = sanitizedNetworkImageUrl(
    productThumbnailUrl(product, width: kPdpProductImageWidth),
  );
  final imageRadius = BorderRadius.circular(env.r.dp(radiusDp));
  final imageBg = const Color(0xFFE0E0E0);
  final productId =
      (product['productId'] ?? product['id'])?.toString().trim() ?? '';
  final heroTag = () {
    final fromNode = node.s('heroTag', def: '').trim();
    if (fromNode.isNotEmpty) return fromNode;
    return (product['heroTag']?.toString() ?? '').trim();
  }();

  final gallery = _PdpImageGallery(
    images: images,
    aspectRatio: aspect,
    imageFit: imageFit,
    heroImageUrl: heroImageUrl,
    imageRadius: imageRadius,
    radiusDp: env.r.dp(radiusDp),
    imageBg: imageBg,
    productId: productId,
    heroTag: heroTag,
    indicatorColor: indicatorColor,
    thumbnailBorderColor: thumbnailBorderColor,
    showThumbnails: galleryStyle == 'thumbnails',
    gallerySize: gallerySize,
    removeThumbnailSpacing: removeThumbnailSpacing,
    interactiveEnabled: env.interactiveFeaturesEnabled,
  );
  return gallery;
}

Map<String, dynamic> _effectiveProduct(BuildContext context, WidgetNode node) {
  final fromScope = PdpProductScope.maybeOf(context)?.effectiveProduct;
  if (fromScope != null) return Map<String, dynamic>.from(fromScope);
  final fromNode = node.m('product');
  if (fromNode == null) return <String, dynamic>{};
  return Map<String, dynamic>.from(fromNode);
}

List<String> _productImages(Map<String, dynamic> product, String? fallbackUrl) {
  final images = apiProductImageUrls(product);
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

BoxFit _imageFit(String raw) {
  final value = raw.trim().toLowerCase();
  if (value == 'fit' || value == 'contain') return BoxFit.contain;
  return BoxFit.cover;
}

String _displayImageUrl(String original) =>
    shopifyResizedImageUrl(original, width: kPdpProductImageWidth) ?? original;

String _galleryStyle(String raw) {
  final value = raw.trim().toLowerCase();
  if (value == 'thumbnails' || value == 'thumbnail') return 'thumbnails';
  return 'indicator';
}

String _thumbnailSizeName(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'portrait':
    case 'potrait':
      return 'portrait';
    case 'square':
    default:
      return 'square';
  }
}

const double _kThumbnailSpacing = 8;

double _thumbnailGap(bool removeSpacing) => removeSpacing ? 0 : _kThumbnailSpacing;

class _ThumbSize {
  const _ThumbSize(this.width, this.height);

  final double width;
  final double height;
}

_ThumbSize _thumbnailSize(String gallerySize) {
  switch (gallerySize) {
    case 'portrait':
      return const _ThumbSize(68, 92);
    case 'square':
    default:
      return const _ThumbSize(84, 84);
  }
}

class _PdpImageGallery extends StatefulWidget {
  const _PdpImageGallery({
    required this.images,
    required this.aspectRatio,
    required this.imageFit,
    required this.heroImageUrl,
    required this.imageRadius,
    required this.radiusDp,
    required this.imageBg,
    required this.productId,
    required this.heroTag,
    required this.indicatorColor,
    required this.thumbnailBorderColor,
    required this.showThumbnails,
    required this.gallerySize,
    required this.removeThumbnailSpacing,
    required this.interactiveEnabled,
  });

  final List<String> images;
  final double aspectRatio;
  final BoxFit imageFit;
  final String? heroImageUrl;
  final BorderRadius imageRadius;
  final double radiusDp;
  final Color imageBg;
  final String productId;
  final String heroTag;
  final Color indicatorColor;
  final Color thumbnailBorderColor;
  final bool showThumbnails;
  final String gallerySize;
  final bool removeThumbnailSpacing;
  final bool interactiveEnabled;

  @override
  State<_PdpImageGallery> createState() => _PdpImageGalleryState();
}

class _PdpImageGalleryState extends State<_PdpImageGallery> {
  late final PageController _pageController;
  late final ScrollController _thumbController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _thumbController = ScrollController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
    _revealThumb(index);
  }

  void _revealThumb(int index) {
    if (!widget.showThumbnails) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_thumbController.hasClients) return;
      final metrics = _thumbnailSize(widget.gallerySize);
      final itemExtent = metrics.width + _thumbnailGap(widget.removeThumbnailSpacing);
      final viewport = _thumbController.position.viewportDimension;
      final target = (index * itemExtent) - ((viewport - metrics.width) / 2);
      final max = _thumbController.position.maxScrollExtent;
      _thumbController.animateTo(
        target.clamp(0, max),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images.isEmpty
        ? AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: ProductImagePlaceholder(backgroundColor: widget.imageBg),
          )
        : AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: _ImagePager(
              controller: _pageController,
              images: widget.images,
              index: _index,
              onPageChanged: (i) {
                setState(() => _index = i);
                _revealThumb(i);
              },
              indicatorColor: widget.indicatorColor,
              showIndicator: !widget.showThumbnails && widget.images.length > 1,
              interactiveEnabled: widget.interactiveEnabled,
              aspectRatio: widget.aspectRatio,
              imageFit: widget.imageFit,
              heroImageUrl: widget.heroImageUrl,
              imageBg: widget.imageBg,
              imageRadius: widget.imageRadius,
              productId: widget.productId,
              heroTag: widget.heroTag,
            ),
          );

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radiusDp),
      child: image,
    );

    if (!widget.showThumbnails || widget.images.isEmpty) return clipped;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clipped,
        SizedBox(height: _thumbnailGap(widget.removeThumbnailSpacing)),
        _ThumbnailStrip(
          controller: _thumbController,
          images: widget.images,
          selectedIndex: _index,
          imageBg: widget.imageBg,
          borderColor: widget.thumbnailBorderColor,
          size: _thumbnailSize(widget.gallerySize),
          gap: _thumbnailGap(widget.removeThumbnailSpacing),
          onSelected: _goTo,
        ),
      ],
    );
  }
}

class _ImagePager extends StatelessWidget {
  const _ImagePager({
    required this.controller,
    required this.images,
    required this.index,
    required this.onPageChanged,
    required this.indicatorColor,
    required this.showIndicator,
    required this.aspectRatio,
    required this.imageFit,
    required this.heroImageUrl,
    required this.imageBg,
    required this.imageRadius,
    required this.productId,
    required this.heroTag,
    required this.interactiveEnabled,
  });

  final PageController controller;
  final List<String> images;
  final int index;
  final ValueChanged<int> onPageChanged;
  final Color indicatorColor;
  final bool showIndicator;
  final double aspectRatio;
  final BoxFit imageFit;
  final String? heroImageUrl;
  final Color imageBg;
  final BorderRadius imageRadius;
  final String productId;
  final String heroTag;
  final bool interactiveEnabled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: controller,
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (_, i) {
            final Widget image;
            final displayUrl = i == 0 && heroImageUrl != null
                ? heroImageUrl!
                : _displayImageUrl(images[i]);
            if (i == 0 && productId.isNotEmpty && heroTag.isNotEmpty) {
              image = buildProductHeroImage(
                productId: productId,
                imageUrl: displayUrl,
                aspectRatio: aspectRatio,
                boxFit: imageFit,
                imageBg: imageBg,
                borderRadius: imageRadius,
                heroTag: heroTag,
              );
            } else {
              image = AppDropNetworkImage(
                url: displayUrl,
                fit: imageFit,
                errorBuilder: (_, __, ___) =>
                    ProductImagePlaceholder(backgroundColor: imageBg),
              );
            }
            if (!interactiveEnabled) return image;
            return GestureDetector(
              onTap: () => openFullscreenImageViewer(
                context,
                images: images,
                initialIndex: i,
              ),
              behavior: HitTestBehavior.opaque,
              child: image,
            );
          },
        ),
        if (showIndicator)
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == index;
                final diameter = active ? 8.0 : 6.0;
                return Container(
                  width: diameter,
                  height: diameter,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? indicatorColor
                        : indicatorColor.withValues(alpha: 0.6),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.controller,
    required this.images,
    required this.selectedIndex,
    required this.imageBg,
    required this.borderColor,
    required this.size,
    required this.gap,
    required this.onSelected,
  });

  final ScrollController controller;
  final List<String> images;
  final int selectedIndex;
  final Color imageBg;
  final Color borderColor;
  final _ThumbSize size;
  final double gap;
  final ValueChanged<int> onSelected;

  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.height,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return Semantics(
            button: true,
            selected: selected,
            label: 'Product image ${i + 1}',
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: size.width,
                height: size.height,
                foregroundDecoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? borderColor : Colors.transparent,
                    width: _borderWidth,
                  ),
                ),
                child: AppDropNetworkImage(
                  url: images[i],
                  fit: BoxFit.cover,
                  width: size.width,
                  height: size.height,
                  errorBuilder: (_, __, ___) =>
                      ProductImagePlaceholder(backgroundColor: imageBg),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
