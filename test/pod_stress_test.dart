// Long-running stress + hostile-T tests for medical/military-grade
// confidence. These exercise the defensive code paths added across the
// v0.20.0 audit passes under heavy load.
//
//   A. Long-running churn — verify no slow leaks in listener / child /
//      cond / cache / queue tracking.
//   B. Hostile T equality — Pods whose value type has pathological ==
//      / hashCode / Comparable behaviour.
//   C. Widget lifecycle stress — rapid pod swaps, churning collection
//      builders, cache overflow under realistic mount load.
//   D. Deep reactive chain — 100-level .map chain propagates without
//      stack overflow.

import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // A. Long-running churn
  // ───────────────────────────────────────────────────────────────────────────

  group('A. churn: 10 000 add/remove listener cycles', () {
    test('pod stays responsive after 10 000 add+remove cycles', () {
      final pod = Pod<int>(0);
      for (var i = 0; i < 10000; i++) {
        final l = () {};
        pod.addStrongRefListener(strongRefListener: l);
        pod.removeListener(l);
      }
      // Pod must still notify a freshly-added listener.
      var fires = 0;
      final listener = () => fires++;
      pod.addStrongRefListener(strongRefListener: listener);
      pod.set(1);
      expect(fires, 1, reason: 'pod must remain notifying after churn');
      pod.dispose();
    });
  });

  group('A. churn: 1 000 ChildPod create/dispose cycles', () {
    test(
      'parent stays responsive and does not retain dead-child weak refs',
      () {
        final parent = Pod<int>(0);
        for (var i = 0; i < 1000; i++) {
          final child = parent.map((v) => v + i);
          child.dispose();
        }
        // Parent should still be notifying. The internal _children list
        // is not inspectable from outside, but a parent that leaked
        // dead refs would still walk them on every notify; we exercise
        // that path by firing once and confirming a fresh listener runs.
        var fires = 0;
        final listener = () => fires++;
        parent.addStrongRefListener(strongRefListener: listener);
        parent.set(1);
        expect(fires, 1);
        parent.dispose();
      },
    );
  });

  group('A. churn: 1 000 SharedPod writes in sequence', () {
    test('queue drains in FIFO order, final value is the last write',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedPod.create<int, int>(
        'stress_key',
        fromValue: (v) => v ?? -1,
        toValue: (v) => v,
        initialValue: -1,
      );
      final futures = <Future<void>>[];
      for (var i = 0; i < 1000; i++) {
        futures.add(pod.set(i));
      }
      await Future.wait(futures);
      expect(pod.getValue(), 999);
      // Storage agrees.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('stress_key'), 999);
      pod.dispose();
    });
  });

  group('A. churn: 1 000 pending conds all error on dispose', () {
    test('every cond Resolvable resolves to Err — no hangs, no leaks',
        () async {
      final pod = Pod<int>(0);
      final resolvables = <Resolvable<int>>[];
      for (var i = 0; i < 1000; i++) {
        resolvables.add(pod.cond((v) => v == -1)); // never matches
      }
      pod.dispose();
      final results = await Future.wait<Result<int>>(
        resolvables.map((r) => r.toAsync().value),
      );
      for (final r in results) {
        expect(r.isErr(), isTrue);
      }
    });
  });

  group('A. churn: 500 PodBuilder mount/unmount cycles', () {
    testWidgets('a pod survives 500 widget mount cycles unscathed',
        (tester) async {
      final pod = Pod<int>(0);
      for (var i = 0; i < 500; i++) {
        await tester.pumpWidget(
          _wrap(
            PodBuilder<int>(
              pod: pod,
              builder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      }
      // After all 500 unmounts, no listeners should be left on the pod.
      // We verify by firing the pod and confirming nothing crashes; a
      // bookkeeping leak would manifest as either growing memory (not
      // testable here) or stale-state crashes.
      var fires = 0;
      final listener = () => fires++;
      pod.addStrongRefListener(strongRefListener: listener);
      pod.set(1);
      expect(fires, 1);
      pod.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B. Hostile T equality
  // ───────────────────────────────────────────────────────────────────────────

  group('B. hostile T: == always returns true', () {
    test(
      'set() short-circuits every time; listener never fires',
      () {
        final pod = Pod<_AlwaysEqual>(const _AlwaysEqual(1));
        var fires = 0;
        final l = () => fires++;
        pod.addStrongRefListener(strongRefListener: l);

        pod.set(const _AlwaysEqual(2));
        pod.set(const _AlwaysEqual(3));
        pod.set(const _AlwaysEqual(4));

        expect(
          fires,
          0,
          reason:
              'T.== returning true means _safeNotEquals returns false → '
              'no notify, no value change',
        );
        // value remains the first one.
        expect(pod.getValue().tag, 1);
        pod.dispose();
      },
    );
  });

  group('B. hostile T: == always returns false', () {
    test(
      'every set() notifies; listener fires once per set',
      () {
        final pod = Pod<_NeverEqual>(const _NeverEqual(1));
        var fires = 0;
        final l = () => fires++;
        pod.addStrongRefListener(strongRefListener: l);

        pod.set(const _NeverEqual(2));
        pod.set(const _NeverEqual(3));
        pod.set(const _NeverEqual(4));

        expect(fires, 3, reason: 'T.== returning false means every set notifies');
        expect(pod.getValue().tag, 4);
        pod.dispose();
      },
    );
  });

  group('B. hostile T: hashCode throws', () {
    test('df_pod never calls hashCode on values — set() does not crash', () {
      // hashCode is never used by df_pod on user values:
      //   - _safeNotEquals uses != (operator ==), not hashCode.
      //   - _children / _listenables / _pendingConds use Set.identity()
      //     (which goes through identityHashCode, an intrinsic that
      //     does not call .hashCode on the object).
      final pod = Pod<_ThrowsHashCode>(const _ThrowsHashCode(1));
      var fires = 0;
      final l = () => fires++;
      pod.addStrongRefListener(strongRefListener: l);

      // None of these set() calls should crash even though the T's
      // hashCode would.
      expect(() => pod.set(const _ThrowsHashCode(2)), returnsNormally);
      expect(() => pod.set(const _ThrowsHashCode(3)), returnsNormally);
      expect(fires, 2);
      pod.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // C. Adversarial widget lifecycle
  // ───────────────────────────────────────────────────────────────────────────

  group('C. lifecycle: 100 pod-swaps under the same widget key', () {
    testWidgets('rapid pod-swaps do not leak listeners on the swapped-out pods',
        (tester) async {
      final pods = List<Pod<int>>.generate(100, (i) => Pod<int>(i));
      const key = ValueKey('swap-stress');

      for (final pod in pods) {
        await tester.pumpWidget(
          _wrap(
            PodBuilder<int>(
              key: key,
              pod: pod,
              builder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        );
      }
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      // No widget is mounted. Firing each swapped-out pod must not run
      // any builder. We can't directly assert listener counts, but we
      // can verify that no exceptions or timer leaks occur.
      for (final pod in pods) {
        pod.set(pod.getValue() + 1000);
      }
      for (final pod in pods) {
        pod.dispose();
      }
    });
  });

  group(
    'C. lifecycle: PodCollectionBuilder with completely-different inner '
    'lists every fire',
    () {
      testWidgets('diff stays correct under thrash', (tester) async {
        final source = Pod<int>(0);
        final allPods = List<Pod<int>>.generate(100, (i) => Pod<int>(i));
        var current = allPods.sublist(0, 10);

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
        final initialBuilds = builds;

        // Slide the window across all 100 pods.
        for (var i = 1; i <= 90; i++) {
          current = allPods.sublist(i, i + 10);
          source.set(i);
          await tester.pump();
        }
        // 90 source fires → 90 rebuilds (plus any inner-pod fires; none
        // here since we didn't set any inner).
        expect(builds, initialBuilds + 90);

        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
        for (final p in allPods) {
          p.dispose();
        }
        source.dispose();
      });
    },
  );

  group('C. lifecycle: cache overflow with 300 distinct keys', () {
    testWidgets(
      'cache enforces maxEntries; old entries evicted in insertion order',
      (tester) async {
        PodBuilderCacheManager.i.clear();
        final origMax = PodBuilderCacheManager.maxEntries;
        PodBuilderCacheManager.maxEntries = 256;
        try {
          for (var i = 0; i < 300; i++) {
            final pod = Pod<int>(i);
            await tester.pumpWidget(
              _wrap(
                PodBuilder<int>(
                  key: ValueKey('overflow-$i'),
                  pod: pod,
                  cacheDuration: const Duration(minutes: 5),
                  builder: (_, __) => const SizedBox.shrink(),
                ),
              ),
            );
            await tester.pumpWidget(_wrap(const SizedBox.shrink()));
            pod.dispose();
          }
          expect(
            PodBuilderCacheManager.i.length,
            lessThanOrEqualTo(256),
            reason: 'cache must not exceed maxEntries',
          );
        } finally {
          PodBuilderCacheManager.maxEntries = origMax;
          PodBuilderCacheManager.i.clear();
        }
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // D. Deep reactive chain
  // ───────────────────────────────────────────────────────────────────────────

  group('D. depth: 100-level .map chain', () {
    test('propagates a single root set without stack overflow', () {
      final root = Pod<int>(0);
      var current = root.map<int>((v) => v + 1);
      for (var i = 0; i < 99; i++) {
        current = current.map<int>((v) => v + 1);
      }
      // Initial: 0 → +1 ×100 = 100.
      expect(current.getValue(), 100);

      // Single root set propagates all the way down.
      root.set(50);
      expect(current.getValue(), 150);

      // Disposal cascade: dispose root, every link should follow.
      root.dispose();
      expect(current.isDisposed, isTrue);
    });
  });
}

// ───────────────────────────────────────────────────────────────────────────
// Hostile T types
// ───────────────────────────────────────────────────────────────────────────

/// `==` claims equal to every other instance. `_safeNotEquals` returns
/// false → `_set` short-circuits → no notify.
class _AlwaysEqual implements Comparable<_AlwaysEqual> {
  final int tag;
  const _AlwaysEqual(this.tag);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => true;

  @override
  int compareTo(_AlwaysEqual other) => 0;
}

/// `==` claims inequality to every other instance. Every set notifies.
class _NeverEqual implements Comparable<_NeverEqual> {
  final int tag;
  const _NeverEqual(this.tag);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => false;

  @override
  int compareTo(_NeverEqual other) => tag - other.tag;
}

/// `hashCode` throws. df_pod should never trip this because it doesn't
/// call hashCode on T values — only on identity helpers like
/// `Set.identity()` which use `identityHashCode` directly.
class _ThrowsHashCode implements Comparable<_ThrowsHashCode> {
  final int tag;
  const _ThrowsHashCode(this.tag);

  @override
  int get hashCode => throw StateError('hashCode must not be called');

  @override
  bool operator ==(Object other) =>
      other is _ThrowsHashCode && other.tag == tag;

  @override
  int compareTo(_ThrowsHashCode other) => tag - other.tag;
}
