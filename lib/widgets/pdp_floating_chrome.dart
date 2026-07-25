import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../pdp/pdp_overlay_button.dart';
import '../pdp/pdp_overlay_metrics.dart';
import '../utils/icon_mapper.dart';

/// Overlay back + wishlist controls for PDP when the app bar is hidden.
class PdpFloatingChrome extends StatelessWidget {
  const PdpFloatingChrome({
    super.key,
    this.onBack,
    this.onWishlistTap,
    this.showWishlist = true,
    this.wishlistSelected = false,
    this.wishlistColor = const Color(0xFFE53935),
    this.applySafeAreaTop = true,
    this.extraTopInset = 0,
  });

  final VoidCallback? onBack;
  final VoidCallback? onWishlistTap;
  final bool showWishlist;
  final bool wishlistSelected;
  final Color wishlistColor;

  /// When false, the parent [SafeArea] already insets the top (e.g. full-page PDP).
  final bool applySafeAreaTop;

  /// Extra top offset when [MediaQuery] omits status-bar padding (builder preview).
  final double extraTopInset;

  @override
  Widget build(BuildContext context) {
    final showWishlistButton = showWishlist;
    if (onBack == null && !showWishlistButton) {
      return const SizedBox.shrink();
    }

    final topInset = PdpOverlayMetrics.topInset + extraTopInset;

    final overlay = SizedBox(
      height: topInset + PdpOverlayMetrics.buttonSize,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (onBack != null)
            Positioned(
              top: topInset,
              left: PdpOverlayMetrics.edgeInset,
              child: PdpOverlayCircleButton(
                icon: iconFromName('back'),
                onPressed: onBack,
              ),
            ),
          if (showWishlistButton)
            Positioned(
              top: topInset,
              right: PdpOverlayMetrics.edgeInset,
              child: PdpOverlayCircleButton(
                icon: wishlistSelected
                    ? FluentIcons.heart_20_filled
                    : iconFromName('favorite_border'),
                iconColor:
                    wishlistSelected ? wishlistColor : const Color(0xFF212127),
                onPressed: onWishlistTap,
              ),
            ),
        ],
      ),
    );

    if (!applySafeAreaTop) return overlay;

    return SafeArea(
      bottom: false,
      child: overlay,
    );
  }
}
