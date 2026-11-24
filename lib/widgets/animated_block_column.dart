import 'package:flutter/widgets.dart';

/// One keyed child in [AnimatedBlockColumn].
class AnimatedBlockItem {
  const AnimatedBlockItem({required this.id, required this.child});

  final String id;
  final Widget child;
}

/// Column that expands / collapses children when the keyed list changes.
///
/// First layout is not animated so page switches stay instant. Later inserts
/// fade and grow in; removals fade and shrink out.
class AnimatedBlockColumn extends StatefulWidget {
  const AnimatedBlockColumn({
    super.key,
    required this.items,
    this.duration = kDefaultBlockChangeDuration,
    this.curve = Curves.easeOutCubic,
  });

  static const Duration kDefaultBlockChangeDuration = Duration(milliseconds: 280);

  final List<AnimatedBlockItem> items;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedBlockColumn> createState() => _AnimatedBlockColumnState();
}

class _Slot {
  _Slot({
    required this.id,
    required this.child,
    required this.controller,
    required this.animation,
    this.outgoing = false,
  });

  final String id;
  Widget child;
  final AnimationController controller;
  final CurvedAnimation animation;
  bool outgoing;

  void dispose() {
    animation.dispose();
    controller.dispose();
  }
}

class _AnimatedBlockColumnState extends State<AnimatedBlockColumn>
    with TickerProviderStateMixin {
  late List<_Slot> _slots;

  @override
  void initState() {
    super.initState();
    _slots = [
      for (final item in widget.items) _createSlot(item, expanded: true),
    ];
  }

  @override
  void didUpdateWidget(covariant AnimatedBlockColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      for (final slot in _slots) {
        slot.controller.duration = widget.duration;
      }
    }
    _reconcile(widget.items);
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      slot.dispose();
    }
    super.dispose();
  }

  _Slot _createSlot(AnimatedBlockItem item, {required bool expanded}) {
    final controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: expanded ? 1 : 0,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: widget.curve,
      reverseCurve: Curves.easeInCubic,
    );
    if (!expanded) {
      controller.forward();
    }
    return _Slot(
      id: item.id,
      child: item.child,
      controller: controller,
      animation: animation,
    );
  }

  void _onExitComplete(_Slot slot) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_slots.contains(slot) || !slot.outgoing) return;
      setState(() => _slots.remove(slot));
      slot.dispose();
    });
  }

  void _reconcile(List<AnimatedBlockItem> next) {
    final existing = <String, _Slot>{
      for (final slot in _slots) slot.id: slot,
    };
    final result = <_Slot>[];
    final kept = <String>{};

    for (final item in next) {
      final prev = existing[item.id];
      if (prev != null) {
        prev.child = item.child;
        if (prev.outgoing) {
          prev.outgoing = false;
          prev.controller.forward();
        }
        result.add(prev);
        kept.add(item.id);
      } else {
        result.add(_createSlot(item, expanded: false));
        kept.add(item.id);
      }
    }

    for (final leaving in _slots) {
      if (kept.contains(leaving.id)) continue;
      if (!leaving.outgoing) {
        leaving.outgoing = true;
        leaving.controller.addStatusListener((status) {
          if (status == AnimationStatus.dismissed) {
            _onExitComplete(leaving);
          }
        });
        leaving.controller.reverse();
      }
      final insertAt = _outgoingIndex(leaving, result);
      result.insert(insertAt, leaving);
    }

    _slots = result;
  }

  int _outgoingIndex(_Slot leaving, List<_Slot> result) {
    final oldIndex = _slots.indexOf(leaving);
    for (var j = oldIndex + 1; j < _slots.length; j++) {
      final neighbor = _slots[j];
      final idx = result.indexWhere((s) => s.id == neighbor.id && !s.outgoing);
      if (idx >= 0) return idx;
    }
    return result.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final slot in _slots)
          _AnimatedBlockSlot(
            key: ValueKey<String>(slot.id),
            animation: slot.animation,
            child: slot.child,
          ),
      ],
    );
  }
}

class _AnimatedBlockSlot extends StatelessWidget {
  const _AnimatedBlockSlot({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}
