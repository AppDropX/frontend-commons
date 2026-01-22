import 'dart:async';
import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';

class _SliderState extends StatefulWidget {
  final List<String> images;
  final double aspectRatio;
  final double radiusDp;
  final bool showIndicator;
  final bool autoPlay;
  final int intervalMs;

  final double dotSizeDp;
  final double dotGapDp;

  const _SliderState({
    required this.images,
    required this.aspectRatio,
    required this.radiusDp,
    required this.showIndicator,
    required this.autoPlay,
    required this.intervalMs,
    required this.dotSizeDp,
    required this.dotGapDp,
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
    return PageView.builder(
      controller: controller,
      itemCount: widget.images.length,
      onPageChanged: (i) => setState(() => index = i),
      itemBuilder: (_, i) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radiusDp),
          child: Image.network(widget.images[i], fit: BoxFit.cover),
        );
      },
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
      child: Stack(
        children: [
          _SliderState(
            images: images,
            aspectRatio: aspect,
            radiusDp: radius,
            showIndicator: showIndicator,
            autoPlay: autoPlay,
            intervalMs: interval,
            dotSizeDp: dotSize,
            dotGapDp: dotGap,
          ),
          if (showIndicator && images.length > 1)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: env.r.dp(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(images.length, (i) {
                    final active = false; // indicator handled visually only
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: dotGap / 2),
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (i == 0) ? dotActive : dotInactive, // simple (you can refine)
                      ),
                    );
                  }),
                ),
              ),
            )
        ],
      ),
    ),
  );
}
