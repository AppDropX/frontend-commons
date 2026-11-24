import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/widgets/preview_block_anchor.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required ScrollController controller,
    required List<String> ids,
    required String? scrollToBlockId,
    int scrollGeneration = 0,
  }) {
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _Host(
          controller: controller,
          ids: ids,
          scrollToBlockId: scrollToBlockId,
          scrollGeneration: scrollGeneration,
        ),
      ),
    );
  }

  testWidgets('scrolls the selected block to the top of the viewport', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpHost(
      tester,
      controller: controller,
      ids: const ['a', 'b'],
      scrollToBlockId: null,
    );
    expect(controller.position.maxScrollExtent, greaterThan(0));
    expect(
      tester.getTopLeft(find.text('block-b', skipOffstage: false)).dy,
      250,
    );

    await pumpHost(
      tester,
      controller: controller,
      ids: const ['a', 'b'],
      scrollToBlockId: 'b',
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('block-b')).dy, closeTo(0, 1));
  });

  testWidgets('reorder of the selected block scrolls it back to the top', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpHost(
      tester,
      controller: controller,
      ids: const ['a', 'b', 'c'],
      scrollToBlockId: 'c',
      scrollGeneration: 1,
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('block-c')).dy, closeTo(0, 1));
    expect(controller.offset, greaterThan(100));

    await pumpHost(
      tester,
      controller: controller,
      ids: const ['c', 'a', 'b'],
      scrollToBlockId: 'c',
      scrollGeneration: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('block-c')).dy, closeTo(0, 1));
    expect(controller.offset, closeTo(0, 1));
  });

  testWidgets('new scroll generation re-scrolls an already selected block', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpHost(
      tester,
      controller: controller,
      ids: const ['a', 'b'],
      scrollToBlockId: 'b',
      scrollGeneration: 1,
    );
    await tester.pumpAndSettle();
    controller.jumpTo(0);
    await tester.pump();
    expect(tester.getTopLeft(find.text('block-b', skipOffstage: false)).dy, 250);

    await pumpHost(
      tester,
      controller: controller,
      ids: const ['a', 'b'],
      scrollToBlockId: 'b',
      scrollGeneration: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('block-b')).dy, closeTo(0, 1));
  });
}

class _Host extends StatelessWidget {
  const _Host({
    required this.controller,
    required this.ids,
    required this.scrollToBlockId,
    this.scrollGeneration = 0,
  });

  final ScrollController controller;
  final List<String> ids;
  final String? scrollToBlockId;
  final int scrollGeneration;

  @override
  Widget build(BuildContext context) {
    final layoutSignature = ids.join('|');
    return PreviewBlockScrollScope(
      controller: controller,
      child: SizedBox(
        width: 400,
        height: 200,
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              for (final id in ids)
                PreviewBlockAnchor(
                  key: ValueKey<String>(id),
                  blockId: id,
                  scrollToBlockId: scrollToBlockId,
                  scrollGeneration: scrollGeneration,
                  layoutSignature: layoutSignature,
                  child: SizedBox(height: 250, child: Text('block-$id')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
