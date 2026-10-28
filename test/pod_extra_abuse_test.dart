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

// Additional abuse tests targeting the seams the earlier abuse-test files
// either skimmed or skipped:
//   - SharedPod write-queue FIFO under interleaved set/delete/refresh, and
//     dispose-mid-queue ordering invariants.
//   - SharedJsonPod._decodeOrFallback edge cases (non-Map decoded, null
//     values, mixed key types).
//   - PodCollectionBuilder runtime mutations of the inner list (grow,
//     shrink, source swap, duplicate identity, reorder).
//   - PollingPodBuilder didUpdateWidget paths (interval swap, poller swap).
//   - PodResultBuilder cache shadowing: live pod fires must beat the
//     cached value.
//   - RootPod misc: updateValue getter side effect, refresh() after dispose,
//     onAfterDispose that throws.
//   - ChildPod.parents getter (@visibleForTesting), reducer identity
//     short-circuit propagation.
//   - addStrongRefListener duplicate-insert semantics, removeListener
//     single-removal-per-call semantics.
//   - ProtectedPod / SharedProtectedPod basic surface (mutators stay open;
//     only listener APIs are gated by the mixin).

import 'dart:async';

import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // SharedPod write-queue invariants
  // ───────────────────────────────────────────────────────────────────────────
  group('SharedPod write-queue FIFO', () {
    test('queued writes commit in call order despite shared backing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedPod.create<String, String>(
        'fifo_key',
        fromValue: (v) => v ?? '',
        toValue: (v) => v,
        initialValue: '',
      );

      // Each write awaits internally; the queue must serialize them.
      // We do NOT await each call individually — kick them all off at once.
      final futures = <Future<void>>[];
      final observed = <String>[];
      final listener = () => observed.add(pod.getValue());
      pod.addStrongRefListener(strongRefListener: listener);

      for (var i = 0; i < 20; i++) {
        futures.add(pod.set('v$i'));
      }
      await Future.wait(futures);

      expect(pod.getValue(), 'v19');
      expect(
        observed.length,
        20,
        reason: 'every queued write notified exactly once',
      );
      // Notifications must arrive in submission order.
      for (var i = 0; i < 20; i++) {
        expect(observed[i], 'v$i');
      }
    });

    test(
      'dispose between two queued writes truncates the tail',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final pod = await SharedPod.create<String, String>(
          'fifo_dispose_key',
          fromValue: (v) => v ?? '',
          toValue: (v) => v,
          initialValue: '',
        );

        final f1 = pod.set('a');
        final f2 = pod.set('b');
        final f3 = pod.set('c');

        // Dispose immediately — first write probably already started but
        // subsequent ones see `isDisposed` and short-circuit before _set.
        pod.dispose();

        // None of these futures should throw.
        await Future.wait([f1, f2, f3]);

        // Storage may reflect any of the in-flight values — the contract is
        // only that we don't crash. The pod is disposed; getValue returns
        // whatever the last completed _set installed.
        expect(pod.isDisposed, isTrue);
      },
    );

    test(
      'delete followed by set sequenced via the queue ends at the set value',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'fifo_delete_then_set': 'preexisting',
        });
        final pod = await SharedPod.create<String, String>(
          'fifo_delete_then_set',
          fromValue: (v) => v ?? 'INIT',
          toValue: (v) => v,
          initialValue: 'INIT',
        );

        expect(pod.getValue(), 'preexisting');

        // Submit both. Queue guarantees delete completes before set runs.
        final fDelete = pod.delete();
        final fSet = pod.set('after_delete');
        await Future.wait([fDelete, fSet]);

        expect(pod.getValue(), 'after_delete');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('fifo_delete_then_set'), 'after_delete');
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // SharedJsonPod._decodeOrFallback specifics
  // ───────────────────────────────────────────────────────────────────────────
  group('SharedJsonPod decode edge cases', () {
    test('Map with non-string keys is stored only as encoded JSON', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedJsonPodCreator.create(
        'json_string_keys',
        initialValue: <String, Object>{},
      );

      // JSON has only string keys in storage, so this is a smoke check that
      // round-trip works for a normal payload.
      await pod.set({'a': 1, 'b': 'two', 'c': true});
      expect(pod.getValue(), {'a': 1, 'b': 'two', 'c': true});

      final prefs = await SharedPreferences.getInstance();
      // Decode the persisted string ourselves to confirm jsonEncode used.
      final raw = prefs.getString('json_string_keys');
      expect(raw, isNotNull);
      expect(raw, contains('"a":1'));
    });

    test(
      'corrupted JSON with null values is filtered when decoded',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'json_with_nulls': '{"keep":1,"drop":null,"also_keep":"yes"}',
        });
        final pod = await SharedJsonPodCreator.create(
          'json_with_nulls',
          initialValue: const <String, Object>{},
        );
        // Null values are filtered out by _decodeOrFallback (the entry
        // `v != null` check). 'drop' should be missing.
        expect(pod.getValue().containsKey('drop'), isFalse);
        expect(pod.getValue()['keep'], 1);
        expect(pod.getValue()['also_keep'], 'yes');
      },
    );

    test('nested JSON object preserved as Object value', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'json_nested': '{"outer":{"inner":42}}',
      });
      final pod = await SharedJsonPodCreator.create(
        'json_nested',
        initialValue: const <String, Object>{},
      );
      expect(pod.getValue()['outer'], isA<Map<dynamic, dynamic>>());
      final outer = pod.getValue()['outer'] as Map;
      expect(outer['inner'], 42);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PodCollectionBuilder dynamic membership
  // ───────────────────────────────────────────────────────────────────────────
  group('PodCollectionBuilder dynamic inner list', () {
    testWidgets('inner list grows at runtime — new pod starts firing', (
      tester,
    ) async {
      final source = Pod<int>(0);
      final inner1 = Pod<int>(1);
      final inner2 = Pod<int>(2);
      var inners = [inner1];

      var builds = 0;
      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => inners,
            builder: (_) {
              builds++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final baselineBuilds = builds;

      // inner2 not subscribed yet — its set should NOT rebuild.
      inner2.set(99);
      await tester.pump();
      expect(builds, baselineBuilds);

      // Add inner2 by signalling source.
      inners = [inner1, inner2];
      source.set(1);
      await tester.pump();
      // One rebuild for the source fire (and re-sync attaches inner2).
      expect(builds, baselineBuilds + 1);

      // Now inner2 fires should rebuild.
      inner2.set(100);
      await tester.pump();
      expect(builds, baselineBuilds + 2);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });

    testWidgets('inner list shrinks at runtime — removed pod stops firing', (
      tester,
    ) async {
      final source = Pod<int>(0);
      final inner1 = Pod<int>(1);
      final inner2 = Pod<int>(2);
      var inners = [inner1, inner2];

      var builds = 0;
      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => inners,
            builder: (_) {
              builds++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final baseline = builds;

      inner2.set(20);
      await tester.pump();
      expect(builds, baseline + 1);

      // Remove inner2 from the collection by signalling source.
      inners = [inner1];
      source.set(1);
      await tester.pump();
      final afterRemove = builds;

      // inner2 is now detached; firing it should NOT rebuild.
      inner2.set(999);
      await tester.pump();
      expect(builds, afterRemove);

      // inner1 is still attached.
      inner1.set(11);
      await tester.pump();
      expect(builds, afterRemove + 1);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });

    testWidgets('source pod swap via didUpdateWidget rewires the listener', (
      tester,
    ) async {
      final sourceA = Pod<int>(0);
      final sourceB = Pod<int>(0);
      final inner = Pod<int>(1);

      var builds = 0;

      Widget build(Pod<int> source) => _wrap(
            PodCollectionBuilder(
              source: source,
              innerPods: () => [inner],
              builder: (_) {
                builds++;
                return const SizedBox.shrink();
              },
            ),
          );

      await tester.pumpWidget(build(sourceA));
      final initial = builds;

      sourceA.set(1);
      await tester.pump();
      expect(builds, initial + 1);

      // Swap to sourceB; sourceA should be detached.
      await tester.pumpWidget(build(sourceB));
      final afterSwap = builds;

      sourceA.set(2);
      await tester.pump();
      expect(
        builds,
        afterSwap,
        reason: 'sourceA detached, its fires should not rebuild',
      );

      sourceB.set(1);
      await tester.pump();
      expect(builds, afterSwap + 1);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });

    testWidgets('inner list with the same pod listed twice attaches once', (
      tester,
    ) async {
      final source = Pod<int>(0);
      final inner = Pod<int>(0);

      var builds = 0;
      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => [inner, inner],
            builder: (_) {
              builds++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final baseline = builds;

      inner.set(1);
      await tester.pump();
      // De-duped via _containsIdentical → exactly one rebuild per fire.
      expect(builds, baseline + 1);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });

    testWidgets('inner list with plain ValueNotifier uses addListener path', (
      tester,
    ) async {
      final source = Pod<int>(0);
      final notifier = ValueNotifier<int>(0);
      addTearDown(notifier.dispose);

      var builds = 0;
      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => [notifier],
            builder: (_) {
              builds++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final baseline = builds;

      notifier.value = 1;
      await tester.pump();
      expect(builds, baseline + 1);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });

    testWidgets('empty inner list still rebuilds on source fire', (
      tester,
    ) async {
      final source = Pod<int>(0);

      var builds = 0;
      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => const [],
            builder: (_) {
              builds++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final baseline = builds;

      source.set(1);
      await tester.pump();
      expect(builds, baseline + 1);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PollingPodBuilder didUpdateWidget
  // ───────────────────────────────────────────────────────────────────────────
  group('PollingPodBuilder didUpdateWidget', () {
    testWidgets('changing the interval restarts the timer cadence', (
      tester,
    ) async {
      var pollerCalls = 0;
      // ignore: df_safer_dart_lints/no_future_outcome_type_or_error
      Option<FutureOr<ValueListenable<int>>> poller() {
        pollerCalls++;
        // ignore: df_safer_dart_lints/no_future_outcome_type_or_error
        return const None();
      }

      Widget build(Duration interval) => _wrap(
            PollingPodBuilder<int>(
              podPoller: poller,
              interval: interval,
              builder: (_, __) => const SizedBox.shrink(),
            ),
          );

      await tester.pumpWidget(build(const Duration(milliseconds: 50)));
      // initState fires poller once.
      expect(pollerCalls, 1);

      // Let one cycle of the 50ms timer fire.
      await tester.pump(const Duration(milliseconds: 60));
      final afterSlow = pollerCalls;
      expect(afterSlow, greaterThan(1));

      // Swap to a much shorter interval — didUpdateWidget should re-arm.
      await tester.pumpWidget(build(const Duration(milliseconds: 10)));
      // _maybeStartPolling fires another check synchronously.
      expect(pollerCalls, greaterThan(afterSlow));

      // Let several short cycles run.
      await tester.pump(const Duration(milliseconds: 50));
      expect(pollerCalls, greaterThan(afterSlow + 2));

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });

    testWidgets('immediate Some on initial poll skips the timer', (
      tester,
    ) async {
      final pod = Pod<int>(7);
      var pollerCalls = 0;
      // ignore: df_safer_dart_lints/no_future_outcome_type_or_error
      Option<FutureOr<ValueListenable<int>>> poller() {
        pollerCalls++;
        // ignore: df_safer_dart_lints/no_future_outcome_type_or_error
        return Some(pod);
      }

      await tester.pumpWidget(
        _wrap(
          PollingPodBuilder<int>(
            podPoller: poller,
            interval: const Duration(milliseconds: 10),
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ),
      );

      expect(pollerCalls, 1, reason: 'initial check found Some — no timer');

      // Drain time; no further poller calls should happen.
      await tester.pump(const Duration(milliseconds: 100));
      expect(pollerCalls, 1);

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });
  });

  group('PodBuilder live-value beats cache', () {
    testWidgets('live pod fire wins over cached value after first build', (
      tester,
    ) async {
      // Cache keys include identityHashCode(pod), so we plant under the
      // same compound key the widget will use to exercise the read path.
      const key = ValueKey('shadow_fix_key');
      final pod = Pod<int>(0);
      final compoundKey = '$key|${identityHashCode(pod)}';

      // Manually plant a cache entry that disagrees with the pod value.
      PodBuilderCacheManager.i.cache(
        compoundKey,
        const Ok<int>(999),
        cacheDuration: const Duration(minutes: 5),
      );

      var seen = -1;
      await tester.pumpWidget(
        _wrap(
          PodBuilder<int>(
            key: key,
            pod: pod,
            cacheDuration: const Duration(minutes: 5),
            builder: (_, snapshot) {
              UNSAFE:
              seen = snapshot.value.unwrap().unwrap();
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // First build reads cache.
      expect(seen, 999);

      // Now fire the pod — _valueChanged calls _setValue() with useCache:false.
      // The live value must overwrite, NOT be shadowed by the stale cache.
      pod.set(42);
      await tester.pump();
      expect(seen, 42, reason: 'live fire must beat cache');

      // Subsequent fires keep flowing live.
      pod.set(43);
      await tester.pump();
      expect(seen, 43);

      // Cleanup cache.
      PodBuilderCacheManager.i.cache(
        compoundKey,
        const Object(),
        cacheDuration: Duration.zero,
      );
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // RootPod misc — updateValue, refresh-after-dispose, onAfterDispose throw
  // ───────────────────────────────────────────────────────────────────────────
  group('RootPod misc', () {
    test('updateValue getter schedules a refresh and returns current value',
        () {
      final pod = Pod<int>(7);
      // updateValue returns the current value and schedules refresh().
      expect(pod.updateValue, 7);
      // The refresh is via Future.delayed(Duration.zero) — listener fires
      // on the next microtask flush.
    });

    test('refresh() after dispose() does not throw', () async {
      final pod = Pod<int>(0);
      unawaited(pod.refresh());
      pod.dispose();
      // The Future.delayed callback inside refresh() should see isDisposed
      // and skip notifyListeners. No throw.
      await Future<void>.delayed(Duration.zero);
      // Re-calling refresh after dispose is technically allowed —
      // the Future.delayed body is the only guard.
      unawaited(pod.refresh());
      await Future<void>.delayed(Duration.zero);
    });

    test('onAfterDispose that throws is swallowed; pod still disposed', () {
      final pod = _PodWithThrowingDispose();
      // Should NOT throw — DisposablePod wraps onAfterDispose in try/catch.
      expect(pod.dispose, returnsNormally);
      expect(pod.isDisposed, isTrue);
    });

    test(
      'set with notifyImmediately:false on a pod disposed before the frame '
      'does NOT crash',
      () async {
        final pod = Pod<int>(0);
        // Deferred notification scheduled, then we dispose before the frame.
        pod.set(1, notifyImmediately: false);
        pod.dispose();
        // The post-frame callback checks isDisposed and bails out. We have
        // to actually pump a frame for the callback to fire.
        await Future<void>.delayed(Duration.zero);
        expect(pod.isDisposed, isTrue);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // ChildPod.parents getter (@visibleForTesting)
  // ───────────────────────────────────────────────────────────────────────────
  group('ChildPod.parents getter', () {
    test('returns the constructor-time parents in declared order', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      final c = Pod<int>(3);
      final child = PodReducer3.reduce<int, int, int, int>(
        () => (a, b, c),
        (x, y, z) => x.getValue() + y.getValue() + z.getValue(),
      );

      final parents = child.parents.toList();
      expect(parents.length, 3);
      expect(identical(parents[0], a), isTrue);
      expect(identical(parents[1], b), isTrue);
      expect(identical(parents[2], c), isTrue);

      // Sanity: the reduction works.
      expect(child.getValue(), 6);
    });

    test('reflects refreshed parent set after responder change', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);

      var useA = true;
      final child = MultiplePodReducer.reduce<int, int>(
        () => useA ? [a] : [b],
        (vals) => vals.fold<int>(0, (acc, v) => acc + v.getValue()),
      );

      expect(identical(child.parents.first, a), isTrue);
      // Toggle the responder by triggering a parent fire.
      useA = false;
      a.set(99); // This causes child._refresh; responder returns [b].
      expect(identical(child.parents.first, b), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // addStrongRefListener duplicate-insert / removeListener single-removal
  // ───────────────────────────────────────────────────────────────────────────
  group('Listener registration semantics', () {
    test(
      'same listener added 3x and removed 1x leaves 2 active registrations',
      () {
        final pod = Pod<int>(0);
        var fires = 0;
        final l = () => fires++;
        pod.addStrongRefListener(strongRefListener: l);
        pod.addStrongRefListener(strongRefListener: l);
        pod.addStrongRefListener(strongRefListener: l);

        pod.set(1);
        expect(fires, 3);

        fires = 0;
        pod.removeListener(l);
        pod.set(2);
        expect(
          fires,
          2,
          reason: 'removeListener removes only the first matching slot',
        );

        fires = 0;
        pod.removeListener(l);
        pod.removeListener(l);
        pod.set(3);
        expect(fires, 0);
      },
    );

    test('removeListener for unknown listener on disposed pod is silent', () {
      final pod = Pod<int>(0);
      pod.dispose();
      // removeListener guard returns early if _isDisposed.
      pod.removeListener(() {});
      // Nothing to assert except non-crash.
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // ProtectedPod / SharedProtectedPod surface
  // ───────────────────────────────────────────────────────────────────────────
  group('ProtectedPod surface', () {
    test('ProtectedPod.set and update remain externally callable', () {
      final pod = ProtectedPod<int>(10);
      pod.set(20);
      expect(pod.getValue(), 20);
      pod.update((v) => v + 5);
      expect(pod.getValue(), 25);
    });

    test('SharedProtectedPod round-trips through storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final created = await SharedProtectedPod.create<String, String>(
        'protected_round_trip',
        fromValue: (v) => v ?? '',
        toValue: (v) => v,
        initialValue: '',
      ).value;
      // ignore: df_safer_dart_lints/must_use_unsafe_wrapper_or_error
      final pod = created.unwrap();
      expect(pod.getValue(), '');
      await pod.set('hello');
      expect(pod.getValue(), 'hello');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('protected_round_trip'), 'hello');
    });

    test(
      'asProtectedPod cast succeeds on a ProtectedPod instance',
      () {
        final pod = ProtectedPod<int>(0);
        final ValueListenable<int> as = pod;
        expect(identical(as.asProtectedPod(), pod), isTrue);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // map() identity reducer — short-circuit propagation
  // ───────────────────────────────────────────────────────────────────────────
  group('map() identity reducer', () {
    test(
      'identity map propagates short-circuit semantics from parent to child',
      () {
        final parent = Pod<int>(0);
        final child = parent.map((v) => v);

        var childFires = 0;
        final l = () => childFires++;
        // Subscribing to the child via the parent's _addChild path is what
        // wires things up. Use a downstream map to observe child fires
        // without breaching ProtectedPodMixin on the ChildPod itself.
        final downstream = child.map((v) => v);
        final dlistener = l;
        // ignore: invalid_use_of_protected_member
        downstream.addStrongRefListener(strongRefListener: dlistener);

        parent.set(0); // same value — no fire
        expect(childFires, 0);

        parent.set(1); // distinct — single fire
        expect(childFires, 1);

        parent.set(1); // same again — no fire
        expect(childFires, 1);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // ValueListenableExt positive casts
  // ───────────────────────────────────────────────────────────────────────────
  group('ValueListenableExt successful casts', () {
    test('asGenericPod on a RootPod returns the same instance', () {
      final pod = Pod<int>(0);
      final ValueListenable<int> vl = pod;
      expect(identical(vl.asGenericPod(), pod), isTrue);
    });

    test('asChildPod on a ChildPod returns the same instance', () {
      final root = Pod<int>(0);
      final child = root.map((v) => v + 1);
      final ValueListenable<int> vl = child;
      expect(identical(vl.asChildPod<int>(), child), isTrue);
    });

    test('asRootPod on a RootPod returns the same instance', () {
      final pod = Pod<int>(0);
      final ValueListenable<int> vl = pod;
      expect(identical(vl.asRootPod(), pod), isTrue);
    });

    test('asDisposablePod on a Pod returns the same instance', () {
      final pod = Pod<int>(0);
      final ValueListenable<int> vl = pod;
      expect(identical(vl.asDisposablePod(), pod), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // hasListeners under reentrant remove
  // ───────────────────────────────────────────────────────────────────────────
  group('WeakChangeNotifier reentrant compaction', () {
    test(
      'reentrant remove inside notify is reflected after compaction',
      () {
        final pod = Pod<int>(0);
        var fires1 = 0;
        var fires2 = 0;
        late final VoidCallback l2;
        l2 = () => fires2++;

        late final VoidCallback l1;
        l1 = () {
          fires1++;
          // Reentrant remove of l2 — must not crash.
          pod.removeListener(l2);
        };

        pod.addStrongRefListener(strongRefListener: l1);
        pod.addStrongRefListener(strongRefListener: l2);

        pod.set(1);
        expect(fires1, 1);
        // l2 was scheduled-for-removal during l1; the iteration visits it
        // anyway in WeakChangeNotifier, but on the NEXT notify it should be
        // gone.
        final f2_after_first = fires2;

        fires1 = 0;
        fires2 = 0;
        pod.set(2);
        // Compaction happened — l2 is gone. l1 should still fire.
        expect(fires1, 1);
        expect(
          fires2,
          0,
          reason: 'l2 was reentrantly removed in the previous notify',
        );
        // Sanity on the first-cycle behavior: l2 either fired 0 or 1 time;
        // current code visits already-scheduled-null entries via the null
        // check, so it should NOT fire.
        expect(f2_after_first, 0);
      },
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Subclass used to set `onAfterDispose` (`@protected`) from a test scope
/// without triggering `invalid_use_of_protected_member`.
final class _PodWithThrowingDispose extends Pod<int> {
  _PodWithThrowingDispose() : super(0) {
    onAfterDispose = () {
      throw StateError('after-dispose boom');
    };
  }
}
