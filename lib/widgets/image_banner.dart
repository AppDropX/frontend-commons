import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';

Widget buildImageBanner(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final url = node.s('url', def: '');
  final aspect = node.d('aspectRatio', def: 16 / 9);
  final radius = node.d('radiusDp', def: 16);
  final bg = parseHexColor(node.s('bgColor', def: '')) ?? const Color(0xFFE5E7EB);

  final action = node.m('action');

  Widget child = ClipRRect(
    borderRadius: BorderRadius.circular(env.r.dp(radius)),
    child: AspectRatio(
      aspectRatio: aspect <= 0 ? (16 / 9) : aspect,
      child: Container(
        color: bg,
        child: url.isEmpty ? const SizedBox.expand() : Image.network(url, fit: BoxFit.cover),
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
