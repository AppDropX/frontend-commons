import 'package:flutter/material.dart';

import '../transitions/product_hero_tags.dart';
import '../utils/network_image_url.dart';
import 'product_image_placeholder.dart';

/// Network product image with optional [Hero] flight (aspect ratio preserved).
Widget buildProductHeroImage({
  required String productId,
  required String? imageUrl,
  required double aspectRatio,
  required BoxFit boxFit,
  required Color imageBg,
  required BorderRadius borderRadius,
  String? heroTag,
  bool enableHero = true,
}) {
  final url = sanitizedNetworkImageUrl(imageUrl ?? '');
  final trimmedHeroTag = heroTag?.trim();
  final tag = !enableHero || productId.trim().isEmpty
      ? null
      : (trimmedHeroTag != null && trimmedHeroTag.isNotEmpty
          ? trimmedHeroTag
          : ProductHeroTags.image(productId));

  Widget imageChild = ClipRRect(
    borderRadius: borderRadius,
    child: AspectRatio(
      aspectRatio: aspectRatio,
      child: ColoredBox(
        color: imageBg,
        child: url == null
            ? ProductImagePlaceholder(backgroundColor: imageBg)
            : Image.network(
                url,
                fit: boxFit,
                alignment: Alignment.center,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    ProductImagePlaceholder(backgroundColor: imageBg),
              ),
      ),
    ),
  );

  if (tag == null) return imageChild;

  return Hero(
    tag: tag,
    // Keeps aspect ratio stable during flight; avoids abrupt scale jumps.
    flightShuttleBuilder: (
      flightContext,
      animation,
      flightDirection,
      fromHeroContext,
      toHeroContext,
    ) {
      final fromWidget = fromHeroContext.widget;
      final toWidget = toHeroContext.widget;
      final fromChild = fromWidget is Hero ? fromWidget.child : imageChild;
      final toChild = toWidget is Hero ? toWidget.child : imageChild;
      return flightDirection == HeroFlightDirection.push ? toChild : fromChild;
    },
    child: Material(
      type: MaterialType.transparency,
      child: imageChild,
    ),
  );
}
