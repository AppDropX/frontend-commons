import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Preview [ScrollController] used to bring a selected block on screen.
///
/// Must wrap only the device-preview scroll view so the builder admin page is
/// not scrolled with [Scrollable.ensureVisible]'s ancestor walk.
class PreviewBlockScrollScope extends InheritedWidget {
  const PreviewBlockScrollScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ScrollController controller;

  static PreviewBlockScrollScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<PreviewBlockScrollScope>();
  }

  @override
  bool updateShouldNotify(PreviewBlockScrollScope oldWidget) {
    return oldWidget.controller != controller;
  }
}

/// Marks a rendered CMS block so the theme builder can scroll it into view.
class PreviewBlockAnchor extends StatefulWidget {
  const PreviewBlockAnchor({
    super.key,
    required this.blockId,
    required this.scrollToBlockId,
    required this.child,
    this.scrollGeneration = 0,
    this.layoutSignature = '',
  });

  final String blockId;
  final String? scrollToBlockId;
  final Widget child;

  /// Bumped on re-select / reorder so an already-selected block scrolls again.
  final int scrollGeneration;

  /// Block order fingerprint. Changes when the selected block is moved.
  final String layoutSignature;

  @override
  State<PreviewBlockAnchor> createState() => _PreviewBlockAnchorState();
}

class _PreviewBlockAnchorState extends State<PreviewBlockAnchor> {
  int _scrollGen = 0;

  bool get _isSelected =>
      widget.scrollToBlockId == widget.blockId && widget.blockId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isSelected) {
      _scheduleScroll();
    }
  }

  @override
  void didUpdateWidget(covariant PreviewBlockAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSelected) {
      _scrollGen++;
      return;
    }
    final becameSelected = oldWidget.scrollToBlockId != widget.blockId;
    final generationChanged =
        oldWidget.scrollGeneration != widget.scrollGeneration;
    final orderChanged = oldWidget.layoutSignature != widget.layoutSignature;
    if (becameSelected || generationChanged || orderChanged) {
      _scheduleScroll();
    }
  }

  void _scheduleScroll() {
    final gen = ++_scrollGen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _scrollGen || !_isSelected) return;
      _startSingleScroll(gen, retries: 0);
    });
  }

  void _startSingleScroll(int gen, {required int retries}) {
    final measured = _measureTarget();
    if (measured == null) {
      if (retries < 4) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || gen != _scrollGen || !_isSelected) return;
          _startSingleScroll(gen, retries: retries + 1);
        });
      }
      return;
    }

    final controller = measured.controller;
    final target = measured.target;
    if ((target - controller.offset).abs() < 0.5) return;

    final distance = (target - controller.offset).abs();
    controller.animateTo(
      target,
      duration: _durationForDistance(distance, measured.viewportExtent),
      curve: Curves.easeInOutCubic,
    ).whenComplete(() {
      if (!mounted || gen != _scrollGen || !_isSelected) return;
      if (!controller.hasClients) return;
      final again = _measureTarget();
      if (again == null) return;
      if ((again.target - controller.offset).abs() <= 16) return;
      controller.animateTo(
        again.target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Duration _durationForDistance(double distance, double viewportExtent) {
    final span = viewportExtent <= 0 ? 400.0 : viewportExtent;
    final t = (distance / (span * 2.5)).clamp(0.0, 1.0);
    final ms = 320 + (380 * t);
    return Duration(milliseconds: ms.round());
  }

  _MeasuredScrollTarget? _measureTarget() {
    final controller = PreviewBlockScrollScope.maybeOf(context)?.controller;
    if (controller == null || !controller.hasClients) return null;

    final block = context.findRenderObject();
    if (block is! RenderBox || !block.hasSize) return null;

    final viewport = RenderAbstractViewport.maybeOf(block);
    if (viewport == null) return null;

    final position = controller.position;
    if (!position.hasContentDimensions || !position.hasViewportDimension) {
      return null;
    }

    final target = viewport.getOffsetToReveal(block, 0).offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    return _MeasuredScrollTarget(
      controller: controller,
      target: target,
      viewportExtent: position.viewportDimension,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MeasuredScrollTarget {
  const _MeasuredScrollTarget({
    required this.controller,
    required this.target,
    required this.viewportExtent,
  });

  final ScrollController controller;
  final double target;
  final double viewportExtent;
}
