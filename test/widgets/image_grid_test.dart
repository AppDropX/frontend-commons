import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/src/responsive.dart';
import 'package:frontend_commons/src/widget_node.dart';
import 'package:frontend_commons/widgets/image_grid.dart';

void main() {
  testWidgets('image grid ignores safe-area padding under the block', (
    tester,
  ) async {
    const width = 330.0;
    const safeBottom = 24.0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(width, 690),
          padding: EdgeInsets.only(bottom: safeBottom),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: Builder(
                builder: (context) {
                  return buildImageGrid(
                    context,
                    WidgetNode(
                      type: 'image_grid',
                      props: {
                        'images': [' ', ' '],
                        'tileHeightDp': 140,
                        'spacingDp': 10,
                        'maxTileWidthDp': 140,
                        'showImageNames': false,
                      },
                    ),
                    AppDropBuildEnv(
                      r: R.fromConstraints(
                        context,
                        const BoxConstraints(maxWidth: width, maxHeight: 690),
                      ),
                      renderNode: (_, __) => const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final grid = tester.renderObject<RenderBox>(find.byType(GridView));
    final scale = width / 320;
    final imageHeight = 140 * scale;
    expect(grid.size.height, closeTo(imageHeight, 0.1));
    expect(grid.size.height, lessThan(imageHeight + safeBottom));
  });
}
