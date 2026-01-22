import 'package:flutter/widgets.dart';
import '../theme_library.dart';

Widget buildCarousel(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final itemWidthFactor = node.d('itemWidthFactor', def: 0.82).clamp(0.2, 1.0);
  final spacingDp = node.d('spacingDp', def: 12);
  final paddingDp = node.d('paddingDp', def: 0);
  final heightDp = node.d('heightDp', def: 0);

  if (node.children.isEmpty) return const SizedBox.shrink();

  // Always bounded height (fix for RenderBox not laid out)
  final h = heightDp > 0 ? env.r.dp(heightDp) : env.r.w * 0.55;

  return SizedBox(
    height: h,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: env.r.dp(paddingDp)),
      itemCount: node.children.length,
      separatorBuilder: (_, __) => SizedBox(width: env.r.dp(spacingDp)),
      itemBuilder: (ctx, i) {
        return SizedBox(
          width: env.r.w * itemWidthFactor,
          child: env.renderNode(ctx, node.children[i]) as Widget,
        );
      },
    ),
  );
}
