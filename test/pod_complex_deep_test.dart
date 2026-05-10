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

// Deep coverage for the three remaining complex subsystems:
// 1. ChildPod._refresh dynamic responder diffing — when responder() returns
//    a different set of parents, old listeners must be detached and new ones
//    attached.
// 2. PodCollectionBuilder edge cases — source-as-inner-pod overlap, ordering,
//    empty/populated transitions.
// 3. PodResultListBuilder — same cache shadowing fix as PodResultBuilder,
//    plus listener attach/detach on pod-list swap.

import 'package:df_pod/df_pod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );

void main() {
  // ───────────────────────────────────────────────────────────────────────
  // ChildPod._refresh dynamic responder diffing
  // ───────────────────────────────────────────────────────────────────────
  group('ChildPod responder diffing', () {
    test('static parents propagate updates correctly', () {
      final a = Pod<int>(1);
      final b = Pod<int>(10);
      final sum = ChildPod<int, int>(
        responder: () => [a, b],
        reducer: (vs) => vs[0] + vs[1],
      );
      expect(sum.getValue(), 11);

      a.set(5);
      expect(sum.getValue(), 15);

      b.set(50);
      expect(sum.getValue(), 55);
    });

    test('dropped parent stops propagating updates', () {
      final a = Pod<int>(1);
      final b = Pod<int>(10);
      var includeB = true;
      final sum = ChildPod<int, int>(
        responder: () => includeB ? [a, b] : [a],
        reducer: (vs) => vs.fold(0, (acc, v) => acc + v),
      );
      expect(sum.getValue(), 11);

      includeB = false;
      a.set(5); // triggers refresh; new responder returns [a] only
      expect(sum.getValue(), 5);

      // b dropped — firing it should not affect sum.
      b.set(999);
      expect(sum.getValue(), 5);
    });

    test('newly-added parent starts propagating updates', () {
      final a = Pod<int>(1);
      final b = Pod<int>(10);
      var includeB = false;
      final sum = ChildPod<int, int>(
        responder: () => includeB ? [a, b] : [a],
        reducer: (vs) => vs.fold(0, (acc, v) => acc + v),
      );
      expect(sum.getValue(), 1);

      includeB = true;
      a.set(2); // triggers refresh; new responder returns [a, b]
      expect(sum.getValue(), 12);

      // b is now subscribed — firing it should propagate.
      b.set(20);
      expect(sum.getValue(), 22);
    });

    test('parents fully replaced — all old detached, all new attached', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      final c = Pod<int>(100);
      final d = Pod<int>(200);
      var phase = 1;
      final pod = ChildPod<int, int>(
        responder: () => phase == 1 ? [a, b] : [c, d],
        reducer: (vs) => vs.fold(0, (acc, v) => acc + v),
      );
      expect(pod.getValue(), 3);

      phase = 2;
      a.set(99); // triggers refresh; new parents are c, d
      // After refresh, value is c + d = 300.
      expect(pod.getValue(), 300);

      // a and b no longer subscribed.
      a.set(0);
      b.set(0);
      expect(pod.getValue(), 300);

      // c and d subscribed.
      c.set(1000);
      expect(pod.getValue(), 1200);

      d.set(2000);
      expect(pod.getValue(), 3000);
    });

    test('responder returning the same parents in different order works', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      var swap = false;
      final pod = ChildPod<int, String>(
        responder: () => swap ? [b, a] : [a, b],
        reducer: (vs) => '${vs[0]}|${vs[1]}',
      );
      expect(pod.getValue(), '1|2');

      swap = true;
      a.set(10);
      expect(pod.getValue(), '2|10');
    });

    test('chain disposal: dispose root unsubscribes child from all parents',
        () {
      final root = Pod<int>(1);
      final extra = Pod<int>(100);
      final pod = ChildPod<int, int>(
        responder: () => [root, extra],
        reducer: (vs) => vs[0] + vs[1],
      );
      expect(pod.getValue(), 101);

      root.dispose(); // triggers disposeChildren — pod is disposed.
      expect(pod.isDisposed, isTrue);

      // After disposal, firing `extra` (still alive) must not blow up.
      extra.set(200);
      // No exception expected.
    });

    test(
      'reducer that throws on first call propagates the error and does not '
      'leave dangling listeners',
      () {
        final a = Pod<int>(1);
        final b = Pod<int>(2);
        var thrown = false;
        expect(
          () => ChildPod<int, int>(
            responder: () => [a, b],
            reducer: (vs) {
              if (!thrown) {
                thrown = true;
                throw StateError('reducer boom');
              }
              return vs.fold(0, (x, y) => x + y);
            },
          ),
          throwsStateError,
        );

        // Firing parents must not crash even though a child was attempted.
        a.set(99);
        b.set(99);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────
  // PodCollectionBuilder edge cases
  // ───────────────────────────────────────────────────────────────────────
  group('PodCollectionBuilder edge cases', () {
    testWidgets(
      'source pod that is also in innerPods — single set produces a single '
      'rebuild even though the same listener is attached twice',
      (tester) async {
        final pod = Pod<int>(0);
        var buildCount = 0;

        await tester.pumpWidget(
          _wrap(
            PodCollectionBuilder(
              source: pod,
              innerPods: () => [pod],
              builder: (_) {
                buildCount++;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        final initial = buildCount;

        pod.set(1);
        await tester.pump();
        // Even if `_listener` is attached twice, Flutter coalesces setState
        // within a frame so the user sees a single rebuild per fire.
        expect(buildCount - initial, 1);

        pod.set(2);
        await tester.pump();
        expect(buildCount - initial, 2);
      },
    );

    testWidgets('inner pod entering the list mid-flight starts firing',
        (tester) async {
      final source = Pod<int>(0);
      final newcomer = Pod<int>(0);
      final inners = <Pod<int>>[];
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => inners,
            builder: (_) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final mountedAt = buildCount;

      // newcomer not yet in the list — firing it must not rebuild.
      newcomer.set(1);
      await tester.pump();
      expect(buildCount, mountedAt);

      // Add newcomer to the inner list and fire source so the builder picks
      // it up.
      inners.add(newcomer);
      source.set(1);
      await tester.pump();
      // Source change rebuilds; newcomer is now subscribed.
      final attachedAt = buildCount;

      newcomer.set(2);
      await tester.pump();
      expect(
        buildCount - attachedAt,
        1,
        reason: 'newcomer should fire once it is in the inner list',
      );
    });

    testWidgets(
      'reordering inner pods (same elements, different order) detaches '
      'and reattaches — verifies _listsIdentical is order-sensitive',
      (tester) async {
        final source = Pod<int>(0);
        final p1 = Pod<int>(0);
        final p2 = Pod<int>(0);
        var buildCount = 0;
        var ordering = 1;

        await tester.pumpWidget(
          _wrap(
            PodCollectionBuilder(
              source: source,
              innerPods: () => ordering == 1 ? [p1, p2] : [p2, p1],
              builder: (_) {
                buildCount++;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(buildCount, 1);

        // Trigger resync via source fire with new ordering.
        ordering = 2;
        source.set(1);
        await tester.pump();
        // After resync, both pods should still be subscribed.
        final reorderedAt = buildCount;

        p1.set(1);
        await tester.pump();
        expect(
          buildCount - reorderedAt,
          1,
          reason: 'p1 must still be subscribed after reorder',
        );
        p2.set(1);
        await tester.pump();
        expect(
          buildCount - reorderedAt,
          2,
          reason: 'p2 must still be subscribed after reorder',
        );
      },
    );

    testWidgets('large dynamic inner list (100 pods) churns cleanly',
        (tester) async {
      final source = Pod<int>(0);
      final pods = List.generate(100, (_) => Pod<int>(0));
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => pods,
            builder: (_) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final mountedAt = buildCount;
      expect(mountedAt, 1);

      // Each pod fire should rebuild exactly once.
      for (var i = 0; i < pods.length; i++) {
        pods[i].set(i + 1);
        await tester.pump();
      }
      expect(buildCount - mountedAt, 100);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // PodResultListBuilder — cache shadowing + listener swap
  // ───────────────────────────────────────────────────────────────────────
  group('PodListBuilder cache + lifecycle', () {
    testWidgets('live updates win over cache for keyed list builder',
        (tester) async {
      // Same shadowing-bug regression as PodResultBuilder, applied to lists.
      final p1 = Pod<int>(1);
      final p2 = Pod<int>(2);
      const ttl = Duration(milliseconds: 200);
      var lastBuilt = const <int>[];

      await tester.pumpWidget(
        _wrap(
          PodListBuilder<int>(
            key: const ValueKey('list_cache'),
            podList: [p1, p2],
            cacheDuration: ttl,
            builder: (context, snapshot) {
              UNSAFE:
              {
                lastBuilt = snapshot.value
                    .unwrap()
                    .map((e) => e.unwrap().unwrap())
                    .toList();
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(lastBuilt, [1, 2]);

      p1.set(10);
      await tester.pump();
      expect(
        lastBuilt,
        [10, 2],
        reason: 'live pod updates must reach the UI even with cache key set',
      );

      p2.set(20);
      await tester.pump();
      expect(lastBuilt, [10, 20]);

      // Drain TTL.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump(ttl + const Duration(milliseconds: 50));
    });

    testWidgets('swapping the pod list detaches old listeners',
        (tester) async {
      final p1 = Pod<int>(1);
      final p2 = Pod<int>(2);
      final p3 = Pod<int>(3);
      var buildCount = 0;

      Widget make(List<Pod<int>> pods) => _wrap(
            PodListBuilder<int>(
              podList: pods,
              builder: (context, _) {
                buildCount++;
                return const SizedBox.shrink();
              },
            ),
          );

      await tester.pumpWidget(make([p1, p2]));
      expect(buildCount, 1);

      await tester.pumpWidget(make([p2, p3]));
      // After the swap, p1 is gone.
      final swapAt = buildCount;
      p1.set(99);
      await tester.pump();
      expect(buildCount, swapAt, reason: 'p1 detached on swap');

      // p2 still subscribed — fires.
      p2.set(99);
      await tester.pump();
      expect(buildCount, swapAt + 1);

      // p3 newly subscribed — fires.
      p3.set(99);
      await tester.pump();
      expect(buildCount, swapAt + 2);
    });

    testWidgets('empty pod list mounts and disposes cleanly', (tester) async {
      // Edge case: empty list shouldn't crash on attach/detach loops.
      var buildCount = 0;
      await tester.pumpWidget(
        _wrap(
          PodListBuilder<int>(
            podList: const <ValueListenable<int>>[],
            builder: (context, _) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      // No exception.
    });

    testWidgets('onDispose receives the full pod list once on teardown',
        (tester) async {
      final p1 = Pod<int>(1);
      final p2 = Pod<int>(2);
      Iterable<ValueListenable<int>>? receivedOnDispose;

      await tester.pumpWidget(
        _wrap(
          PodListBuilder<int>(
            podList: [p1, p2],
            onDispose: (pods) => receivedOnDispose = pods,
            builder: (context, _) => const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      expect(receivedOnDispose, isNotNull);
      expect(receivedOnDispose!.toList(), [p1, p2]);
    });
  });
}
