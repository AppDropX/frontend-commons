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
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color iconColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      elevation: 2,
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
  }
}
