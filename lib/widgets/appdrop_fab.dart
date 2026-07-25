import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../models/fab_config.dart';
import '../utils/icon_mapper.dart';
import '../utils/network_image_url.dart';

const double kAppDropFabSize = 52;
const double kAppDropFabHorizontalInset = 20;
const double kAppDropFabBottomInset = 36;
/// Bottom offset when the storefront bottom nav is visible (FAB floats above it).
const double kAppDropFabBottomInsetAboveNav = 104;
const double _fabImageInset = 10;

/// Floating action button rendered from tenant [FabConfig].
class AppDropFab extends StatelessWidget {
  const AppDropFab({
    super.key,
    required this.config,
    required this.onTap,
    this.size = kAppDropFabSize,
  });

  final FabConfig config;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!config.enabled) return const SizedBox.shrink();

    final isImage = config.contentStyle == 'image';
    final imageUrl = sanitizedNetworkImageUrl(config.imageUrl);

    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      color: config.backgroundColorValue,
      borderRadius: config.borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: config.borderRadius,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: config.borderRadius,
            border: Border.all(color: Colors.black12),
          ),
          child: isImage
              ? (imageUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(_fabImageInset),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          FluentIcons.image_off_20_regular,
                          color: config.iconColorValue,
                          size: 26,
                        ),
                      ),
                    )
                  : Icon(
                      FluentIcons.image_20_regular,
                      color: config.iconColorValue,
                      size: 26,
                    ))
              : Icon(
                  fabIconFromName(config.icon),
                  color: config.iconColorValue,
                  size: 26,
                ),
        ),
      ),
    );
  }
}
