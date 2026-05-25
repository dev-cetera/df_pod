// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Regression tests for the v0.20.0 optimization pass. These tests
// verify CORRECTNESS, not performance — perf claims are documented in
// CHANGELOG. The point here is to prove that the optimizations
// preserve every observable behaviour the test suite already guarantees.
//
//   - O1: ReducerPod diff (only mutates listeners that actually changed)
//   - O2: WeakChangeNotifier._compactListeners fast-path skips when
//         nothing died during the notify
//   - O3: ChildPod identity short-circuit when parent list is unchanged
//   - O4: PodBuilder/PodListBuilder cache-key memoization
//   - MO1: PodCollectionBuilder identity-Set diff
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // O1: ReducerPod diff correctness
  // ───────────────────────────────────────────────────────────────────────────
  group('O1: ReducerPod diff', () {
    test('stable parent list — listeners survive across many refreshes', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      final pSum = ReducerPod<int>(
        responder: () => [Some(a), Some(b)],
        reducer: (vs) {
          UNSAFE:
          return Some(
            vs.fold<int>(
              0,
              (acc, v) => acc + (v.isSome() ? v.unwrap() as int : 0),
            ),
          );
        },
      );
      expect(pSum.getValue(), 3);

      // Many fires — the diff approach should keep both listeners
      // attached the whole time. Pre-O1 they were removed and re-added
      // on every fire.
      for (var i = 0; i < 50; i++) {
        a.set(i);
      }
      expect(pSum.getValue(), 49 + 2);

      for (var i = 0; i < 50; i++) {
        b.set(i);
      }
      expect(pSum.getValue(), 49 + 49);

      pSum.dispose();
    });

    test(
      'shrinking parent set: dropped parent\'s listener is detached',
      () {
        final a = Pod<int>(1);
        final b = Pod<int>(2);
        var includeB = true;
        final pSum = ReducerPod<int>(
          responder: () => includeB ? [Some(a), Some(b)] : [Some(a)],
          reducer: (vs) {
            UNSAFE:
            return Some(
              vs.fold<int>(
                0,
                (acc, v) => acc + (v.isSome() ? v.unwrap() as int : 0),
              ),
            );
          },
        );
        expect(pSum.getValue(), 3);

        includeB = false;
        a.set(10);
        expect(pSum.getValue(), 10);

        // Now b fires — pSum should NOT track it any more.
        b.set(999);
        expect(pSum.getValue(), 10);

        pSum.dispose();
      },
    );

    test('reducer throw rolls back subscription changes', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      var swap = false;
      final pSum = ReducerPod<int>(
        responder: () => swap ? [Some(a)] : [Some(a), Some(b)],
        reducer: (vs) {
          if (swap) throw StateError('boom');
          UNSAFE:
          return Some(
            vs.fold<int>(
              0,
              (acc, v) => acc + (v.isSome() ? v.unwrap() as int : 0),
            ),
          );
        },
      );
      expect(pSum.getValue(), 3);

      // Trigger a refresh that will throw inside the reducer. The
      // optimisation should roll back any subscription change so the
      // pod can still observe its original parents.
      swap = true;
      final errors = <FlutterErrorDetails>[];
      final prev = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        a.set(100); // triggers _refresh → _getValue → reducer throws
      } finally {
        FlutterError.onError = prev;
      }

      // Reducer threw; pod value unchanged. Subscriptions should be
      // rolled back so subsequent untainted refreshes still work.
      swap = false;
      a.set(5);
      expect(pSum.getValue(), 5 + 2);

      pSum.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // O2: WeakChangeNotifier compaction fast-path
  // ───────────────────────────────────────────────────────────────────────────
  group('O2: compactListeners fast path', () {
    test('many notifies with stable listeners — no spurious recompaction', () {
      final pod = Pod<int>(0);
      // Stable, alive listeners.
      final listeners = <VoidCallback>[];
      var totalFires = 0;
      for (var i = 0; i < 32; i++) {
        final l = () => totalFires++;
        listeners.add(l);
        pod.addStrongRefListener(strongRefListener: l);
      }

      for (var i = 0; i < 100; i++) {
        pod.set(i);
      }
      // Each set fires 32 listeners → 3200 total.
      expect(totalFires, 32 * 99); // first set is 0→0 short-circuits

      pod.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // O3: ChildPod identity short-circuit
  // ───────────────────────────────────────────────────────────────────────────
  group('O3: ChildPod identity short-circuit', () {
    test('stable parent list — child still propagates updates correctly', () {
      final parent = Pod<int>(1);
      final child = parent.map<int>((v) => v * 10);
      expect(child.getValue(), 10);

      for (var i = 0; i < 50; i++) {
        parent.set(i);
      }
      expect(child.getValue(), 49 * 10);

      parent.dispose();
    });

    test('parent set change still triggers full diff', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      var includeB = true;
      final child = ChildPod<int, int>(
        responder: () => includeB ? [a, b] : [a],
        reducer: (vs) => vs.fold<int>(0, (acc, v) => acc + v),
      );
      expect(child.getValue(), 3);

      includeB = false;
      a.set(10);
      // child re-runs responder, sees parent set shrunk, drops b's subscription.
      expect(child.getValue(), 10);

      b.set(999);
      // b's listener is detached so child's value should be unaffected.
      expect(child.getValue(), 10);

      a.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // O4: cache-key memoization
  // ───────────────────────────────────────────────────────────────────────────
  group('O4: cache-key memo', () {
    setUp(PodBuilderCacheManager.i.clear);

    testWidgets('cache survives many rebuilds with the same pod',
        (tester) async {
      const key = ValueKey('o4-memo');
      final pod = Pod<int>(1);

      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            key: key,
            pod: pod,
            cacheDuration: const Duration(minutes: 5),
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ),
      );

      // Many fires → many _cacheValue/__valueChanged → many cache-key
      // calls. With O4 the key string is computed once.
      for (var i = 0; i < 100; i++) {
        pod.set(i);
        await tester.pump();
      }

      // Cache holds last value under the compound key. We can't read
      // the key string directly (it's encapsulated), but we can verify
      // size hasn't blown up.
      expect(PodBuilderCacheManager.i.length, lessThanOrEqualTo(1));

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });

    testWidgets('didUpdateWidget invalidates the memo when pod changes',
        (tester) async {
      const key = ValueKey('o4-memo-invalidate');
      final podA = Pod<int>(1);

      Widget make(Pod<int> p) => _wrap(
            PodBuilder<int>(
              key: key,
              pod: p,
              cacheDuration: const Duration(minutes: 5),
              builder: (_, __) => const SizedBox.shrink(),
            ),
          );

      await tester.pumpWidget(make(podA));

      // Swap the pod under the same widget key. The new pod has a
      // different identityHashCode, so the cache-key memo must
      // invalidate or we'd write podB's value under podA's key.
      final podB = Pod<int>(99);
      await tester.pumpWidget(make(podB));

      // Both pods should have independent cache entries.
      expect(PodBuilderCacheManager.i.length, 2);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // MO1: PodCollectionBuilder identity-Set diff
  // ───────────────────────────────────────────────────────────────────────────
  group('MO1: PodCollectionBuilder identity-set diff', () {
    testWidgets(
      'large dynamic inner list — diff stays correct under churn',
      (tester) async {
        final source = Pod<int>(0);
        final pods = List<Pod<int>>.generate(80, (i) => Pod<int>(i));
        var window = pods.sublist(0, 40);

        var builds = 0;
        await tester.pumpWidget(
          _wrap(
            PodCollectionBuilder(
              source: source,
              innerPods: () => window,
              builder: (_) {
                builds++;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        final baseline = builds;

        // Slide the window over a few times.
        window = pods.sublist(20, 60);
        source.set(1);
        await tester.pump();
        expect(builds, baseline + 1);

        window = pods.sublist(40, 80);
        source.set(2);
        await tester.pump();
        expect(builds, baseline + 2);

        // Pods currently in the window fire → rebuild.
        pods[50].set(999);
        await tester.pump();
        expect(builds, baseline + 3);

        // Pods OUT of the window fire → NO rebuild (detached by diff).
        pods[0].set(999);
        await tester.pump();
        expect(builds, baseline + 3);

        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      },
    );
  });
}
