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
  group('PodBuilder', () {
    testWidgets('builds with initial pod value', (tester) async {
      final pod = Pod<int>(42);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PodBuilder(
            pod: pod,
            builder: (context, snapshot) {
              UNSAFE:
              final value = snapshot.value.unwrap().unwrap();
              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('rebuilds when pod value changes', (tester) async {
      final pod = Pod<int>(1);
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PodBuilder(
            pod: pod,
            builder: (context, snapshot) {
              buildCount++;
              UNSAFE:
              final value = snapshot.value.unwrap().unwrap();
              return Text('$value');
            },
          ),
        ),
      );
      expect(buildCount, 1);
      expect(find.text('1'), findsOneWidget);

      pod.set(2);
      await tester.pump();
      expect(buildCount, 2);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('does NOT rebuild when pod set to equal int value',
        (tester) async {
      final pod = Pod<int>(1);
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PodBuilder(
            pod: pod,
            builder: (context, snapshot) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      pod.set(1); // same value — short-circuit
      await tester.pump();
      expect(buildCount, 1); // no rebuild
    });

    testWidgets('does rebuild when pod set to equal List (no short-circuit)',
        (tester) async {
      final pod = Pod<List<int>>([1, 2]);
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PodBuilder(
            pod: pod,
            builder: (context, snapshot) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      pod.set([1, 2]); // structurally equal but different instance
      await tester.pump();
      expect(buildCount, 2); // DOES rebuild — List isn't Comparable/Equatable
    });

    testWidgets('cleans up listener on dispose', (tester) async {
      final pod = Pod<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PodBuilder(
            pod: pod,
            builder: (context, snapshot) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      // Remove the widget from the tree.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      // Firing the pod after dispose must not throw or rebuild.
      pod.set(99);
      await tester.pump();
      expect(buildCount, 1);
    });

    testWidgets('switches pod cleanly on widget rebuild', (tester) async {
      final podA = Pod<int>(10);
      final podB = Pod<int>(20);
      var buildCount = 0;

      Widget make(Pod<int> p) => Directionality(
            textDirection: TextDirection.ltr,
            child: PodBuilder(
              pod: p,
              builder: (context, snapshot) {
                buildCount++;
                UNSAFE:
                final value = snapshot.value.unwrap().unwrap();
                return Text('$value');
              },
            ),
          );

      await tester.pumpWidget(make(podA));
      expect(buildCount, 1);
      expect(find.text('10'), findsOneWidget);

      // Swap to podB.
      await tester.pumpWidget(make(podB));
      expect(find.text('20'), findsOneWidget);

      // Firing old pod should NOT rebuild.
      final countAfterSwap = buildCount;
      podA.set(11);
      await tester.pump();
      expect(buildCount, countAfterSwap);

      // Firing new pod SHOULD rebuild.
      podB.set(21);
      await tester.pump();
      expect(find.text('21'), findsOneWidget);
    });
  });
}
