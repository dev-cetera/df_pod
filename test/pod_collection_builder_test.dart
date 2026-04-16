// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:df_pod/df_pod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PodCollectionBuilder', () {
    testWidgets('rebuilds when source pod fires', (tester) async {
      final source = Pod<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PodCollectionBuilder(
            source: source,
            innerPods: () => const [],
            builder: (_) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      source.set(1);
      await tester.pump();
      expect(buildCount, 2);

      source.set(2);
      await tester.pump();
      expect(buildCount, 3);
    });

    testWidgets('subscribes to inner pods returned at mount', (tester) async {
      final source = Pod<int>(0);
      final inner = Pod<String>('a');
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PodCollectionBuilder(
            source: source,
            innerPods: () => [inner],
            builder: (_) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      // Firing an inner pod rebuilds without source changing.
      inner.set('b');
      await tester.pump();
      expect(buildCount, 2);

    });

    testWidgets(
      'dynamically attaches and detaches inner pods when source fires',
      (tester) async {
        final source = Pod<List<Pod<int>>>([]);
        final p1 = Pod<int>(10);
        final p2 = Pod<int>(20);
        var buildCount = 0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: PodCollectionBuilder(
              source: source,
              innerPods: () => source.getValue(),
              builder: (_) {
                buildCount++;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(buildCount, 1);

        // Initially no inner pods — firing p1 should NOT rebuild.
        p1.set(11);
        await tester.pump();
        expect(buildCount, 1);

        // Add p1 to the source list — rebuilds once for source change.
        source.set([p1]);
        await tester.pump();
        expect(buildCount, 2);

        // Now firing p1 SHOULD rebuild.
        p1.set(12);
        await tester.pump();
        expect(buildCount, 3);

        // Swap p1 for p2 via source update.
        source.set([p2]);
        await tester.pump();
        expect(buildCount, 4);

        // p1 is no longer subscribed — firing it should NOT rebuild.
        p1.set(13);
        await tester.pump();
        expect(buildCount, 4);

        // p2 IS subscribed — firing it should rebuild.
        p2.set(21);
        await tester.pump();
        expect(buildCount, 5);
      },
    );

    testWidgets('does not leak listeners after dispose', (tester) async {
      final source = Pod<int>(0);
      final inner = Pod<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PodCollectionBuilder(
            source: source,
            innerPods: () => [inner],
            builder: (_) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final initialBuilds = buildCount;

      // Replace the widget with something else to trigger dispose.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      // After dispose, firing either pod must not rebuild (the widget is gone)
      // AND must not throw. We can't directly assert "no rebuild" (the widget
      // isn't there), so instead assert builds didn't increment from the
      // listener callback path by checking the count is unchanged.
      source.set(42);
      inner.set(99);
      await tester.pump();
      expect(buildCount, initialBuilds);
    });

    testWidgets('switches source cleanly on widget update', (tester) async {
      final sourceA = Pod<int>(0);
      final sourceB = Pod<int>(0);
      var buildCount = 0;

      Widget make(Listenable s) => Directionality(
        textDirection: TextDirection.ltr,
        child: PodCollectionBuilder(
          source: s,
          innerPods: () => const [],
          builder: (_) {
            buildCount++;
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(make(sourceA));
      expect(buildCount, 1);

      // Swap source. The widget should detach A and attach B.
      await tester.pumpWidget(make(sourceB));
      expect(buildCount, 2);

      // Firing the OLD source should no longer rebuild.
      sourceA.set(1);
      await tester.pump();
      expect(buildCount, 2);

      // Firing the NEW source should rebuild.
      sourceB.set(1);
      await tester.pump();
      expect(buildCount, 3);
    });
  });
}
