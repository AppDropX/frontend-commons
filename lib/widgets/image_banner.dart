import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';
import '../utils/network_image_url.dart';

Widget buildImageBanner(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final url = sanitizedNetworkImageUrl(node.s('url', def: ''));
  final aspect = node.d('aspectRatio', def: 16 / 9);
  final radius = node.d('radiusDp', def: 16);
  final bg = parseHexColor(node.s('bgColor', def: '')) ?? const Color(0xFFE5E7EB);

  final action = effectiveMediaTapAction(node);

  final br = BorderRadius.circular(env.r.dp(radius));
  Widget child = Container(
    decoration: BoxDecoration(
      borderRadius: br,
      boxShadow: kAppDropComponentShadows,
    ),
    child: ClipRRect(
      borderRadius: br,
      child: AspectRatio(
        aspectRatio: aspect <= 0 ? (16 / 9) : aspect,
        child: Container(
          color: bg,
          child: url == null
              ? const SizedBox.expand()
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: bg, child: const SizedBox.expand()),
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
