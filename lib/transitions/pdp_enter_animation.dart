import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Stagger order for PDP content after the route transition completes.
enum PdpStaggerSlot {
  image,
  title,
  price,
  description,
  addToCart,
}

/// Inherited flag set on PDP scroll content so block builders can stagger in.
class PdpEnterAnimationScope extends InheritedWidget {
  const PdpEnterAnimationScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static PdpEnterAnimationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PdpEnterAnimationScope>();
  }

  static bool isEnabled(BuildContext context) {
    return maybeOf(context)?.enabled ?? false;
  }

  @override
  bool updateShouldNotify(PdpEnterAnimationScope oldWidget) {
    return oldWidget.enabled != enabled;
  }
}

/// Applies a short fade + slide-up with slot-based delay (no bounce).
Widget wrapPdpStagger(
  BuildContext context,
  PdpStaggerSlot slot,
  Widget content,
) {
  if (!PdpEnterAnimationScope.isEnabled(context)) return content;

  final delayMs = _delayMs(slot);
  return Animate(
    delay: Duration(milliseconds: delayMs),
    effects: const [
      FadeEffect(
        duration: Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ),
      SlideEffect(
        begin: Offset(0, 0.06),
        end: Offset.zero,
        duration: Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      ),
    ],
    child: content,
  );
}

int _delayMs(PdpStaggerSlot slot) {
  switch (slot) {
    case PdpStaggerSlot.image:
      return 0;
    case PdpStaggerSlot.title:
      return 70;
    case PdpStaggerSlot.price:
      return 140;
    case PdpStaggerSlot.description:
      return 210;
    case PdpStaggerSlot.addToCart:
      return 280;
  }
}

/// Maps CMS `pdpStaggerSlot` string props on generic blocks (e.g. `text`).
PdpStaggerSlot? pdpStaggerSlotFromString(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'image':
      return PdpStaggerSlot.image;
    case 'title':
      return PdpStaggerSlot.title;
    case 'price':
      return PdpStaggerSlot.price;
    case 'description':
      return PdpStaggerSlot.description;
    case 'add_to_cart':
    case 'addtocart':
      return PdpStaggerSlot.addToCart;
    default:
      return null;
  }
}
