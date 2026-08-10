import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/launch_screen_config.dart';
import '../utils/color.dart';
import '../utils/network_image_url.dart';

/// Renders a tenant launch / splash screen from [LaunchScreenConfig].
class LaunchScreenView extends StatelessWidget {
  const LaunchScreenView({
    super.key,
    required this.config,
    this.logoOverride,
    this.fallbackLogo,
    this.fallbackBackgroundColor,
    this.useNetworkLogo = true,
  });

  final LaunchScreenConfig config;
  /// When set, replaces network/asset fallback for the app icon (e.g. cached local file).
  final Widget? logoOverride;
  final Widget? fallbackLogo;
  final Color? fallbackBackgroundColor;
  /// When false, skips [Image.network] for the logo (pilot cold-start splash).
  final bool useNetworkLogo;

  @override
  Widget build(BuildContext context) {
    final background = config.background;
    final appIcon = config.appIcon;
    final loader = config.loader;

    final backgroundColor = background.enabled && background.mode == 'color'
        ? (parseHexColor(background.color) ??
            fallbackBackgroundColor ??
            Colors.white)
        : (fallbackBackgroundColor ?? Colors.white);

    final backgroundUrl = background.enabled && background.mode == 'image'
        ? sanitizedNetworkImageUrl(background.imageUrl)
        : null;

    final logoUrl = appIcon.enabled
        ? sanitizedNetworkImageUrl(appIcon.logoUrl)
        : null;
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final logoSize = appIcon.logoDimensionForShortestSide(shortestSide);

    final loaderColor =
        parseHexColor(loader.color) ?? const Color(0xFFFF6B00);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (backgroundUrl != null)
          Positioned.fill(
            child: Image.network(
              backgroundUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(color: backgroundColor),
            ),
          )
        else
          ColoredBox(color: backgroundColor),
        if (appIcon.enabled)
          Center(
            child: logoOverride ??
                (useNetworkLogo && logoUrl != null
                    ? Image.network(
                        logoUrl,
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            fallbackLogo ?? const SizedBox.shrink(),
                      )
                    : (fallbackLogo ?? const SizedBox.shrink())),
          ),
        if (loader.enabled)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Center(
              child: CupertinoActivityIndicator(
                radius: 14,
                color: loaderColor,
              ),
            ),
          ),
      ],
    );
  }
}
