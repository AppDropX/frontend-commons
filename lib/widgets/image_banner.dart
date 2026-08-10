import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';
import '../utils/network_image_aspect.dart';
import '../utils/network_image_url.dart';

Widget buildImageBanner(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final url = sanitizedNetworkImageUrl(node.s('url', def: ''));
  final aspect = node.d('aspectRatio', def: 16 / 9);
  final radius = node.d('radiusDp', def: 16);
  final bg = parseHexColor(node.s('bgColor', def: '')) ?? const Color(0xFFE5E7EB);
  final fitWithImage = node.b('fitWithImage', def: false);

  final action = effectiveMediaTapAction(node);
  final fallbackAspect = aspect <= 0 ? (16 / 9) : aspect;

  final br = BorderRadius.circular(env.r.dp(radius));
  Widget child = Container(
    decoration: BoxDecoration(
      borderRadius: br,
      boxShadow: kAppDropComponentShadows,
    ),
    child: ClipRRect(
      borderRadius: br,
      child: fitWithImage && url != null
          ? _FitWithImageBanner(
              url: url,
              bg: bg,
              fallbackAspect: fallbackAspect,
            )
          : AspectRatio(
              aspectRatio: fallbackAspect,
              child: Container(
                color: bg,
                child: url == null
                    ? const SizedBox.expand()
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: bg, child: const SizedBox.expand()),
                      ),
              ),
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
  });

  final String url;
  final Color bg;
  final double fallbackAspect;

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
      child: Container(
        color: widget.bg,
        child: Image.network(
          widget.url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              ColoredBox(color: widget.bg, child: const SizedBox.expand()),
        ),
      ),
    );
  }
}
