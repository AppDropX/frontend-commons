import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/pdp/pdp_page_enrichment.dart';
import 'package:frontend_commons/src/responsive.dart';
import 'package:frontend_commons/widgets/product_html_description.dart';

void main() {
  test('product description keeps catalog html', () {
    final blocks = enrichPdpBlocksWithProduct(
      [
        {'type': 'product_description', 'description': 'Fallback copy'},
      ],
      {
        'description': '<p>Hello</p><ul><li>One</li></ul>',
      },
    );
    expect(blocks.single['description'], '<p>Hello</p><ul><li>One</li></ul>');
  });

  testWidgets('renders paragraphs, bullets, and bold', (tester) async {
    const html = '''
<p>Expertly crafted in India, this sling is a travel companion.</p>
<ul>
<li><strong>Stylish Tan Leather: </strong>Tan-colored buffalo leather.</li>
<li style="font-weight: bold;"><strong>Size: 9H x 11W Inch</strong></li>
</ul>
''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              return ProductHtmlDescription(
                html: html,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
                r: R.fromConstraints(context, constraints),
              );
            },
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Expertly crafted in India'),
      findsOneWidget,
    );
    expect(find.text('•'), findsNWidgets(2));

    final leather = _spanContaining('Stylish Tan Leather:');
    expect(leather, isNotNull);
    expect(leather!.style?.fontWeight, FontWeight.w700);

    final rest = _spanContaining('Tan-colored buffalo leather.');
    expect(rest, isNotNull);
    expect(rest!.style?.fontWeight, FontWeight.w400);

    final size = _spanContaining('Size: 9H x 11W Inch');
    expect(size, isNotNull);
    expect(size!.style?.fontWeight, FontWeight.w700);
  });
}

TextSpan? _spanContaining(String needle) {
  TextSpan? found;
  void walk(InlineSpan span) {
    if (found != null) return;
    if (span is TextSpan) {
      final text = span.text ?? '';
      if (text.contains(needle)) {
        found = span;
        return;
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        walk(child);
      }
    }
  }

  for (final text
      in find.byType(Text).evaluate().map((e) => e.widget as Text)) {
    final root = text.textSpan;
    if (root == null) continue;
    walk(root);
    if (found != null) return found;
  }
  return found;
}
