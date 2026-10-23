import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/src/responsive.dart';
import 'package:frontend_commons/src/widget_node.dart';
import 'package:frontend_commons/widgets/pdp_product_image_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const product = {
    'title': 'Wallet',
    'imageUrl': 'https://example.com/one.jpg',
    'images': [
      'https://example.com/one.jpg',
      'https://example.com/two.jpg',
    ],
  };

  Widget host(Map<String, dynamic> props) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: Builder(
              builder: (context) {
                return buildPdpProductImageBlock(
                  context,
                  WidgetNode(type: 'pdp_product_image', props: props),
                  AppDropBuildEnv(
                    r: R.fromConstraints(
                      context,
                      const BoxConstraints(maxWidth: 320, maxHeight: 700),
                    ),
                    renderNode: (_, __) => const SizedBox.shrink(),
                    interactiveFeaturesEnabled: false,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Size _paintedSize(WidgetTester tester, Container dot) {
    final rendered = tester.renderObject<RenderBox>(find.byWidget(dot)).size;
    final margin = dot.margin;
    if (margin is! EdgeInsets) return rendered;
    return Size(
      rendered.width - margin.horizontal,
      rendered.height - margin.vertical,
    );
  }

  List<Container> dottedIndicators(WidgetTester tester) {
    return tester
        .widgetList<Container>(find.byType(Container))
        .where((container) {
          final decoration = container.decoration;
          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle &&
              container.margin != null;
        })
        .toList();
  }

  testWidgets('indicator dots are plain circles', (tester) async {
    await tester.pumpWidget(
      host({
        'gallery_style': 'indicator',
        'gallery_size': 'portrait',
        'indicator_color': '#FFFFFF',
        'product': product,
      }),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Product image 1'), findsNothing);

    final dots = dottedIndicators(tester);
    expect(dots, hasLength(2));

    final sizes = dots.map((dot) => _paintedSize(tester, dot)).toList();
    expect(sizes, contains(const Size(8, 8)));
    expect(sizes, contains(const Size(6, 6)));

    for (final dot in dots) {
      final decoration = dot.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNull);
      expect(decoration.border, isNull);
      expect(decoration.shape, BoxShape.circle);
    }
  });

  testWidgets('thumbnails sit under the image and border the selected one', (
    tester,
  ) async {
    await tester.pumpWidget(
      host({
        'gallery_style': 'thumbnails',
        'gallery_size': 'portrait',
        'thumbnail_border_color': '#FF6A00',
        'product': product,
      }),
    );
    await tester.pump();

    expect(dottedIndicators(tester), isEmpty);
    expect(find.bySemanticsLabel('Product image 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Product image 2'), findsOneWidget);

    final thumbs = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    expect(thumbs, hasLength(2));
    final firstSize = tester
        .renderObject<RenderBox>(find.byWidget(thumbs.first))
        .size;
    expect(firstSize, const Size(68, 92));

    final imageBottom = tester.getBottomLeft(find.byType(PageView)).dy;
    final firstThumb = tester.getTopLeft(find.bySemanticsLabel('Product image 1'));
    final secondThumb = tester.getTopLeft(find.bySemanticsLabel('Product image 2'));
    expect(firstThumb.dy - imageBottom, closeTo(8, 0.5));
    expect(secondThumb.dx, closeTo(firstThumb.dx + firstSize.width + 8, 0.5));

    BoxDecoration borderOf(AnimatedContainer container) {
      final decoration = container.foregroundDecoration;
      expect(decoration, isA<BoxDecoration>());
      return decoration as BoxDecoration;
    }

    expect(borderOf(thumbs.first).border!.top.color, const Color(0xFFFF6A00));
    expect(borderOf(thumbs.last).border!.top.color, Colors.transparent);

    await tester.tap(find.bySemanticsLabel('Product image 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final updated = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    expect(borderOf(updated.first).border!.top.color, Colors.transparent);
    expect(borderOf(updated.last).border!.top.color, const Color(0xFFFF6A00));
  });

  testWidgets('remove spacing toggle closes both thumbnail gaps', (tester) async {
    await tester.pumpWidget(
      host({
        'gallery_style': 'thumbnails',
        'gallery_size': 'portrait',
        'remove_thumbnail_spacing': true,
        'product': product,
      }),
    );
    await tester.pump();

    final firstSize = tester
        .renderObject<RenderBox>(
          find.byWidget(
            tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).first,
          ),
        )
        .size;
    final imageBottom = tester.getBottomLeft(find.byType(PageView)).dy;
    final firstThumb = tester.getTopLeft(find.bySemanticsLabel('Product image 1'));
    final secondThumb = tester.getTopLeft(find.bySemanticsLabel('Product image 2'));
    expect(firstThumb.dy - imageBottom, closeTo(0, 0.5));
    expect(secondThumb.dx, closeTo(firstThumb.dx + firstSize.width, 0.5));
  });
}
