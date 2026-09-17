import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';
import '../utils/network_image_aspect.dart';
import '../utils/network_image_url.dart';

String _overlayTitleFromNode(WidgetNode node) {
  final camel = node.s('overlayTitle').trim();
  if (camel.isNotEmpty) return camel;
  return node.s('overlay_title').trim();
}

bool _showOverlayTitle(WidgetNode node) =>
    node.b('showOverlayTitle', def: false) ||
    node.b('show_overlay_title', def: false);

Widget? _overlayTitleLabel(WidgetNode node, AppDropBuildEnv env) {
  if (!_showOverlayTitle(node)) return null;
  final title = _overlayTitleFromNode(node);
  if (title.isEmpty) return null;
  return Positioned(
    top: env.r.dp(16),
    left: env.r.dp(8),
    right: env.r.dp(8),
    child: Text(
      title.toUpperCase(),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: env.r.sp(14, min: 12, max: 18),
        fontWeight: FontWeight.w500,
        letterSpacing: 1.6,
        height: 1.2,
        shadows: const [
          Shadow(blurRadius: 8, color: Color(0x66000000)),
        ],
      ),
    ),
  );
}

Widget _bannerFill({
  required String? url,
  required Color bg,
  Widget? overlay,
}) {
  return Container(
    color: bg,
    child: Stack(
      fit: StackFit.expand,
      children: [
        url == null
            ? const SizedBox.expand()
            : AppDropNetworkImage(
                url: url,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    ColoredBox(color: bg, child: const SizedBox.expand()),
              ),
        if (overlay != null) overlay,
      ],
    ),
  );
}

Widget buildImageBanner(
    BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final url = sanitizedNetworkImageUrl(node.s('url', def: ''));
  final aspect = node.d('aspectRatio', def: 16 / 9);
  final radius = node.d('radiusDp', def: 16);
  final bg =
      parseHexColor(node.s('bgColor', def: '')) ?? const Color(0xFFE5E7EB);
  final fitWithImage = node.b('fitWithImage', def: false);
  final overlay = _overlayTitleLabel(node, env);

  final action = effectiveMediaTapAction(node);
  final fallbackAspect = aspect <= 0 ? (16 / 9) : aspect;

  final br = BorderRadius.circular(env.r.dp(radius));
  final blockShadows = appDropMediaBlockShadowsOf(context, node);
  Widget child = Container(
    decoration: BoxDecoration(
      borderRadius: br,
      boxShadow: blockShadows,
    ),
    child: ClipRRect(
      borderRadius: br,
      child: fitWithImage && url != null
          ? _FitWithImageBanner(
              url: url,
              bg: bg,
              fallbackAspect: fallbackAspect,
              overlay: overlay,
            )
          : AspectRatio(
              aspectRatio: fallbackAspect,
              child: _bannerFill(url: url, bg: bg, overlay: overlay),
            ),
    ),
  );

  if (action != null) {
    child = GestureDetector(
      onTap: () => env.dispatchAction(context, action),
      child: child,
    );
  }
  return child;
}

class _FitWithImageBanner extends StatefulWidget {
  const _FitWithImageBanner({
    required this.url,
    required this.bg,
    required this.fallbackAspect,
    this.overlay,
  });

  final String url;
  final Color bg;
  final double fallbackAspect;
  final Widget? overlay;

  @override
  State<_FitWithImageBanner> createState() => _FitWithImageBannerState();
}

class _FitWithImageBannerState extends State<_FitWithImageBanner> {
  double? _aspect;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _FitWithImageBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _aspect = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final aspect = await resolveNetworkImageAspectRatio(widget.url);
    if (!mounted || aspect == null || aspect <= 0) return;
    setState(() => _aspect = aspect);
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect ?? widget.fallbackAspect;
    return AspectRatio(
      aspectRatio: aspect,
      child: _bannerFill(
        url: widget.url,
        bg: widget.bg,
        overlay: widget.overlay,
      ),
    );
  }
}
