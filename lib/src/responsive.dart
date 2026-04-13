import 'package:flutter/widgets.dart';

class R {
  final double w;
  final double h;
  final double scale;

  const R._(this.w, this.h, this.scale);

  static R fromConstraints(BuildContext context, BoxConstraints c, {double baseWidth = 320}) {
    final width = c.maxWidth.isFinite ? c.maxWidth : MediaQuery.of(context).size.width;
    final height = c.maxHeight.isFinite ? c.maxHeight : MediaQuery.of(context).size.height;
    final s = width / baseWidth;
    return R._(width, height, s);
  }

  double dp(num v) => v.toDouble() * scale;
  double sp(num v, {num min = 10, num max = 26}) {
    final minD = min.toDouble();
    final maxD = max.toDouble();
    final val = v.toDouble() * scale;
    if (val < minD) return minD;
    if (val > maxD) return maxD;
    return val;
  }
}
