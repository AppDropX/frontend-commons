import 'package:flutter/widgets.dart';

class R {
  final double w;
  final double h;
  final double scale;

  const R._(this.w, this.h, this.scale);

  static R fromConstraints(BuildContext context, BoxConstraints c, {double baseWidth = 390}) {
    final width = c.maxWidth.isFinite ? c.maxWidth : MediaQuery.of(context).size.width;
    final height = c.maxHeight.isFinite ? c.maxHeight : MediaQuery.of(context).size.height;
    final s = width / baseWidth;
    return R._(width, height, s);
  }

  double dp(num v) => v.toDouble() * scale;
  double sp(num v, {double min = 10, double max = 26}) {
    final val = v.toDouble() * scale;
    if (val < min) return min;
    if (val > max) return max;
    return val;
  }
}
