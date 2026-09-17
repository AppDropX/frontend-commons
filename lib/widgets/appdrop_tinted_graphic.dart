import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/icon_mapper.dart';
import '../utils/network_image_url.dart';
import '../utils/toolbar_icons.dart';
import 'appdrop_network_image.dart';

/// Fluent glyph, or a remote SVG/PNG tinted to [color] (theme toolbar font).
class AppDropTintedGraphic extends StatelessWidget {
  const AppDropTintedGraphic({
    super.key,
    required this.glyph,
    required this.color,
    this.svgUrl = '',
    this.size = 20,
    this.filled = false,
  });

  final String glyph;
  final String svgUrl;
  final Color color;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final url = sanitizedNetworkImageUrl(svgUrl);
    if (url != null && isSvgNetworkUrl(url)) {
      return SvgPicture.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (_) => SizedBox(
          width: size,
          height: size,
          child: _glyphIcon(),
        ),
        errorBuilder: (_, __, ___) => _glyphIcon(),
      );
    }
    if (url != null) {
      return AppDropNetworkImage(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: BlendMode.srcIn,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _glyphIcon(),
      );
    }
    return _glyphIcon();
  }

  Widget _glyphIcon() {
    return Icon(
      iconFromNameForNav(glyph, filled),
      size: size,
      color: color,
    );
  }
}
