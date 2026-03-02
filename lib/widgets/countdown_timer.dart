import 'dart:async';
import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';

Widget buildCountdownTimer(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  return _CountdownTimerDisplay(node: node, env: env);
}

class _CountdownTimerDisplay extends StatefulWidget {
  const _CountdownTimerDisplay({required this.node, required this.env});

  final WidgetNode node;
  final AppDropBuildEnv env;

  @override
  State<_CountdownTimerDisplay> createState() => _CountdownTimerDisplayState();
}

class _CountdownTimerDisplayState extends State<_CountdownTimerDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _parseTarget() {
    final dateStr = widget.node.s('targetDate', def: '');
    final timeStr = widget.node.s('targetTime', def: '00:00');
    if (dateStr.isEmpty) return null;
    final dateParts = dateStr.split('-');
    if (dateParts.length != 3) return null;
    final timeParts = timeStr.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    if (year == null || month == null || day == null) return null;
    try {
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.node.b('enabled', def: true);
    if (!enabled) return const SizedBox.shrink();

    final target = _parseTarget();
    final r = widget.env.r;
    final bgColor = parseHexColor(widget.node.s('bgColor', def: '#1F2937')) ?? const Color(0xFF1F2937);
    final timerColor = parseHexColor(widget.node.s('timerColor', def: '#FFFFFF')) ?? const Color(0xFFFFFFFF);
    final showImageOption = widget.node.b('showImageOption', def: true);
    final imageUrl = widget.node.s('imageUrl', def: '');
    final now = DateTime.now();
    final isComplete = target == null || !now.isBefore(target);
    final remaining = target != null && now.isBefore(target) ? target.difference(now) : Duration.zero;

    Widget content;
    if (isComplete) {
      // Only show image when toggle is ON and URL is set
      if (showImageOption && imageUrl.isNotEmpty) {
        content = ClipRRect(
          borderRadius: BorderRadius.circular(r.dp(12)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
          ),
        );
      } else {
        content = Center(
          child: DefaultTextStyle(
            style: TextStyle(color: timerColor, fontSize: r.sp(16), fontWeight: FontWeight.w600),
            child: Text('Complete'),
          ),
        );
      }
    } else {
      final days = remaining.inDays;
      final hours = remaining.inHours % 24;
      final minutes = remaining.inMinutes % 60;
      final seconds = remaining.inSeconds % 60;
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TimeUnit(value: days, label: 'D', color: timerColor, r: r),
          _TimeUnit(value: hours, label: 'H', color: timerColor, r: r),
          _TimeUnit(value: minutes, label: 'M', color: timerColor, r: r),
          _TimeUnit(value: seconds, label: 'S', color: timerColor, r: r),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: r.dp(16), horizontal: r.dp(12)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(r.dp(12)),
      ),
      child: content,
    );
  }
}

class _TimeUnit extends StatelessWidget {
  const _TimeUnit({
    required this.value,
    required this.label,
    required this.color,
    required this.r,
  });

  final int value;
  final String label;
  final Color color;
  final R r;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.dp(6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              color: color,
              fontSize: r.sp(24),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: r.dp(2)),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: r.sp(11),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
