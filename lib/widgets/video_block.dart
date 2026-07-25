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

  if (url.isEmpty) {
    return wrapTap(
      Container(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: kAppDropComponentShadows,
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
      boxShadow: kAppDropComponentShadows,
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
          bgColor: bg,
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
    required this.bgColor,
    this.redirectAction,
    this.env,
    this.buildContext,
  });

  final String url;
  final bool autoplay;
  final bool loop;
  final bool showControls;
  final bool muted;
  final Color bgColor;
  final Map<String, dynamic>? redirectAction;
  final AppDropBuildEnv? env;
  final BuildContext? buildContext;

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  VideoPlayerController? _controller;
  String? _lastUrl;
  bool _error = false;

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
      _initController();
    }
  }

  Future<void> _initController() async {
    if (widget.url.isEmpty || widget.url == _lastUrl) return;
    await _controller?.dispose();
    _lastUrl = widget.url;
    _error = false;
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..setLooping(widget.loop)
        ..setVolume(widget.muted ? 0 : 1);
      await _controller!.initialize();
      if (widget.autoplay && mounted) {
        _controller!.play();
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: widget.bgColor,
        child: const Center(
          child: Icon(FluentIcons.error_circle_20_regular, size: 48, color: Colors.white54),
        ),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: widget.bgColor,
        child: const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
          ),
        ),
      );
    }
    final hasRedirect =
        widget.redirectAction != null && widget.env != null && widget.buildContext != null;

    Widget playCtrl() {
      void toggle() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
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
                _controller!.value.isPlaying ? FluentIcons.pause_20_regular : FluentIcons.play_20_regular,
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
            _controller!.value.isPlaying ? FluentIcons.pause_circle_20_filled : FluentIcons.play_circle_20_filled,
            size: 64,
            color: Colors.white.withOpacity(0.9),
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
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
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
