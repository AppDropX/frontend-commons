import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/src/widget_node.dart';
import 'package:frontend_commons/widgets/animated_block_column.dart';

void main() {
  test('WidgetNode.fromJson keeps the block id', () {
    final node = WidgetNode.fromJson({
      'id': 'banner-1',
      'type': 'image_banner',
      'url': 'https://example.com/a.png',
    });
    expect(node.id, 'banner-1');
    expect(node.type, 'image_banner');
    expect(node.props.containsKey('id'), isFalse);
  });

  testWidgets('first paint shows items immediately', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedBlockColumn(
          items: const [
            AnimatedBlockItem(id: 'a', child: Text('Alpha')),
          ],
        ),
      ),
    );
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('insert expands then shows the new block', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: _Host(ids: ['a']),
      ),
    );
    expect(find.text('block-a'), findsOneWidget);
    expect(find.text('block-b'), findsNothing);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: _Host(ids: ['a', 'b']),
      ),
    );
    await tester.pump();
    await tester.pump(AnimatedBlockColumn.kDefaultBlockChangeDuration);
    expect(find.text('block-a'), findsOneWidget);
    expect(find.text('block-b'), findsOneWidget);
  });

  testWidgets('remove collapses then drops the block', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: _Host(ids: ['a', 'b']),
      ),
    );
    expect(find.text('block-b'), findsOneWidget);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: _Host(ids: ['a']),
      ),
    );
    expect(find.text('block-b'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('block-a'), findsOneWidget);
    expect(find.text('block-b'), findsNothing);
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    return AnimatedBlockColumn(
      items: [
        for (final id in ids)
          AnimatedBlockItem(id: id, child: Text('block-$id')),
      ],
    );
  }
}
