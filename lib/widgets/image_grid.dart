import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';

Widget buildImageGrid(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final imgsRaw = node.l('images') ?? const [];
  final images = imgsRaw.map((e) => e.toString()).toList();
  if (images.isEmpty) return const SizedBox.shrink();

  final maxTile = node.d('maxTileWidthDp', def: 140);
  final spacing = node.d('spacingDp', def: 10);
  final radius = node.d('radiusDp', def: 14);
  final aspect = node.d('tileAspectRatio', def: 1.0);
  final bg = parseHexColor(node.s('imageBgColor', def: '')) ?? const Color(0xFFE5E7EB);

  final cols = (env.r.w / env.r.dp(maxTile)).floor().clamp(2, 4);

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: images.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      crossAxisSpacing: env.r.dp(spacing),
      mainAxisSpacing: env.r.dp(spacing),
      childAspectRatio: aspect <= 0 ? 1.0 : aspect,
    ),
    itemBuilder: (_, i) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(env.r.dp(radius)),
        child: Container(
          color: bg,
          child: Image.network(images[i], fit: BoxFit.cover),
        ),
      );
    },
  );
}
