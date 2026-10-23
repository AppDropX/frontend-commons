import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/src/responsive.dart';
import 'package:frontend_commons/src/widget_node.dart';
import 'package:frontend_commons/utils/media_redirect.dart';
import 'package:frontend_commons/widgets/expandable_info.dart';

void main() {
  test('redirect accepts a string flag and snake_case ids', () {
    expect(
      actionFromMediaRedirect({
        'enabled': 'true',
        'kind': 'product',
        'product_id': 'belt-1',
      }),
      {'type': 'open_product', 'productId': 'belt-1'},
    );
  });

  test('a JSON string redirect on a section is kept', () {
    final sections = parseExpandableInfoSections([
      {
        'title': 'Care',
        'body': 'Dry clean',
        'redirect': '{"enabled":true,"kind":"page","pageId":"about"}',
      },
    ]);

    expect(
      actionFromMediaRedirect(sections.single.redirect),
      {'type': 'open_page', 'pageId': 'about'},
    );
  });

  testWidgets('tapping expanded content follows the section redirect', (
    tester,
  ) async {
    final tapped = await _tapBody(
      tester,
      sections: [
        {
          'title': 'Shipping',
          'body': 'Ships in 4 days',
          'redirect': {
            'enabled': 'true',
            'kind': 'collection',
            'collection_id': 'belts',
          },
        },
      ],
    );

    expect(tapped?['type'], 'open_collection');
    expect(tapped?['collection'], 'belts');
  });

  testWidgets('content uses the block redirect when the section has none', (
    tester,
  ) async {
    final tapped = await _tapBody(
      tester,
      blockRedirect: {
        'enabled': true,
        'kind': 'url',
        'url': 'https://example.com/care',
        'urlScope': 'external',
      },
      sections: [
        {
          'title': 'Care',
          'body': 'Dry clean only',
          'redirect': {'enabled': false, 'kind': 'collection'},
        },
      ],
    );

    expect(tapped?['type'], 'open_url_external');
    expect(tapped?['url'], 'https://example.com/care');
  });

  testWidgets('a disabled redirect does not navigate', (tester) async {
    final tapped = await _tapBody(
      tester,
      sections: [
        {
          'title': 'Brand',
          'body': 'Our story',
          'redirect': {'enabled': false, 'kind': 'page', 'pageId': 'about'},
        },
      ],
    );

    expect(tapped, isNull);
  });
}

Future<Map<String, dynamic>?> _tapBody(
  WidgetTester tester, {
  required List<Map<String, dynamic>> sections,
  Map<String, dynamic>? blockRedirect,
}) async {
  Map<String, dynamic>? tapped;
  const width = 330.0;
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(width, 690)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: Builder(
              builder: (context) {
                return buildExpandableInfo(
                  context,
                  WidgetNode(
                    type: 'expandable_info',
                    props: {
                      if (blockRedirect != null) 'redirect': blockRedirect,
                      'sections': [
                        for (final section in sections)
                          {...section, 'defaultExpanded': true},
                      ],
                    },
                  ),
                  AppDropBuildEnv(
                    r: R.fromConstraints(
                      context,
                      const BoxConstraints(maxWidth: width, maxHeight: 690),
                    ),
                    renderNode: (_, __) => const SizedBox.shrink(),
                    onAction: (_, action) => tapped = action,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text(sections.first['body']!.toString()));
  await tester.pump();
  return tapped;
}
