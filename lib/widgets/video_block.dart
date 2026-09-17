import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';

/// Builds a video block from [WidgetNode] props: url, aspectRatio, radiusDp,
/// autoplay, loop, showControls, muted, bgColor.
Widget buildVideoBlock(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final url = node.s('url', def: '');
  final aspect = node.d('aspectRatio', def: 16 / 9);
  final radius = node.d('radiusDp', def: 16);
  final autoplay = node.b('autoplay', def: false);
  final loop = node.b('loop', def: false);
  final showControls = node.b('showControls', def: true);
  final muted = node.b('muted', def: false);
  final bg = parseHexColor(node.s('bgColor', def: '')) ?? const Color(0xFF1F2937);
  final tapAction = effectiveMediaTapAction(node);

  Widget wrapTap(Widget child) {
    if (tapAction == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => env.dispatchAction(context, tapAction),
      child: child,
    );
  }

  final br = BorderRadius.circular(env.r.dp(radius));
  final blockShadows = appDropMediaBlockShadowsOf(context, node);

  if (url.isEmpty) {
    return wrapTap(
      Container(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: blockShadows,
        ),
        child: ClipRRect(
          borderRadius: br,
          child: AspectRatio(
            aspectRatio: aspect <= 0 ? 16 / 9 : aspect,
            child: Container(
              color: bg,
              child: const Center(
                child: Icon(FluentIcons.video_off_20_regular, size: 48, color: Colors.white54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  return Container(
    decoration: BoxDecoration(
      borderRadius: br,
      boxShadow: blockShadows,
    ),
    child: ClipRRect(
      borderRadius: br,
      child: AspectRatio(
        aspectRatio: aspect <= 0 ? 16 / 9 : aspect,
        child: _VideoPlayer(
          url: url,
          autoplay: autoplay,
          loop: loop,
          showControls: showControls,
          muted: muted,
          redirectAction: tapAction,
          env: env,
          buildContext: context,
        ),
      ),
    ),
  );
}

class _VideoPlayer extends StatefulWidget {
  const _VideoPlayer({
    required this.url,
    required this.autoplay,
    required this.loop,
    required this.showControls,
    required this.muted,
    this.redirectAction,
    this.env,
    this.buildContext,
  });

  final String url;
  final bool autoplay;
  final bool loop;
  final bool showControls;
  final bool muted;
  final Map<String, dynamic>? redirectAction;
  final AppDropBuildEnv? env;
  final BuildContext? buildContext;

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  static const _initTimeout = Duration(seconds: 25);

  VideoPlayerController? _controller;
  String? _lastUrl;
  int _attempt = 0;
  int _generation = 0;
  bool _retryScheduled = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _lastUrl = null;
      _attempt = 0;
      _initController();
    } else if (_controller != null && _controller!.value.isInitialized) {
      if (oldWidget.loop != widget.loop) {
        _controller!.setLooping(widget.loop);
      }
      if (oldWidget.muted != widget.muted) {
        _controller!.setVolume(widget.muted ? 0 : 1);
      }
    }
  }

  Future<void> _initController() async {
    if (widget.url.isEmpty || widget.url == _lastUrl) return;
    final generation = ++_generation;
    _lastUrl = widget.url;
    await _releaseController();
    if (!mounted || generation != _generation) return;
    setState(() {});

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      controller.addListener(_onControllerUpdate);
      await controller.initialize().timeout(_initTimeout);
      if (!mounted || generation != _generation) return;
      await controller.setLooping(widget.loop);
      await controller.setVolume(widget.muted ? 0 : 1);
      if (widget.autoplay && mounted && generation == _generation) {
        await controller.play();
      }
      _attempt = 0;
      if (mounted && generation == _generation) setState(() {});
    } catch (_) {
      if (!mounted || generation != _generation) return;
      await _releaseController();
      _scheduleRetry();
    }
  }

  void _onControllerUpdate() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    if (controller.value.hasError) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_retryScheduled || !mounted) return;
    _retryScheduled = true;
    _attempt++;
    final shift = (_attempt - 1).clamp(0, 3);
    final delay = Duration(milliseconds: 1000 * (1 << shift));
    Future<void>.delayed(delay, () async {
      _retryScheduled = false;
      if (!mounted) return;
      _lastUrl = null;
      await _initController();
    });
    if (mounted) setState(() {});
  }

  Future<void> _releaseController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onControllerUpdate);
    await controller.dispose();
  }

  @override
  void dispose() {
    _generation++;
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    if (!ready) {
      return const AppDropMediaShimmer();
    }

    final hasRedirect =
        widget.redirectAction != null && widget.env != null && widget.buildContext != null;

    Widget playCtrl() {
      void toggle() {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
        setState(() {});
      }

      if (hasRedirect) {
        return Positioned(
          right: 6,
          bottom: 6,
          child: Material(
            color: Colors.black45,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: toggle,
              icon: Icon(
                controller.value.isPlaying ? FluentIcons.pause_20_regular : FluentIcons.play_20_regular,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: toggle,
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            controller.value.isPlaying ? FluentIcons.pause_circle_20_filled : FluentIcons.play_circle_20_filled,
            size: 64,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        if (hasRedirect)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final ctx = widget.buildContext!;
                if (!ctx.mounted) return;
                widget.env!.dispatchAction(ctx, widget.redirectAction!);
              },
            ),
          ),
        if (widget.showControls) playCtrl(),
      ],
    );
  }
}
