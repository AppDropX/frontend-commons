import 'package:flutter/material.dart';

/// Animated heart toggle used on product cards and cart rows.
class WishlistHeartButton extends StatefulWidget {
  const WishlistHeartButton({
    super.key,
    required this.isWishlisted,
    required this.activeColor,
    required this.size,
    this.inactiveColor,
    this.onTap,
    this.padding = const EdgeInsets.all(2),
    this.showBackground = false,
    this.backgroundColor,
    this.borderRadius = 4,
  });

  final bool isWishlisted;
  final Color activeColor;
  final Color? inactiveColor;
  final double size;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showBackground;
  final Color? backgroundColor;
  final double borderRadius;

  @override
  State<WishlistHeartButton> createState() => _WishlistHeartButtonState();
}

class _WishlistHeartButtonState extends State<WishlistHeartButton>
    with TickerProviderStateMixin {
  late final AnimationController _fillController;
  late final AnimationController _ringController;

  late final Animation<double> _fillScale;
  late final Animation<double> _outlineOpacity;
  late final Animation<double> _outlineScale;
  late final Animation<double> _filledOpacity;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );

    _fillScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.elasticOut),
    );

    _outlineOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: const Interval(0.0, 0.48, curve: Curves.easeInCubic),
      ),
    );

    _outlineScale = Tween<double>(begin: 1.0, end: 0.68).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: const Interval(0.0, 0.52, curve: Curves.easeInCubic),
      ),
    );

    _filledOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: const Interval(0.14, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _ringScale = Tween<double>(begin: 0.5, end: 2.25).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );

    _ringOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.42), weight: 22),
      TweenSequenceItem(tween: Tween(begin: 0.42, end: 0.0), weight: 78),
    ]).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    if (widget.isWishlisted) {
      _fillController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(WishlistHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isWishlisted && widget.isWishlisted) {
      _playFill();
    } else if (oldWidget.isWishlisted && !widget.isWishlisted) {
      _snapToOutline();
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _playFill() {
    if (_fillController.value >= 1.0) return;
    if (_fillController.isAnimating &&
        _fillController.status == AnimationStatus.forward) {
      return;
    }
    _ringController.forward(from: 0);
    _fillController.forward(from: _fillController.value);
  }

  /// Instant switch back to outline (no reverse animation).
  void _snapToOutline() {
    _ringController.stop();
    _fillController.stop();
    _ringController.value = 0;
    _fillController.value = 0;
  }

  void _handleTap() {
    if (!widget.isWishlisted) {
      _playFill();
    } else {
      _snapToOutline();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final inactive = widget.inactiveColor ?? Colors.grey.shade600;
    final layoutSize = widget.size + 4;
    final canvas = widget.size * 2.35;

    Widget heart = SizedBox(
      width: layoutSize,
      height: layoutSize,
      child: OverflowBox(
        maxWidth: canvas,
        maxHeight: canvas,
        alignment: Alignment.center,
        child: SizedBox(
          width: canvas,
          height: canvas,
          child: AnimatedBuilder(
            animation: Listenable.merge([_fillController, _ringController]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: _ringOpacity.value,
                    child: Transform.scale(
                      scale: _ringScale.value,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.activeColor.withValues(alpha: 0.18),
                          border: Border.all(
                            color: widget.activeColor.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: _outlineOpacity.value,
                    child: Transform.scale(
                      scale: _outlineScale.value,
                      child: Icon(
                        Icons.favorite_border,
                        size: widget.size,
                        color: inactive,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: _filledOpacity.value,
                    child: Transform.scale(
                      scale: _fillScale.value,
                      child: Icon(
                        Icons.favorite,
                        size: widget.size,
                        color: widget.activeColor,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    Widget content = Padding(padding: widget.padding, child: heart);

    if (widget.onTap == null) return content;

    if (widget.showBackground) {
      return Material(
        color: widget.backgroundColor ?? Colors.white.withValues(alpha: 0.86),
        shape: const CircleBorder(),
        clipBehavior: Clip.none,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleTap,
          child: content,
        ),
      );
    }

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: content,
    );
  }
}
