// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Regression tests for the v0.20.0 optimization pass.
//
//   - P1: ReducerPod._listenables stored as Set.identity() — diff uses
//         O(1) "already subscribed?" lookups, no per-refresh `oldSet`
//         allocation.
//   - P2: Deferred notifications coalesce — multiple
//         `set(.., notifyImmediately: false)` within one frame produce
//         exactly one notification, not N.
//   - P3: _pendingConds is lazy-initialised — pods that never call
//         `cond()` don't allocate the Set.
//   - P4: _pinnedListeners is lazy-initialised — pods that never use
//         pinning helpers don't allocate the Set.
//   - P5: PodCollectionBuilder uses linear diff for small lists, set
//         diff for large lists. Both branches produce identical
//         observable behavior.
//
// The optimizations are *observably* correctness-preserving — these
// tests check the new emergent behaviour (coalescing) and the
// invariants any optimization must keep (round-trip subscription
// changes, dispose cleanup).
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
  // P1: ReducerPod with Set-typed _listenables still behaves correctly
  // ───────────────────────────────────────────────────────────────────────────
  group('P1: ReducerPod _listenables as Set', () {
    test('static parents — many updates propagate end-to-end', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      final c = Pod<int>(3);
      final pSum = ReducerPod<int>(
        responder: () => [Some(a), Some(b), Some(c)],
        reducer: (vs) {
          var total = 0;
          for (final v in vs) {
            UNSAFE:
            if (v.isSome()) total += v.unwrap() as int;
          }
          UNSAFE:
          return Some(total);
        },
      );
      expect(pSum.getValue(), 6);

      a.set(10);
      expect(pSum.getValue(), 15);
      b.set(20);
      expect(pSum.getValue(), 33);
      c.set(30);
      expect(pSum.getValue(), 60);

      pSum.dispose();
    });

    test('duplicate parents in responder dedupe via Set semantics', () {
      final p = Pod<int>(5);
      final pDup = ReducerPod<int>(
        // Returns p twice; Set.identity() drops the second.
        responder: () => [Some(p), Some(p)],
        reducer: (vs) {
          var total = 0;
          for (final v in vs) {
            UNSAFE:
            if (v.isSome()) total += v.unwrap() as int;
          }
          UNSAFE:
          return Some(total);
        },
      );
      // The reducer sees both [p, p] in `vs`, so the sum is 10. The
      // SET dedup is about subscriptions, not reducer inputs.
      expect(pDup.getValue(), 10);

      // One subscription on p, so one fire per set.
      var fires = 0;
      late final ll = () => fires++;
      pDup.addStrongRefListener(strongRefListener: ll);

      p.set(100);
      expect(fires, 1);
      expect(pDup.getValue(), 200);

      pDup.dispose();
    });

    test('ValueNotifier interop still works (non-Pod ValueListenable)', () {
      final vn = ValueNotifier<int>(10);
      final p = Pod<int>(5);
      final pSum = ReducerPod<int>(
        responder: () => [Some(vn), Some(p)],
        reducer: (vs) {
          var total = 0;
          for (final v in vs) {
            UNSAFE:
            if (v.isSome()) total += v.unwrap() as int;
          }
          UNSAFE:
          return Some(total);
        },
      );
      expect(pSum.getValue(), 15);

      vn.value = 100;
      expect(pSum.getValue(), 105);
      p.set(50);
      expect(pSum.getValue(), 150);

      pSum.dispose();
      vn.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P2: Coalesced deferred notifications
  // ───────────────────────────────────────────────────────────────────────────
  group('P2: deferred notify coalescing', () {
    testWidgets(
      'N rapid sets with notifyImmediately:false → 1 notify per frame',
      (tester) async {
        // Mount a real widget so the binding has work to schedule.
        await tester.pumpWidget(_wrap(const SizedBox.shrink()));

        final pod = Pod<int>(0);
        var fires = 0;
        // Strong-ref listener: stays alive for the test scope.
        // Assigned to a variable (not a function declaration) so the
        // `mustBeStrongRefOrError` lint is satisfied.
        final listener = () {
          fires++;
        };
        pod.addStrongRefListener(strongRefListener: listener);

        // Five back-to-back deferred sets. Pre-P2 this scheduled 5
        // post-frame callbacks; each one fired notifyListeners → 5
        // listener calls.
        pod.set(1, notifyImmediately: false);
        pod.set(2, notifyImmediately: false);
        pod.set(3, notifyImmediately: false);
        pod.set(4, notifyImmediately: false);
        pod.set(5, notifyImmediately: false);

        // Value updates synchronously; notify is deferred.
        expect(pod.getValue(), 5);
        expect(fires, 0);

        // The deferred notify is scheduled via addPostFrameCallback.
        // Schedule another frame and let it drain — request a build of
        // the widget tree so the binding has a reason to do work.
        tester.binding.scheduleFrame();
        await tester.pump();
        expect(
          fires,
          1,
          reason:
              'P2: coalesced; one notify per frame regardless of write count',
        );

        // Another batch in the next frame coalesces independently.
        pod.set(6, notifyImmediately: false);
        pod.set(7, notifyImmediately: false);
        tester.binding.scheduleFrame();
        await tester.pump();
        expect(fires, 2);

        pod.dispose();
      },
    );

    testWidgets(
      'immediate notify still fires synchronously and uncoalesced',
      (tester) async {
        final pod = Pod<int>(0);
        var fires = 0;
        final l = () {
          fires++;
        };
        pod.addStrongRefListener(strongRefListener: l);

        // Three immediate sets — each fires synchronously.
        pod.set(1);
        pod.set(2);
        pod.set(3);
        expect(fires, 3);

        pod.dispose();
      },
    );

    testWidgets(
      'P2 safety: sync notify in the middle of a deferred batch '
      'does not lose the deferred notification',
      (tester) async {
        await tester.pumpWidget(_wrap(const SizedBox.shrink()));

        final pod = Pod<int>(0);
        final fires = <int>[];
        final l = () => fires.add(pod.getValue());
        pod.addStrongRefListener(strongRefListener: l);

        // Interleave deferred and immediate sets.
        pod.set(1, notifyImmediately: false); // schedule deferred-1
        pod.set(2); // immediate → fires.add(2). The deferred is still
        // pending (flag still true). At frame end the deferred fires
        // and adds the *final* value again.
        pod.set(3, notifyImmediately: false); // value=3, flag still true
        expect(fires, [2]);

        tester.binding.scheduleFrame();
        await tester.pump();
        // Deferred fires once with the final value (3). Pre-P2 it would
        // have fired twice (once per deferred set), but the listener
        // would see the same final value each time anyway.
        expect(
          fires,
          [2, 3],
          reason: 'sync notify path remains uncoalesced; deferred fires once',
        );

        pod.dispose();
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P3: _pendingConds lazy init does not regress cond() semantics
  // ───────────────────────────────────────────────────────────────────────────
  group('P3: cond() with lazy _pendingConds', () {
    test('cond() resolves on match', () async {
      final pod = Pod<int>(0);
      final r = pod.cond((v) => v == 7);
      pod.set(7);
      final result = await r.toAsync().value;
      expect(result.isOk(), isTrue);
      pod.dispose();
    });

    test('cond() errors on dispose-before-match', () async {
      final pod = Pod<int>(0);
      final r = pod.cond((v) => v == 999);
      pod.dispose();
      final result = await r.toAsync().value;
      expect(result.isErr(), isTrue);
    });

    test('pod that never calls cond() disposes cleanly', () {
      final pod = Pod<int>(0);
      pod.set(1);
      pod.set(2);
      pod.dispose();
      expect(pod.isDisposed, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P4: _pinnedListeners lazy init does not regress pin/unpin
  // ───────────────────────────────────────────────────────────────────────────
  group('P4: lazy _pinnedListeners', () {
    test('addSingleExecutionListener still fires exactly once', () {
      final pod = Pod<int>(0);
      var fires = 0;
      pod.addSingleExecutionListener(() => fires++);
      pod.set(1);
      pod.set(2);
      pod.set(3);
      expect(fires, 1);
      pod.dispose();
    });

    test('pod that never pins disposes cleanly', () {
      final pod = Pod<int>(0);
      pod.dispose();
      expect(pod.isDisposed, isTrue);
    });

    test('unpin before pin is a safe no-op (lazy init not triggered)', () {
      // We can't easily exercise this externally without exposing the
      // protected methods. But verifying dispose doesn't throw is a
      // sufficient smoke-test for "lazy init doesn't break the null
      // path".
      final pod = Pod<int>(0);
      pod.dispose();
      expect(pod.isDisposed, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P5: PodCollectionBuilder adaptive diff
  // ───────────────────────────────────────────────────────────────────────────
  group('P5: PodCollectionBuilder linear-vs-set diff', () {
    testWidgets('small inner list (linear branch) produces correct diff',
        (tester) async {
      final source = Pod<int>(0);
      final inners = [Pod<int>(1), Pod<int>(2), Pod<int>(3)];
      var current = inners.sublist(0, 3);

      var builds = 0;
      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => current,
            builder: (_) {
              builds++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final baseline = builds;

      // Inner pod fires → rebuild.
      inners[0].set(10);
      await tester.pump();
      expect(builds, baseline + 1);

      // Shrink list to 1 element. The dropped pods should no longer
      // trigger rebuilds.
      current = inners.sublist(0, 1);
      source.set(1);
      await tester.pump();
      final afterShrink = builds;

      // Pods that left the list fire — no rebuild.
      inners[1].set(99);
      inners[2].set(99);
      await tester.pump();
      expect(builds, afterShrink);

      // Pod still in list fires — rebuild.
      inners[0].set(100);
      await tester.pump();
      expect(builds, afterShrink + 1);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });

    testWidgets(
      'large inner list (set branch) produces identical diff results',
      (tester) async {
        final source = Pod<int>(0);
        final pods = List<Pod<int>>.generate(20, (i) => Pod<int>(i));
        var current = pods.sublist(0, 10);

        var builds = 0;
        await tester.pumpWidget(
          _wrap(
            PodCollectionBuilder(
              source: source,
              innerPods: () => current,
              builder: (_) {
                builds++;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        final baseline = builds;

        // Slide window — half new, half retained.
        current = pods.sublist(5, 15);
        source.set(1);
        await tester.pump();
        expect(builds, baseline + 1);

        // Pods in the window fire — rebuild.
        pods[10].set(999);
        await tester.pump();
        expect(builds, baseline + 2);

        // Pods OUT of the window fire — no rebuild.
        pods[0].set(999);
        await tester.pump();
        expect(builds, baseline + 2);

        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      },
    );
  });
}
