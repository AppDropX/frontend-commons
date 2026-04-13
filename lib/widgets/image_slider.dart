import 'dart:async';
import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/network_image_url.dart';

class _SliderState extends StatefulWidget {
  final List<String> images;
  final List<dynamic>? imageRedirects;
  final AppDropBuildEnv env;
  final BuildContext hostContext;

  final double radiusDp;
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
    required this.radiusDp,
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
        controller.animateToPage(next, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
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
            Widget slide = ClipRRect(
              borderRadius: BorderRadius.circular(widget.radiusDp),
              child: u == null
                  ? const ColoredBox(color: Color(0xFFE5E7EB), child: SizedBox.expand())
                  : Image.network(
                      u,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFE5E7EB), child: SizedBox.expand()),
                    ),
            );
            if (action != null) {
              slide = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.env.dispatchAction(widget.hostContext, action),
                child: slide,
              );
            }
            return slide;
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
                    margin: EdgeInsets.symmetric(horizontal: widget.dotGapDp / 2),
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

Widget buildImageSlider(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final imagesRaw = node.l('images') ?? const [];
  final images = imagesRaw.map((e) => e.toString()).toList();

  if (images.isEmpty) return const SizedBox.shrink();

  final aspect = node.d('aspectRatio', def: 16 / 9);
  final radius = env.r.dp(node.d('radiusDp', def: 16));
  final showIndicator = node.b('showIndicator', def: true);
  final autoPlay = node.b('autoPlay', def: false);
  final interval = node.i('intervalMs', def: 2500);

  final dotSize = env.r.dp(node.d('dotSizeDp', def: 6));
  final dotGap = env.r.dp(node.d('dotGapDp', def: 6));
  final dotActive = parseHexColor(node.s('dotActive', def: '')) ?? const Color(0xFFFFFFFF);
  final dotInactive = parseHexColor(node.s('dotInactive', def: '')) ?? const Color(0x88FFFFFF);

  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: AspectRatio(
      aspectRatio: aspect <= 0 ? 16 / 9 : aspect,
      child: _SliderState(
        images: images,
        imageRedirects: imageRedirectsListFromNode(node),
        env: env,
        hostContext: context,
        radiusDp: radius,
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
  );
}
