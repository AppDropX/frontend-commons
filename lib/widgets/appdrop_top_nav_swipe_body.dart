import 'package:flutter/material.dart';

/// Adds horizontal swipe-to-change-tab on top of an existing body widget.
///
/// Does not own tab state — callers pass [selectedIndex] and [onSwipeToTab],
/// which should invoke the same handler used by [AppDropTopTabs.onChanged].
class AppDropTopNavSwipeBody extends StatefulWidget {
  const AppDropTopNavSwipeBody({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.tabCount,
    required this.onSwipeToTab,
  });

  final Widget child;
  final int selectedIndex;
  final int tabCount;
  final ValueChanged<int> onSwipeToTab;

  @override
  State<AppDropTopNavSwipeBody> createState() => _AppDropTopNavSwipeBodyState();
}

class _AppDropTopNavSwipeBodyState extends State<AppDropTopNavSwipeBody>
    with SingleTickerProviderStateMixin {
  static const double _distanceThreshold = 56;
  static const double _velocityThreshold = 280;
  static const Duration _commitDuration = Duration(milliseconds: 220);

  late final AnimationController _commitController;
  Animation<double>? _commitAnimation;
  double _dragOffset = 0;
  double _panDx = 0;
  double _panDy = 0;
  bool _isHorizontalPan = false;
  bool _isCommitting = false;
  int? _pendingIndex;

  @override
  void initState() {
    super.initState();
    _commitController = AnimationController(vsync: this, duration: _commitDuration)
      ..addListener(() {
        if (_commitAnimation != null) {
          setState(() => _dragOffset = _commitAnimation!.value);
        }
      })
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        final target = _pendingIndex;
        _pendingIndex = null;
        _isCommitting = false;
        _dragOffset = 0;
        if (target != null) {
          widget.onSwipeToTab(target);
        }
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _commitController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppDropTopNavSwipeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex && !_isCommitting) {
      _dragOffset = 0;
      _resetPanTracking();
    }
  }

  bool get _canSwipe => widget.tabCount > 1;

  bool get _canSwipeToPrevious => widget.selectedIndex > 0;

  bool get _canSwipeToNext => widget.selectedIndex < widget.tabCount - 1;

  void _resetPanTracking() {
    _panDx = 0;
    _panDy = 0;
    _isHorizontalPan = false;
  }

  void _onPanStart(DragStartDetails _) {
    if (!_canSwipe || _isCommitting) return;
    _resetPanTracking();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_canSwipe || _isCommitting) return;

    _panDx += details.delta.dx;
    _panDy += details.delta.dy;

    if (!_isHorizontalPan) {
      final absDx = _panDx.abs();
      final absDy = _panDy.abs();
      if (absDx < 8 && absDy < 8) return;
      if (absDx <= absDy) return;
      _isHorizontalPan = true;
    }

    var nextOffset = _dragOffset + details.delta.dx;
    if (!_canSwipeToPrevious && nextOffset > 0) {
      nextOffset *= 0.35;
    }
    if (!_canSwipeToNext && nextOffset < 0) {
      nextOffset *= 0.35;
    }
    setState(() => _dragOffset = nextOffset);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_canSwipe || _isCommitting || !_isHorizontalPan) {
      _resetPanTracking();
      _snapBack();
      return;
    }

    final velocity = details.velocity.pixelsPerSecond.dx;
    final width = MediaQuery.sizeOf(context).width;

    int? target;
    if (_canSwipeToNext &&
        (_dragOffset <= -_distanceThreshold || velocity <= -_velocityThreshold)) {
      target = widget.selectedIndex + 1;
    } else if (_canSwipeToPrevious &&
        (_dragOffset >= _distanceThreshold || velocity >= _velocityThreshold)) {
      target = widget.selectedIndex - 1;
    }

    _resetPanTracking();

    if (target == null) {
      _snapBack();
      return;
    }

    _commitSwipe(target, width);
  }

  void _onPanCancel() {
    _resetPanTracking();
    _snapBack();
  }

  void _snapBack() {
    if (_dragOffset == 0 || _isCommitting) return;
    final begin = _dragOffset;
    _commitAnimation = Tween<double>(begin: begin, end: 0).animate(
      CurvedAnimation(parent: _commitController, curve: Curves.easeOut),
    );
    _isCommitting = true;
    _pendingIndex = null;
    _commitController
      ..reset()
      ..forward();
  }

  void _commitSwipe(int targetIndex, double width) {
    final sign = targetIndex > widget.selectedIndex ? -1.0 : 1.0;
    final begin = _dragOffset;
    final end = sign * width;
    _pendingIndex = targetIndex;
    _commitAnimation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _commitController, curve: Curves.easeOutCubic),
    );
    _isCommitting = true;
    _commitController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canSwipe) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: _commitDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: Transform.translate(
            key: ValueKey<int>(widget.selectedIndex),
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
