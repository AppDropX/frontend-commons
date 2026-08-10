import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';
import '../utils/network_image_url.dart';

double _nameSpForVariation(String v, AppDropBuildEnv env) {
  switch (v.toLowerCase()) {
    case 'small':
      return env.r.sp(12, min: 11, max: 16);
    case 'large':
      return env.r.sp(16, min: 14, max: 20);
    case 'medium':
    default:
      return env.r.sp(14, min: 12, max: 18);
  }
}

/// Vertical space reserved below each image when names are shown (single line).
double _nameBlockHeight(AppDropBuildEnv env, double nameFontSize, bool showNames) {
  if (!showNames) return 0;
  const maxLines = 1;
  const lineHeightFactor = 1.25;
  return env.r.dp(6) + nameFontSize * lineHeightFactor * maxLines + env.r.dp(2);
}

Widget buildImageGrid(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  if (!node.b('enabled', def: true)) return const SizedBox.shrink();

  final props = Map<String, dynamic>.from(node.props);
  normalizeImageGridProps(props);
  final gridNode = WidgetNode(type: node.type, props: props, children: node.children);

  final imgsRaw = gridNode.l('images') ?? const [];
  final images = imgsRaw.map((e) => e.toString()).toList();
  if (images.isEmpty) return const SizedBox.shrink();

  final maxTile = gridNode.d('maxTileWidthDp', def: 140);
  final spacing = gridNode.d('spacingDp', def: 10);
  final radius = gridNode.d('radiusDp', def: 14);
  final aspect = gridNode.d('tileAspectRatio', def: 1.0);
  final bg = parseHexColor(gridNode.s('imageBgColor', def: '')) ?? const Color(0xFFE5E7EB);

  final layoutMode = gridNode.s('layoutMode', def: 'grid').toLowerCase();
  final isCarousel = layoutMode == 'carousel' || layoutMode == 'horizontal';
  final showNames = gridNode.b('showImageNames', def: false);
  final nameFontSize = _nameSpForVariation(
    gridNode.s('imageNameFontVariation', def: 'medium'),
    env,
  );
  final nameColor =
      parseHexColor(gridNode.s('imageNameColor', def: '#000000')) ??
          const Color(0xFF000000);
  final namesRaw = gridNode.l('imageNames') ?? const [];
  String nameAt(int i) =>
      i >= 0 && i < namesRaw.length ? namesRaw[i].toString().trim() : '';

  final redirectList = imageRedirectsListFromNode(gridNode);
  final safeAspect = aspect <= 0 ? 1.0 : aspect;
  final spacingPx = env.r.dp(spacing);
  final radiusPx = env.r.dp(radius);

  Widget buildImage(String url) {
    final u = sanitizedNetworkImageUrl(url);
    final br = BorderRadius.circular(radiusPx);
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: kAppDropComponentShadows,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Container(
          color: bg,
          child: u == null
              ? const SizedBox.expand()
              : Image.network(
                  u,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: bg, child: const SizedBox.expand()),
                ),
        ),
      ),
    );
  }

  Widget buildNameLabel(String name, {required double maxHeight}) {
    if (!showNames || name.isEmpty || maxHeight <= 0) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: maxHeight,
      child: Padding(
        padding: EdgeInsets.only(top: env.r.dp(6)),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: nameFontSize,
              color: nameColor,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTile(
    int i, {
    required double tileWidth,
    required double tileHeight,
  }) {
    final imageH = (tileWidth / safeAspect).clamp(0.0, tileHeight);
    final nameBlockH = (tileHeight - imageH).clamp(0.0, double.infinity);
    final name = nameAt(i);
    final action = actionFromImageRedirectsAt(redirectList, i);

    Widget tile = SizedBox(
      width: tileWidth,
      height: tileHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: tileWidth,
            height: imageH,
            child: buildImage(images[i]),
          ),
          buildNameLabel(name, maxHeight: nameBlockH),
        ],
      ),
    );

    if (action != null) {
      tile = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => env.dispatchAction(context, action),
        child: tile,
      );
    }
    return tile;
  }

  if (isCarousel) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;
        if (width <= 0) return const SizedBox.shrink();

        final tileW = env.r.dp(maxTile).clamp(100.0, width * 0.55);
        final imageH = tileW / safeAspect;
        final nameExtra = _nameBlockHeight(env, nameFontSize, showNames);
        final rowH = imageH + nameExtra;

        return SizedBox(
          height: rowH,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: images.length,
            separatorBuilder: (_, __) => SizedBox(width: spacingPx),
            itemBuilder: (_, i) => buildTile(
              i,
              tileWidth: tileW,
              tileHeight: rowH,
            ),
          ),
        );
      },
    );
  }

  return LayoutBuilder(
    builder: (ctx, constraints) {
      final width = constraints.maxWidth;
      if (width <= 0) return const SizedBox.shrink();

      final cols = (width / env.r.dp(maxTile)).floor().clamp(2, 4);
      final tileW = (width - spacingPx * (cols - 1)) / cols;
      final imageH = tileW / safeAspect;
      final nameExtra = _nameBlockHeight(env, nameFontSize, showNames);
      final tileH = imageH + nameExtra;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: spacingPx,
          mainAxisSpacing: spacingPx,
          mainAxisExtent: tileH,
        ),
        itemBuilder: (_, i) => buildTile(
          i,
          tileWidth: tileW,
          tileHeight: tileH,
        ),
      );
    },
  );
}
