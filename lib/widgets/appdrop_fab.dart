import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../models/fab_config.dart';
import '../theme/appdrop_theme_config.dart';
import '../utils/icon_mapper.dart';
import '../utils/network_image_url.dart';
import 'appdrop_network_image.dart';

const double kAppDropFabSize = 52;
const double kAppDropFabHorizontalInset = 20;

/// Gap above the home indicator when the storefront bottom nav is hidden.
const double kAppDropFabBottomInset = 56;

/// Gap above a painted bottom nav (nav already includes the home indicator).
const double kAppDropFabBottomInsetAboveNav = 104;
const double kAppDropFabImageInset = 4;

/// Whether the storefront bottom bar will actually paint (theme on + items).
bool appDropBottomNavIsPainted({
  required bool showBottomNav,
  Map<String, dynamic>? themeJson,
  BottomBarConfig? bottomBar,
}) {
  if (!showBottomNav) return false;
  final bar = bottomBar ??
      (themeJson == null
          ? null
          : BottomBarConfig.fromJson(
              Map<String, dynamic>.from(
                themeJson['bottom_bar'] is Map
                    ? themeJson['bottom_bar'] as Map
                    : const {},
              ),
            ));
  if (bar == null) return false;
  return bar.enabled && bar.items.any((item) => item.enabled);
}

double appDropFabBottomOffset({
  required bool bottomNavVisible,
  double safeAreaBottom = 0,
}) {
  if (bottomNavVisible) return kAppDropFabBottomInsetAboveNav;
  return kAppDropFabBottomInset + safeAreaBottom;
}

/// Positions [AppDropFab] over [child], lifting it when bottom nav is painted.
class AppDropFabOverlay extends StatelessWidget {
  const AppDropFabOverlay({
    super.key,
    required this.config,
    required this.routePath,
    required this.onTap,
    required this.bottomNavVisible,
    required this.child,
  });

  final FabConfig config;
  final String routePath;
  final VoidCallback onTap;
  final bool bottomNavVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!config.isVisibleOnRoute(routePath)) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: kAppDropFabHorizontalInset,
          bottom: appDropFabBottomOffset(
            bottomNavVisible: bottomNavVisible,
            safeAreaBottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: AppDropFab(config: config, onTap: onTap),
        ),
      ],
    );
  }
}

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
                      padding: const EdgeInsets.all(kAppDropFabImageInset),
                      child: AppDropNetworkImage(
                        url: imageUrl,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        showLoadingShimmer: false,
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
