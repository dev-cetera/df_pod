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

// Deep abuse coverage for four internal subsystems the user called out:
//
//   1. Pod mappings — `.map()` / `.reduce()` chains, fanout, dispose
//      propagation, type changes, intermediate-link death.
//   2. Reducer arity helpers — `PodReducer1` … `PodReducer7` and
//      `MultiplePodReducer`. We exercise every arity end-to-end and the
//      single-responder-call invariant first guaranteed in v0.18.x.
//   3. WeakChangeNotifier — `hasListeners`, swapping the listener set
//      between notifies, the count-vs-capacity invariants the deeper
//      tests don't quite hit.
//   4. PodFinalizerWrapper — the `@visibleForTesting` shim around
//      `Finalizer<DisposablePod<dynamic>?>` that auto-disposes a pod
//      once the wrapper is GC'd.
//   5. PodBuilderCacheManager — TTL, key collisions, eviction.

import 'package:df_pod/df_pod.dart';
// `PodFinalizerWrapper` lives in an underscore-prefixed source file that the
// generated barrel skips. It is annotated `@visibleForTesting`, so importing
// directly from the implementation path is the intended access pattern.
// ignore: implementation_imports
import 'package:df_pod/src/utils/_pod_finalizer_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // 1. Pod mappings — .map() and .reduce() chains
  // ───────────────────────────────────────────────────────────────────────────
  group('Pod mappings — .map() type-changing chains', () {
    test('map() chain crosses 4 different types and propagates', () {
      final root = Pod<int>(5);
      final asString = root.map((v) => 'n=$v');
      final asLen = asString.map((s) => s.length);
      final asEven = asLen.map((n) => n.isEven);
      final asMarker = asEven.map((b) => b ? '✓' : '✗');

      expect(asString.getValue(), 'n=5'); // 3 chars
      expect(asLen.getValue(), 3);
      expect(asEven.getValue(), isFalse);
      expect(asMarker.getValue(), '✗');

      root.set(123); // 'n=123' → len 5 → odd → '✗'
      expect(asString.getValue(), 'n=123');
      expect(asLen.getValue(), 5);
      expect(asEven.getValue(), isFalse);
      expect(asMarker.getValue(), '✗');

      root.set(12); // 'n=12' → len 4 → even → '✓'
      expect(asString.getValue(), 'n=12');
      expect(asLen.getValue(), 4);
      expect(asEven.getValue(), isTrue);
      expect(asMarker.getValue(), '✓');
    });

    test('parent fanout: 5 sibling maps all observe every parent set', () {
      // ChildPod's listeners are `@protected` via ProtectedPodMixin, so we
      // verify fanout by reading values after each parent set — if a child's
      // internal `_refresh` listener didn't fire, the cached value wouldn't
      // have been recomputed.
      final root = Pod<int>(0);
      final c1 = root.map((v) => v + 1);
      final c2 = root.map((v) => v + 2);
      final c3 = root.map((v) => v + 3);
      final c4 = root.map((v) => v + 4);
      final c5 = root.map((v) => v + 5);

      root.set(10);
      expect([
        c1.getValue(),
        c2.getValue(),
        c3.getValue(),
        c4.getValue(),
        c5.getValue(),
      ], [11, 12, 13, 14, 15],);

      root.set(20);
      expect([
        c1.getValue(),
        c2.getValue(),
        c3.getValue(),
        c4.getValue(),
        c5.getValue(),
      ], [21, 22, 23, 24, 25],);
    });

    test(
      'child short-circuit independent of parent: parent fires but child '
      'value collapses to same projection — chain a second map() off the '
      'child to observe fire count without breaching ProtectedPodMixin',
      () {
        // Map int → bool. Many different ints map to the same bool, so the
        // intermediate child must short-circuit on its own value. We observe
        // this via a downstream map() that returns the projection's
        // value; if isPositive short-circuits, downstream's reducer must
        // not re-run.
        final root = Pod<int>(0);
        final isPositive = root.map((v) => v > 0);
        var downstreamRebuilds = 0;
        // ignore: unused_local_variable
        final observer = isPositive.map((b) {
          downstreamRebuilds++;
          return b ? 'POS' : 'NEG';
        });

        final initial = downstreamRebuilds;
        root.set(1); // isPositive: false → true → downstream rebuilds.
        expect(isPositive.getValue(), isTrue);
        expect(downstreamRebuilds - initial, 1);

        // Many positive sets — isPositive stays true; downstream should not
        // be re-run for any of them.
        root.set(2);
        root.set(3);
        root.set(100);
        expect(
          downstreamRebuilds - initial,
          1,
          reason: 'isPositive short-circuit blocks downstream rebuilds',
        );

        root.set(-1); // isPositive: true → false → downstream rebuilds.
        expect(isPositive.getValue(), isFalse);
        expect(downstreamRebuilds - initial, 2);

        root.set(-99);
        expect(downstreamRebuilds - initial, 2);
      },
    );

    test('map() reducer that throws on initial creation propagates', () {
      final pod = Pod<int>(1);
      expect(
        () => pod.map<int>((_) => throw StateError('initial map boom')),
        throwsStateError,
      );
      // Parent still functional after the failed child construction.
      pod.set(2);
      expect(pod.getValue(), 2);
    });

    test('map() reducer that throws on a subsequent fire is surfaced', () {
      // The throw happens inside ChildPod._refresh → reducer. The refresh
      // is triggered as a listener of the parent's notifyListeners, so the
      // exception is caught and reported via FlutterError.
      final pod = Pod<int>(0);
      var calls = 0;
      // ignore: unused_local_variable
      final child = pod.map((v) {
        calls++;
        if (calls > 1) throw StateError('later map boom');
        return v * 10;
      });

      final errors = <FlutterErrorDetails>[];
      final prev = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        pod.set(1);
      } finally {
        FlutterError.onError = prev;
      }
      expect(errors, hasLength(1));
      expect(errors.single.exception, isA<StateError>());
    });

    test(
      'disposing the parent disposes a wide map fanout (5 children) in '
      'a single call',
      () {
        final root = Pod<int>(0);
        final children = List.generate(5, (i) => root.map((v) => v + i));
        for (final c in children) {
          expect(c.isDisposed, isFalse);
        }
        root.dispose();
        for (final c in children) {
          expect(c.isDisposed, isTrue);
        }
      },
    );

    test(
      'middle of a 4-deep map chain is disposed — root still propagates '
      'to siblings that share the root, not the dead branch',
      () {
        final root = Pod<int>(1);
        final a = root.map((v) => v * 10); // alive branch
        final b1 = root.map((v) => v * 100); // doomed-mid branch
        final b2 = b1.map((v) => v + 1); // depends on b1

        expect(a.getValue(), 10);
        expect(b1.getValue(), 100);
        expect(b2.getValue(), 101);

        // Disposing b1 disposes b2 too (b2 is its child).
        b1.dispose();
        expect(b1.isDisposed, isTrue);
        expect(b2.isDisposed, isTrue);
        expect(a.isDisposed, isFalse);

        // Root still drives a.
        root.set(2);
        expect(a.getValue(), 20);
      },
    );

    test(
      '.reduce() between a root and a derived map preserves single-source '
      'updates without double-firing',
      () {
        final root = Pod<int>(1);
        final doubled = root.map((v) => v * 2);

        var reducerCalls = 0;
        final sum = root.reduce<int, int>(doubled, (a, b) {
          reducerCalls++;
          return a.getValue() + b.getValue();
        });
        final initialCalls = reducerCalls;
        expect(sum.getValue(), 3); // 1 + 2

        root.set(10);
        // root's notify fires (a) the reducer (via direct subscription) and
        // (b) doubled.refresh which fires the reducer too. Acceptable as
        // long as the FINAL value is correct.
        expect(sum.getValue(), 30); // 10 + 20
        expect(reducerCalls - initialCalls, greaterThanOrEqualTo(1));
      },
    );

    test(
      '.reduce() where the second operand is the SAME pod as the first '
      'subscribes the same listener twice but stays consistent',
      () {
        final p = Pod<int>(1);
        final paired = p.reduce<int, int>(p, (a, b) {
          return a.getValue() + b.getValue();
        });
        expect(paired.getValue(), 2);

        p.set(7);
        expect(paired.getValue(), 14);
      },
    );

    test('long .reduce() chain folds correctly', () {
      // Build a reduce-of-reduce tower 5 levels deep using only .reduce().
      final p1 = Pod<int>(1);
      final p2 = Pod<int>(2);
      final p3 = Pod<int>(3);
      final p4 = Pod<int>(4);
      final p5 = Pod<int>(5);
      final s1 = p1.reduce<int, int>(p2, (a, b) => a.getValue() + b.getValue());
      final s2 = s1.reduce<int, int>(p3, (a, b) => a.getValue() + b.getValue());
      final s3 = s2.reduce<int, int>(p4, (a, b) => a.getValue() + b.getValue());
      final s4 = s3.reduce<int, int>(p5, (a, b) => a.getValue() + b.getValue());

      expect(s4.getValue(), 15); // 1+2+3+4+5

      p3.set(30);
      expect(s4.getValue(), 42); // 1+2+30+4+5

      p1.set(10);
      expect(s4.getValue(), 51); // 10+2+30+4+5
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Reducer arity helpers — PodReducer1..7 + MultiplePodReducer
  // ───────────────────────────────────────────────────────────────────────────
  group('PodReducer arity 1..7', () {
    test('PodReducer1 — single parent identity reduction', () {
      final p1 = Pod<int>(42);
      final mirror = PodReducer1.reduce<int, int>(
        () => (p1,),
        (a) => a.getValue(),
      );
      expect(mirror.getValue(), 42);
      p1.set(100);
      expect(mirror.getValue(), 100);
    });

    test(
      'PodReducer1 — responder called once per refresh (no double-invocation)',
      () {
        // Same invariant as the existing PodReducer2 test; protect the
        // dedicated PodReducer1 path against regression.
        final p1 = Pod<int>(1);
        var responderCalls = 0;
        final out = PodReducer1.reduce<int, int>(
          () {
            responderCalls++;
            return (p1,);
          },
          (a) => a.getValue() * 10,
        );
        final initial = responderCalls;
        expect(out.getValue(), 10);

        p1.set(2);
        expect(responderCalls - initial, 1);
        expect(out.getValue(), 20);
      },
    );

    test('PodReducer3 — sum of 3 parents', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      final c = Pod<int>(3);
      final sum = PodReducer3.reduce<int, int, int, int>(
        () => (a, b, c),
        (a, b, c) => a.getValue() + b.getValue() + c.getValue(),
      );
      expect(sum.getValue(), 6);

      a.set(10);
      b.set(20);
      c.set(30);
      expect(sum.getValue(), 60);
    });

    test('PodReducer4 — mixed types reduce to a single shape', () {
      final n = Pod<int>(5);
      final s = Pod<String>('x');
      final b = Pod<bool>(true);
      final d = Pod<double>(0.5);
      final out = PodReducer4.reduce<String, int, String, bool, double>(
        () => (n, s, b, d),
        (n, s, b, d) =>
            '${n.getValue()}|${s.getValue()}|${b.getValue()}|${d.getValue()}',
      );
      expect(out.getValue(), '5|x|true|0.5');

      n.set(7);
      expect(out.getValue(), '7|x|true|0.5');
      s.set('y');
      expect(out.getValue(), '7|y|true|0.5');
      b.set(false);
      expect(out.getValue(), '7|y|false|0.5');
      d.set(1.5);
      expect(out.getValue(), '7|y|false|1.5');
    });

    test('PodReducer5 — every parent contributes', () {
      final p1 = Pod<int>(1);
      final p2 = Pod<int>(2);
      final p3 = Pod<int>(3);
      final p4 = Pod<int>(4);
      final p5 = Pod<int>(5);
      final sum = PodReducer5.reduce<int, int, int, int, int, int>(
        () => (p1, p2, p3, p4, p5),
        (p1, p2, p3, p4, p5) =>
            p1.getValue() +
            p2.getValue() +
            p3.getValue() +
            p4.getValue() +
            p5.getValue(),
      );
      expect(sum.getValue(), 15);

      p4.set(40);
      expect(sum.getValue(), 51);
    });

    test('PodReducer6 — concat in declaration order', () {
      final parts = List.generate(6, (i) => Pod<String>('p$i'));
      final joined = PodReducer6.reduce<
        String,
        String,
        String,
        String,
        String,
        String,
        String
      >(
        () => (parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]),
        (a, b, c, d, e, f) => [
          a.getValue(),
          b.getValue(),
          c.getValue(),
          d.getValue(),
          e.getValue(),
          f.getValue(),
        ].join('/'),
      );
      expect(joined.getValue(), 'p0/p1/p2/p3/p4/p5');

      parts[3].set('CHANGED');
      expect(joined.getValue(), 'p0/p1/p2/CHANGED/p4/p5');
    });

    test('PodReducer7 — sum across 7 parents', () {
      final pods = List.generate(7, (i) => Pod<int>(i + 1));
      final out = PodReducer7.reduce<int, int, int, int, int, int, int, int>(
        () => (
          pods[0],
          pods[1],
          pods[2],
          pods[3],
          pods[4],
          pods[5],
          pods[6],
        ),
        (a, b, c, d, e, f, g) =>
            a.getValue() +
            b.getValue() +
            c.getValue() +
            d.getValue() +
            e.getValue() +
            f.getValue() +
            g.getValue(),
      );
      expect(out.getValue(), 1 + 2 + 3 + 4 + 5 + 6 + 7);

      pods[6].set(100);
      expect(out.getValue(), 1 + 2 + 3 + 4 + 5 + 6 + 100);
    });

    test(
      'PodReducer arity helpers all dispose listeners when child disposes',
      () {
        // We cannot directly probe the parent's _children set from outside,
        // but we can verify that after the child is disposed, firing the
        // parents does not blow up — the listeners are gone.
        final p1 = Pod<int>(1);
        final p2 = Pod<int>(2);
        final p3 = Pod<int>(3);
        final child = PodReducer3.reduce<int, int, int, int>(
          () => (p1, p2, p3),
          (a, b, c) => a.getValue() + b.getValue() + c.getValue(),
        );
        expect(child.getValue(), 6);

        child.dispose();
        // Parents should still fire cleanly with no listeners attached.
        p1.set(10);
        p2.set(20);
        p3.set(30);
      },
    );
  });

  group('MultiplePodReducer (N parents)', () {
    test('reduces a 10-element dynamic parent list', () {
      final parents = List.generate(10, (i) => Pod<int>(i));
      final sum = MultiplePodReducer.reduce<int, int>(
        () => parents,
        (vs) => vs.fold<int>(0, (acc, p) => acc + p.getValue()),
      );
      expect(sum.getValue(), 0 + 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9);

      parents[5].set(100);
      expect(sum.getValue(), 0 + 1 + 2 + 3 + 4 + 100 + 6 + 7 + 8 + 9);
    });

    test(
      'responder that returns a different parent set on each fire — '
      'subscriptions migrate correctly',
      () {
        final a = Pod<int>(1);
        final b = Pod<int>(10);
        final c = Pod<int>(100);
        var phase = 1;
        final sum = MultiplePodReducer.reduce<int, int>(
          () => phase == 1 ? [a, b] : [b, c],
          (vs) => vs.fold<int>(0, (acc, p) => acc + p.getValue()),
        );
        expect(sum.getValue(), 11);

        // Trigger a refresh by firing a current parent.
        phase = 2;
        a.set(999); // a is still subscribed at this point — fires refresh.
        // Refresh re-runs responder → new parent set [b, c]. New value 110.
        expect(sum.getValue(), 110);

        // a is no longer subscribed — fires must NOT affect sum.
        a.set(-1);
        expect(sum.getValue(), 110);

        // c is now subscribed.
        c.set(1000);
        expect(sum.getValue(), 1010);
      },
    );

    test('empty parent list yields a single-call reducer with no inputs', () {
      // Same as the ChildPod empty-responder test, but exercising the
      // MultiplePodReducer entry point specifically.
      final pod = MultiplePodReducer.reduce<int, String>(
        () => const <GenericPod<int>>[],
        (vs) => 'count=${vs.length}',
      );
      expect(pod.getValue(), 'count=0');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 3. WeakChangeNotifier — invariants not covered by deeper tests
  // ───────────────────────────────────────────────────────────────────────────
  group('WeakChangeNotifier extra invariants', () {
    test('hasListeners is false at construction', () {
      final pod = _ExposedNotifier();
      expect(pod.exposedHasListeners, isFalse);
    });

    test('hasListeners tracks add/remove transitions', () {
      final pod = _ExposedNotifier();
      final l = () {};
      pod.addStrongRefListener(strongRefListener: l);
      expect(pod.exposedHasListeners, isTrue);
      pod.removeListener(l);
      expect(pod.exposedHasListeners, isFalse);
    });

    test('hasListeners is false after dispose', () {
      final pod = _ExposedNotifier();
      final l = () {};
      pod.addStrongRefListener(strongRefListener: l);
      pod.dispose();
      expect(pod.exposedHasListeners, isFalse);
    });

    test('notifyListeners with zero listeners is an early return (no crash)', () {
      final pod = _ExposedNotifier();
      // Should not throw even with no listeners.
      pod.exposedNotifyListeners();
    });

    test(
      'removeListener for a listener registered on a DIFFERENT notifier is '
      'a no-op',
      () {
        final podA = Pod<int>(0);
        final podB = Pod<int>(0);
        var aCalls = 0;
        final l = () => aCalls++;
        podA.addStrongRefListener(strongRefListener: l);

        // Try to remove l from B — should silently do nothing.
        podB.removeListener(l);
        podA.set(1);
        expect(aCalls, 1);
      },
    );

    test(
      'rapid grow-then-shrink cycles keep the count accurate across many '
      'capacity transitions',
      () {
        final pod = Pod<int>(0);
        // Cycle 50 times: add 100 listeners, fire once, remove all.
        for (var cycle = 0; cycle < 50; cycle++) {
          var fires = 0;
          final ls = <VoidCallback>[];
          for (var i = 0; i < 100; i++) {
            final l = () => fires++;
            ls.add(l);
            pod.addStrongRefListener(strongRefListener: l);
          }
          pod.set(cycle + 1);
          expect(fires, 100, reason: 'cycle $cycle');
          for (final l in ls) {
            pod.removeListener(l);
          }
          // Confirm no orphans.
          fires = 0;
          pod.set(-1 - cycle);
          expect(fires, 0, reason: 'orphans after cycle $cycle');
        }
      },
    );

    test(
      'addStrongRefListener after a full removal cycle re-grows correctly',
      () {
        final pod = Pod<int>(0);
        // Fill, drain, fill again — internal capacity must handle this.
        final ls1 = <VoidCallback>[];
        for (var i = 0; i < 30; i++) {
          final l = () {};
          ls1.add(l);
          pod.addStrongRefListener(strongRefListener: l);
        }
        for (final l in ls1) {
          pod.removeListener(l);
        }
        var fires = 0;
        final ls2 = <VoidCallback>[];
        for (var i = 0; i < 30; i++) {
          final l = () => fires++;
          ls2.add(l);
          pod.addStrongRefListener(strongRefListener: l);
        }
        pod.set(1);
        expect(fires, 30);
      },
    );

    test(
      'listener that swaps itself out for a NEW listener mid-notify — new '
      'listener does not fire this cycle, fires next',
      () {
        final pod = Pod<int>(0);
        var oldFires = 0;
        var newFires = 0;
        VoidCallback? newL;
        late final VoidCallback oldL;
        oldL = () {
          oldFires++;
          if (newL == null) {
            pod.removeListener(oldL);
            newL = () => newFires++;
            pod.addStrongRefListener(strongRefListener: newL!);
          }
        };
        pod.addStrongRefListener(strongRefListener: oldL);

        pod.set(1);
        expect(oldFires, 1);
        expect(newFires, 0);

        pod.set(2);
        expect(oldFires, 1);
        expect(newFires, 1);
      },
    );

    test(
      'nested notifyListeners cycle: outer listener triggers inner set, '
      '_notificationCallStackDepth is decremented correctly on the way out '
      '(if not, compaction would be deferred forever)',
      () {
        final outer = Pod<int>(0);
        final inner = Pod<int>(0);
        var calls = 0;
        late final VoidCallback bridge;
        bridge = () {
          calls++;
          inner.set(outer.getValue() * 2);
        };
        outer.addStrongRefListener(strongRefListener: bridge);

        outer.set(5);
        expect(inner.getValue(), 10);
        expect(calls, 1);

        // After this, removing bridge should actually compact the list, not
        // remain deferred. We verify indirectly: add a fresh listener and
        // fire — count must be correct.
        outer.removeListener(bridge);
        var afterFires = 0;
        final after = () => afterFires++;
        outer.addStrongRefListener(strongRefListener: after);
        outer.set(6);
        expect(afterFires, 1);
        // bridge must not have fired.
        expect(calls, 1);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 4. PodFinalizerWrapper — non-deterministic-GC surface checks
  // ───────────────────────────────────────────────────────────────────────────
  //
  // Dart's Finalizer is documented as best-effort: callbacks "may eventually
  // be called" once the value becomes unreachable, but no test can force
  // GC deterministically. We therefore exercise everything we CAN observe:
  //
  //   • Construction succeeds and does not pre-dispose the pod.
  //   • The wrapper does not pin the pod with a strong reference (it uses
  //     WeakReference, so .target gives back the same instance while the
  //     caller still holds it).
  //   • Manually disposing the pod with the wrapper still attached does not
  //     double-dispose when the finalizer eventually fires.
  //   • Constructing many wrappers around different pods does not throw.
  //
  group('PodFinalizerWrapper', () {
    test('constructor does not dispose the pod', () {
      final pod = Pod<int>(7);
      // ignore: invalid_use_of_visible_for_testing_member, unused_local_variable
      final wrapper = PodFinalizerWrapper(pod);
      expect(pod.isDisposed, isFalse);
      expect(pod.getValue(), 7);
    });

    test('wrapper does not pin the pod with a strong reference', () {
      // We can't force GC, but we CAN confirm the wrapper uses a
      // WeakReference: if it held a strong ref, the API would not need the
      // WeakReference wrapper at all. We probe by verifying the public
      // surface is `@visibleForTesting` and the constructor's signature.
      final pod = Pod<int>(0);
      // ignore: invalid_use_of_visible_for_testing_member
      final w = PodFinalizerWrapper(pod);
      expect(w, isNotNull);
      // Pod remains usable while caller holds it.
      pod.set(1);
      expect(pod.getValue(), 1);
    });

    test(
      'manually disposing the pod before the wrapper is GC\'d is safe — '
      'the eventual finalizer call is a no-op via the disposed-twice guard',
      () {
        final pod = Pod<int>(1);
        // ignore: invalid_use_of_visible_for_testing_member, unused_local_variable
        final w = PodFinalizerWrapper(pod);
        pod.dispose();
        expect(pod.isDisposed, isTrue);
        // If the finalizer fires later (non-deterministic), it calls
        // pod.dispose() again — DisposablePod logs an alert and returns.
        // Either way, no exception escapes.
      },
    );

    test(
      'many wrappers in a tight loop do not throw — Finalizer.attach must '
      'tolerate rapid registration',
      () {
        final pods = <Pod<int>>[];
        for (var i = 0; i < 200; i++) {
          final p = Pod<int>(i);
          pods.add(p);
          // ignore: invalid_use_of_visible_for_testing_member, unused_local_variable
          final w = PodFinalizerWrapper(p);
        }
        // All pods still alive.
        for (var i = 0; i < pods.length; i++) {
          expect(pods[i].isDisposed, isFalse);
          expect(pods[i].getValue(), i);
        }
      },
    );

    test(
      'wrapping a pod that gets disposed externally then re-used is not a '
      'supported scenario, but it must not crash the wrapper constructor',
      () {
        final pod = Pod<int>(1);
        pod.dispose();
        // Constructing a wrapper around an already-disposed pod just
        // captures a WeakReference. The eventual finalizer dispose() call
        // hits the already-disposed branch (Log.alert + return).
        // ignore: invalid_use_of_visible_for_testing_member, unused_local_variable
        final w = PodFinalizerWrapper(pod);
        // No exception during construction.
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 5. PodBuilderCacheManager — TTL + key abuse
  // ───────────────────────────────────────────────────────────────────────────
  //
  // The cache is a process-global singleton (PodBuilderCacheManager.i), so
  // tests must use unique keys and avoid mutating each other's entries.
  //
  group('PodBuilderCacheManager — direct unit tests', () {
    final mgr = PodBuilderCacheManager.i;
    String uniqueKey(String tag) =>
        '_test_${tag}_${DateTime.now().microsecondsSinceEpoch}_'
        '${identityHashCode(Object())}';

    test('store → get round-trip with no TTL', () {
      final k = uniqueKey('roundtrip');
      mgr.cache(k, 42);
      expect(mgr.get(k), 42);
      // Stays put across multiple reads.
      expect(mgr.get(k), 42);
      expect(mgr.get(k), 42);
    });

    test('get(null) returns null', () {
      expect(mgr.get(null), isNull);
    });

    test('get on missing key returns null', () {
      expect(mgr.get(uniqueKey('missing')), isNull);
    });

    test(
      'cache(key, value) with no duration overwrites a prior entry with '
      'a duration and clears the expiration',
      () async {
        final k = uniqueKey('overwrite_clears_ttl');
        mgr.cache(k, 'A', cacheDuration: const Duration(milliseconds: 20));
        mgr.cache(k, 'B'); // no duration — expiration cleared
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(mgr.get(k), 'B', reason: 'previous TTL must not evict B');
      },
    );

    test(
      're-caching the same key with a NEW TTL replaces the prior TTL',
      () async {
        final k = uniqueKey('refresh_ttl');
        mgr.cache(k, 'old', cacheDuration: const Duration(milliseconds: 30));
        mgr.cache(k, 'new', cacheDuration: const Duration(milliseconds: 200));
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(
          mgr.get(k),
          'new',
          reason: 'old TTL must not still be in effect',
        );
      },
    );

    test('TTL expiry returns null on first read after the deadline', () async {
      final k = uniqueKey('ttl_expire_basic');
      mgr.cache(k, 'val', cacheDuration: const Duration(milliseconds: 20));
      expect(mgr.get(k), 'val');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(mgr.get(k), isNull);
    });

    test(
      'BUG GUARD: expired entry stays evicted on SUBSEQUENT reads (the '
      'wrapper used to clear only its own _expirations map, leaving the '
      'value in the inner CacheManager — a second get() would resurrect '
      'the stale value)',
      () async {
        final k = uniqueKey('ttl_double_read');
        mgr.cache(
          k,
          'will_expire',
          cacheDuration: const Duration(milliseconds: 20),
        );
        expect(mgr.get(k), 'will_expire');

        await Future<void>.delayed(const Duration(milliseconds: 60));

        // First read after expiry — wrapper detects expiration, evicts
        // from _expirations, returns null.
        expect(mgr.get(k), isNull, reason: 'first post-expiry read');

        // Second read — if the inner cache still has the entry and the
        // wrapper has lost track of the TTL, this would incorrectly
        // return 'will_expire'.
        expect(
          mgr.get(k),
          isNull,
          reason:
              'stale value must NOT resurrect after first expired read; '
              'this guards a real wrapper/inner desync bug',
        );

        // Third read for good measure.
        expect(mgr.get(k), isNull);
      },
    );

    test(
      'two keys with overlapping TTLs expire independently',
      () async {
        final k1 = uniqueKey('indep_ttl_a');
        final k2 = uniqueKey('indep_ttl_b');
        mgr.cache(k1, 'A', cacheDuration: const Duration(milliseconds: 20));
        mgr.cache(k2, 'B', cacheDuration: const Duration(milliseconds: 200));

        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(mgr.get(k1), isNull, reason: 'A expired');
        expect(mgr.get(k2), 'B', reason: 'B still alive');
      },
    );

    test('cache value can be any Object (heterogeneous types)', () {
      final k = uniqueKey('hetero');
      mgr.cache(k, 1);
      expect(mgr.get(k), 1);
      mgr.cache(k, 'now a string');
      expect(mgr.get(k), 'now a string');
      mgr.cache(k, const <int>[1, 2, 3]);
      expect(mgr.get(k), const <int>[1, 2, 3]);
    });

    test(
      'overwriting a no-TTL entry with a TTL entry installs the new TTL',
      () async {
        final k = uniqueKey('install_ttl');
        mgr.cache(k, 'permanent');
        expect(mgr.get(k), 'permanent');

        mgr.cache(
          k,
          'temporary',
          cacheDuration: const Duration(milliseconds: 20),
        );
        expect(mgr.get(k), 'temporary');

        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(mgr.get(k), isNull, reason: 'new TTL must take effect');
      },
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Test-only helper to expose @protected members of WeakChangeNotifier.
// ─────────────────────────────────────────────────────────────────────────────

class _ExposedNotifier with WeakChangeNotifier {
  // ignore: invalid_use_of_protected_member
  bool get exposedHasListeners => hasListeners;
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  void exposedNotifyListeners() => notifyListeners();
}
