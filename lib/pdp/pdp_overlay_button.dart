import 'package:flutter/material.dart';

import 'pdp_overlay_metrics.dart';

/// Circular overlay button used on PDP (back, wishlist on image, etc.).
class PdpOverlayCircleButton extends StatelessWidget {
  const PdpOverlayCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconColor = const Color(0xFF212127),
    this.enabled = true,
    this.showShadow = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color iconColor;
  final bool enabled;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: showShadow ? 1 : 0.94),
      elevation: showShadow ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          width: PdpOverlayMetrics.buttonSize,
          height: PdpOverlayMetrics.buttonSize,
          child: Icon(
            icon,
            size: PdpOverlayMetrics.iconSize,
            color: iconColor,
          ),
        ),
      ),
    );

    if (!showShadow) return button;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: button,
    );
  }
}
