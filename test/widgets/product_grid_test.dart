import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/src/responsive.dart';
import 'package:frontend_commons/src/widget_node.dart';
import 'package:frontend_commons/widgets/product_grid.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'grid row uses real card height when text is taller than its intrinsic height',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return buildProductGrid(
                  context,
                  WidgetNode(
                    type: 'product_grid',
                    props: {
                      'layoutMode': 'grid',
                      'showAddToCart': true,
                      'items': [
                        {'id': '1', 'title': 'Short'},
                        {'id': '2', 'title': 'Tall'},
                      ],
                    },
                  ),
                  AppDropBuildEnv(
                    r: R.fromConstraints(
                      context,
                      const BoxConstraints(maxWidth: 400, maxHeight: 900),
                    ),
                    renderNode: (_, node) {
                      final product = node.m('product');
                      final tall = product?['id'] == '2';
                      return _TallerThanIntrinsic(
                        child: SizedBox(height: tall ? 160 : 80),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      final buttons = find.text('Add to cart');
      expect(buttons, findsNWidgets(2));
      final first = tester.getRect(buttons.at(0));
      final second = tester.getRect(buttons.at(1));
      expect(second.bottom, closeTo(first.bottom, 0.5));
      expect(second.top, closeTo(first.top, 0.5));
      // Row hugs the cards. A full-height stretch would pin the buttons near the
      // bottom of the 900px test surface.
      expect(first.bottom, lessThan(400));
    },
  );
}

/// Reports an intrinsic height 2px shorter than the height it actually takes.
///
/// This is the mismatch [IntrinsicHeight] trips on for the first frame of a
/// store font, and for the price row's [FittedBox].
class _TallerThanIntrinsic extends SingleChildRenderObjectWidget {
  const _TallerThanIntrinsic({required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTallerThanIntrinsic();
  }
}

class _RenderTallerThanIntrinsic extends RenderProxyBox {
  @override
  double computeMinIntrinsicHeight(double width) {
    final height = super.computeMinIntrinsicHeight(width);
    return height > 2 ? height - 2 : 0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final height = super.computeMaxIntrinsicHeight(width);
    return height > 2 ? height - 2 : 0;
  }
}
