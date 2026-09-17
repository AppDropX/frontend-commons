import 'package:flutter/widgets.dart';
import '../theme_library.dart';

Widget buildSpacer(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final h = node.d('sizeDp', def: 12);
  if (h <= 0) return const SizedBox.shrink();
  return SizedBox(height: env.r.dp(h));
}
