import 'dart:async';
import 'package:flutter/material.dart';
import '../theme_library.dart';
import 'fullscreen_image_viewer.dart';
import '../transitions/pdp_enter_animation.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';
import '../utils/network_image_url.dart';
import 'product_hero_image.dart';

class _SliderState extends StatefulWidget {
  final List<String> images;
  final List<dynamic>? imageRedirects;
  final AppDropBuildEnv env;
  final BuildContext hostContext;
  final String heroProductId;
  final String heroTag;
  final bool enableFullscreenViewer;

  final double radiusDp;
  final double slideSpacing;
  final bool showIndicator;
  final bool autoPlay;
  final int intervalMs;

  final double dotSizeDp;
  final double dotGapDp;
  final Color dotActive;
  final Color dotInactive;
  final double dotBottomPadding;

  const _SliderState({
    required this.images,
    required this.imageRedirects,
    required this.env,
    required this.hostContext,
    required this.heroProductId,
    required this.heroTag,
    required this.enableFullscreenViewer,
    required this.radiusDp,
    required this.slideSpacing,
    required this.showIndicator,
    required this.autoPlay,
    required this.intervalMs,
    required this.dotSizeDp,
    required this.dotGapDp,
    required this.dotActive,
    required this.dotInactive,
    required this.dotBottomPadding,
  });

  @override
  State<_SliderState> createState() => _SliderStateState();
}

class _SliderStateState extends State<_SliderState> {
  final controller = PageController();
  int index = 0;
  Timer? t;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay && widget.images.length > 1) {
      t = Timer.periodic(Duration(milliseconds: widget.intervalMs), (_) {
        final next = (index + 1) % widget.images.length;
        controller.animateToPage(next,
            duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      });
    }
  }

  @override
  void dispose() {
    t?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: controller,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => index = i),
          itemBuilder: (_, i) {
            final u = sanitizedNetworkImageUrl(widget.images[i]);
            final action = actionFromImageRedirectsAt(widget.imageRedirects, i);
            Widget slide;
            if (i == 0 &&
                widget.heroProductId.isNotEmpty &&
                widget.heroTag.isNotEmpty) {
              slide = buildProductHeroImage(
                productId: widget.heroProductId,
                imageUrl: widget.images[i],
                aspectRatio: 1,
                boxFit: BoxFit.cover,
                imageBg: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(widget.radiusDp),
                heroTag: widget.heroTag,
              );
            } else {
              slide = ClipRRect(
                borderRadius: BorderRadius.circular(widget.radiusDp),
                child: u == null
                    ? const ColoredBox(
                        color: Color(0xFFE5E7EB),
                        child: SizedBox.expand(),
                      )
                    : Image.network(
                        u,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFE5E7EB),
                          child: SizedBox.expand(),
                        ),
                      ),
              );
            }
            if (action != null) {
              if (widget.enableFullscreenViewer) {
                slide = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => openFullscreenImageViewer(
                    context,
                    images: widget.images,
                    initialIndex: i,
                  ),
                  child: slide,
                );
              } else {
                slide = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      widget.env.dispatchAction(widget.hostContext, action),
                  child: slide,
                );
              }
            } else if (widget.enableFullscreenViewer) {
              slide = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => openFullscreenImageViewer(
                  context,
                  images: widget.images,
                  initialIndex: i,
                ),
                child: slide,
              );
            }
            if (widget.slideSpacing <= 0) return slide;
            return Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: widget.slideSpacing / 2),
              child: slide,
            );
          },
        ),
        if (widget.showIndicator && widget.images.length > 1)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.dotBottomPadding),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.images.length, (i) {
                  return Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: widget.dotGapDp / 2),
                    width: widget.dotSizeDp,
                    height: widget.dotSizeDp,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == index ? widget.dotActive : widget.dotInactive,
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}

Widget buildImageSlider(
    BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final imagesRaw = node.l('images') ?? const [];
  final images = imagesRaw.map((e) => e.toString()).toList();

  if (images.isEmpty) return const SizedBox.shrink();

  final aspect = node.d('aspectRatio', def: 16 / 9);
  final radius = env.r.dp(node.d('radiusDp', def: 16));
  final slideSpacing = env.r.dp(node.d('spacingDp', def: 0));
  final showIndicator = node.b('showIndicator', def: true);
  final autoPlay = node.b('autoPlay', def: false);
  final interval = node.i('intervalMs', def: 2500);

  final dotSize = env.r.dp(node.d('dotSizeDp', def: 6));
  final dotGap = env.r.dp(node.d('dotGapDp', def: 6));
  final dotActive =
      parseHexColor(node.s('dotActive', def: '')) ?? const Color(0xFFFFFFFF);
  final dotInactive =
      parseHexColor(node.s('dotInactive', def: '')) ?? const Color(0x88FFFFFF);

  final heroProductId = node.s('productId', def: '').trim();
  final heroTag = node.s('heroTag', def: '').trim();
  final enableFullscreenViewer = node.b(
    'enableFullscreenViewer',
    def: heroProductId.isNotEmpty,
  );
  final br = BorderRadius.circular(radius);
  final slider = Container(
    decoration: BoxDecoration(
      borderRadius: br,
      boxShadow: kAppDropComponentShadows,
    ),
    child: ClipRRect(
      borderRadius: br,
      child: AspectRatio(
        aspectRatio: aspect <= 0 ? 16 / 9 : aspect,
        child: _SliderState(
          images: images,
          imageRedirects: imageRedirectsListFromNode(node),
          env: env,
          hostContext: context,
          heroProductId: heroProductId,
          heroTag: heroTag,
          enableFullscreenViewer: enableFullscreenViewer,
          radiusDp: radius,
          slideSpacing: slideSpacing,
          showIndicator: showIndicator,
          autoPlay: autoPlay,
          intervalMs: interval,
          dotSizeDp: dotSize,
          dotGapDp: dotGap,
          dotActive: dotActive,
          dotInactive: dotInactive,
          dotBottomPadding: env.r.dp(10),
        ),
      ),
    ),
  );
  return wrapPdpStagger(context, PdpStaggerSlot.image, slider);
}
