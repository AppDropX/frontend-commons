import 'package:flutter/material.dart';

import '../utils/image_decode_size.dart';
import 'appdrop_block_shimmer.dart';

/// [Image.network] that decodes at the size it paints into rather than at the
/// source resolution.
///
/// Product originals are frequently 2000 px+; decoding one at full size costs
/// ~16 MB of RGBA whether it fills the screen or a 150 dp grid tile. Flutter's
/// default `imageCache` budget is 100 MB, so a handful of full-size decodes
/// evicts everything and every scroll reversal re-downloads and re-decodes.
/// Sizing the decode keeps the cache holding hundreds of entries instead of a
/// few.
class AppDropNetworkImage extends StatelessWidget {
  const AppDropNetworkImage({
    super.key,
    required this.url,
    required this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.gaplessPlayback = false,
    this.color,
    this.colorBlendMode,
    this.filterQuality = FilterQuality.medium,
    this.fadeInDuration = const Duration(milliseconds: 160),
    this.showLoadingShimmer = true,
    this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;
  final bool gaplessPlayback;
  final Color? color;
  final BlendMode? colorBlendMode;
  final FilterQuality filterQuality;
  final Duration fadeInDuration;
  final bool showLoadingShimmer;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : width;
        final decodeWidth = boxWidth == null
            ? null
            : decodeWidthForBox(boxWidth, devicePixelRatio);
        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          gaplessPlayback: gaplessPlayback,
          color: color,
          colorBlendMode: colorBlendMode,
          filterQuality: filterQuality,
          // ResizeImage never upscales, so already-small thumbnails pass through.
          cacheWidth: decodeWidth,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || fadeInDuration == Duration.zero) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: fadeInDuration,
              curve: Curves.easeOut,
              child: child,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null || !showLoadingShimmer) return child;
            final bounded = constraints.maxWidth.isFinite &&
                constraints.maxHeight.isFinite &&
                constraints.maxWidth > 0 &&
                constraints.maxHeight > 0;
            final shimmer = Stack(
              fit: bounded ? StackFit.expand : StackFit.loose,
              alignment: Alignment.center,
              children: [
                if (bounded)
                  const Positioned.fill(child: AppDropMediaShimmer())
                else
                  const AppDropMediaShimmer(),
                child,
              ],
            );
            if (!bounded) return shimmer;
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: shimmer,
            );
          },
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
