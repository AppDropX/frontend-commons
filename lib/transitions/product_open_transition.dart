import 'package:flutter/material.dart';

/// Duration for PLP → PDP navigation (Blinkit / Zepto style: ~half second).
const Duration kProductOpenTransitionDuration = Duration(milliseconds: 500);

/// Shared ease curve for forward and reverse product open transitions.
const Curve kProductOpenTransitionCurve = Curves.easeInOut;

/// Builds the fade + slight upward slide used when opening/closing product detail.
Widget productOpenTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: kProductOpenTransitionCurve,
    reverseCurve: kProductOpenTransitionCurve,
  );

  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.035),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// [Page] that uses [PageRouteBuilder] instead of the platform default slide.
///
/// Use with go_router `pageBuilder` for `/products/:productId`.
class ProductOpenPage extends Page<void> {
  const ProductOpenPage({
    required this.child,
    super.key,
    this.transitionDuration = kProductOpenTransitionDuration,
    this.reverseTransitionDuration = kProductOpenTransitionDuration,
  });

  final Widget child;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: productOpenTransitionBuilder,
    );
  }
}
