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

// Abuse tests targeting gaps left by the other suites. Focus areas:
//   - Equality-short-circuit behaviour on types not yet probed (DateTime,
//     Duration, BigInt, Symbol, Equatable, records).
//   - update() / in-place mutation of non-comparable values.
//   - Pod.fromStream error-handler routing and stream lifecycle.
//   - ChildPod / ReducerPod with degenerate inputs (empty responder, all-None,
//     duplicate parents, self-as-parent).
//   - PodCollectionBuilder interop with non-WeakChangeNotifier listenables.
//   - PollingPodBuilder timer hygiene.
//   - ValueListenableExt cast failures.
//   - Full round-trip coverage of every SharedPod primitive helper.
//   - Builder cache key/type collisions across pumps.

import 'dart:async';

import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // Equality short-circuit — types not covered elsewhere
  // ───────────────────────────────────────────────────────────────────────────
  group('Equality short-circuit — additional types', () {
    test('DateTime: same instant does NOT notify', () {
      final t = DateTime.utc(2024, 1, 1);
      final pod = Pod<DateTime>(t);
      var calls = 0;
      final l = () => calls++;
      pod.addStrongRefListener(strongRefListener: l);

      // Same instant, different instance — value equality should short-circuit.
      pod.set(DateTime.utc(2024, 1, 1));
      expect(calls, 0, reason: 'DateTime uses value equality');

      pod.set(DateTime.utc(2024, 1, 2));
      expect(calls, 1);
    });

    test('Duration: equal durations do NOT notify', () {
      final pod = Pod<Duration>(const Duration(seconds: 5));
      var calls = 0;
      final l = () => calls++;
      pod.addStrongRefListener(strongRefListener: l);

      pod.set(const Duration(seconds: 5));
      expect(calls, 0);

      pod.set(const Duration(milliseconds: 5001));
      expect(calls, 1);
    });

    test('BigInt: equal values do NOT notify', () {
      final pod = Pod<BigInt>(BigInt.parse('99999999999999999999'));
      var calls = 0;
      final l = () => calls++;
      pod.addStrongRefListener(strongRefListener: l);

      pod.set(BigInt.parse('99999999999999999999'));
      expect(calls, 0);

      pod.set(BigInt.parse('99999999999999999998'));
      expect(calls, 1);
    });

    test('Symbol: equal symbols do NOT notify', () {
      final pod = Pod<Symbol>(#foo);
      var calls = 0;
      final l = () => calls++;
      pod.addStrongRefListener(strongRefListener: l);

      pod.set(#foo);
      expect(calls, 0);

      pod.set(#bar);
      expect(calls, 1);
    });

    test('Equatable subclass: equal values do NOT notify', () {
      final pod = Pod<_Point>(const _Point(1, 2));
      var calls = 0;
      final l = () => calls++;
      pod.addStrongRefListener(strongRefListener: l);

      // New instance, structurally equal — Equatable hits the short-circuit.
      pod.set(const _Point(1, 2));
      expect(calls, 0);

      pod.set(const _Point(1, 3));
      expect(calls, 1);
    });

    test(
      'record types: equal records DO notify (records are not Comparable '
      'or Equatable, so isDefinitelyComparableOrEquatable returns false)',
      () {
        // Documents an intentional limitation of the short-circuit — records
        // are value-equal in Dart 3, but the heuristic only short-circuits
        // for known marker types. Users who care should wrap with Equatable.
        final pod = Pod<(int, int)>((1, 2));
        var calls = 0;
        final l = () => calls++;
        pod.addStrongRefListener(strongRefListener: l);

        pod.set((1, 2));
        expect(calls, 1, reason: 'records bypass the equality short-circuit');
      },
    );

    test('Set: equal-content set DOES notify (not Comparable/Equatable)', () {
      final pod = Pod<Set<int>>({1, 2, 3});
      var calls = 0;
      final l = () => calls++;
      pod.addStrongRefListener(strongRefListener: l);

      pod.set({1, 2, 3});
      expect(calls, 1);
    });

    test('String: identical instance does NOT notify (Comparable)', () {
      // Probes the identity path for canonicalised strings.
      const s = 'canon';
      final pod = Pod<String>(s);
      var calls = 0;
      final l = () => calls++;
      pod.addStrongRefListener(strongRefListener: l);

      pod.set(s);
      expect(calls, 0);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // update() behaviour with in-place mutation
  // ───────────────────────────────────────────────────────────────────────────
  group('update() with in-place mutation', () {
    test(
      'returning the same int after no change does NOT notify',
      () {
        final pod = Pod<int>(5);
        var calls = 0;
        final l = () => calls++;
        pod.addStrongRefListener(strongRefListener: l);

        pod.update((n) => n);
        expect(calls, 0);
      },
    );

    test(
      'mutating a List in place and returning the same instance DOES notify',
      () {
        // Lists are not Comparable/Equatable — the short-circuit does not
        // apply, so a same-instance return after mutation still propagates.
        final pod = Pod<List<int>>([1, 2, 3]);
        var calls = 0;
        var lastSeen = const <int>[];
        final l = () {
          calls++;
          lastSeen = pod.getValue();
        };
        pod.addStrongRefListener(strongRefListener: l);

        pod.update((list) {
          list.add(4);
          return list;
        });
        expect(calls, 1);
        expect(lastSeen, [1, 2, 3, 4]);
      },
    );

    test('update() with throwing updater propagates the error', () {
      final pod = Pod<int>(1);
      expect(
        () => pod.update((_) => throw StateError('boom')),
        throwsStateError,
      );
      // Pod value untouched after the throw.
      expect(pod.getValue(), 1);
    });

    test('update() with notifyImmediately: false defers via post-frame', () {
      // We can't directly observe the post-frame scheduling without a
      // WidgetsBinding pump, so just verify the call doesn't crash and the
      // value updates synchronously.
      final pod = Pod<int>(1);
      pod.update((n) => n + 1, notifyImmediately: false);
      expect(pod.getValue(), 2);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Pod.fromStream — error-handler routing
  // ───────────────────────────────────────────────────────────────────────────
  group('Pod.fromStream error routing', () {
    test('custom onError handler receives the error', () async {
      final controller = StreamController<int>();
      Object? capturedError;
      final pod = Pod<int>.fromStream(
        controller.stream,
        initialValue: 0,
        onError: (e, _) => capturedError = e,
      );

      final boom = StateError('stream boom');
      controller.addError(boom);
      await Future<void>.delayed(Duration.zero);

      expect(capturedError, isA<StateError>());
      expect((capturedError as StateError).message, 'stream boom');

      await controller.close();
      pod.dispose();
    });

    test('subsequent values still arrive after a handled error', () async {
      final controller = StreamController<int>();
      var errors = 0;
      final pod = Pod<int>.fromStream(
        controller.stream,
        initialValue: 0,
        onError: (_, __) => errors++,
      );

      controller.add(1);
      controller.addError('e');
      controller.add(2);
      await Future<void>.delayed(Duration.zero);

      expect(errors, 1);
      expect(pod.getValue(), 2);

      await controller.close();
      pod.dispose();
    });

    test('broadcast stream is supported', () async {
      final controller = StreamController<int>.broadcast();
      final pod = Pod<int>.fromStream(controller.stream, initialValue: 0);

      controller.add(42);
      await Future<void>.delayed(Duration.zero);
      expect(pod.getValue(), 42);

      pod.dispose();
      await controller.close();
    });

    test(
      'closing the stream while the pod is alive does not throw or '
      'corrupt the value',
      () async {
        final controller = StreamController<int>();
        final pod = Pod<int>.fromStream(controller.stream, initialValue: 0);
        controller.add(1);
        await Future<void>.delayed(Duration.zero);
        await controller.close();

        // Pod stays at the last emitted value; no further events possible.
        expect(pod.getValue(), 1);
        pod.dispose();
      },
    );

    test(
      'equality short-circuit applies to stream-driven sets',
      () async {
        final controller = StreamController<int>();
        final pod = Pod<int>.fromStream(controller.stream, initialValue: 0);
        var calls = 0;
        final l = () => calls++;
        pod.addStrongRefListener(strongRefListener: l);

        controller.add(7);
        controller.add(7); // equal — must not notify twice
        controller.add(8);
        await Future<void>.delayed(Duration.zero);

        expect(calls, 2, reason: '0→7→8, the duplicate 7 short-circuits');

        await controller.close();
        pod.dispose();
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // ChildPod / ReducerPod degenerate inputs
  // ───────────────────────────────────────────────────────────────────────────
  group('ChildPod degenerate inputs', () {
    test(
      'empty responder list — reducer receives empty input and runs cleanly',
      () {
        final pod = ChildPod<int, String>(
          responder: () => const <GenericPod<int>>[],
          reducer: (vs) => 'len=${vs.length}',
        );
        expect(pod.getValue(), 'len=0');
      },
    );

    test('responder returning the same parent twice subscribes twice', () {
      // Documented expectation: ChildPod does not dedupe. The reducer sees
      // the same parent value twice; subsequent parent updates fire the
      // child once per subscription.
      final parent = Pod<int>(1);
      var refreshes = 0;
      final pod = ChildPod<int, int>(
        responder: () => [parent, parent],
        reducer: (vs) {
          refreshes++;
          return vs.fold(0, (a, b) => a + b);
        },
      );
      expect(pod.getValue(), 2);

      final before = refreshes;
      parent.set(10);
      // Each subscription fires the refresh closure. The internal _isDirty
      // guard collapses cascaded fires within a single dispatch, so we
      // expect at least one rebuild and a correct final value.
      expect(pod.getValue(), 20);
      expect(refreshes, greaterThan(before));
    });

    test('mid-chain ChildPod disposal does not break the sibling chain', () {
      // root -> midA (disposed) — midB (alive) should keep working.
      final root = Pod<int>(1);
      final midA = root.map((v) => v + 10);
      final midB = root.map((v) => v * 100);

      midA.dispose();
      expect(midA.isDisposed, isTrue);
      expect(midB.isDisposed, isFalse);

      root.set(2);
      expect(midB.getValue(), 200);
      // Firing root once more after a child is gone must not crash.
      root.set(3);
      expect(midB.getValue(), 300);
    });
  });

  group('ReducerPod degenerate inputs', () {
    test(
      'all-None initial responder leaves value uninitialised AND the pod '
      'stays stuck — _refresh is only attached to parents the responder '
      'originally yielded as Some, so nothing can wake it up later',
      () {
        var allowSome = false;
        final inner = Pod<int>(0);
        final pod = ReducerPod<int>(
          responder: () => [if (allowSome) Some(inner) else const None()],
          reducer: (vs) => allowSome ? const Some(9) : const None(),
        );

        // Initial reducer returned None — value never initialised.
        expect(() => pod.getValue(), throwsA(isA<Error>()));

        // Flipping the switch on its own changes nothing — the inner pod was
        // never subscribed (responder returned None at construction), so
        // setting it cannot trigger a refresh.
        allowSome = true;
        inner.set(1);
        expect(
          () => pod.getValue(),
          throwsA(isA<Error>()),
          reason: 'a stuck reducer pod has no path back to alive',
        );
      },
    );

    test(
      'reducer that returns None on a subsequent refresh keeps the prior '
      'value (does not clear it)',
      () {
        var emitSome = true;
        final src = Pod<int>(1);
        final pod = ReducerPod<int>(
          responder: () => [Some(src)],
          reducer: (vs) {
            if (!emitSome) return const None();
            UNSAFE:
            return Some(vs.first.unwrap() as int);
          },
        );
        expect(pod.getValue(), 1);

        emitSome = false;
        src.set(2); // reducer returns None — _set is skipped
        expect(
          pod.getValue(),
          1,
          reason: 'prior value retained when reducer yields None',
        );

        emitSome = true;
        src.set(3);
        expect(pod.getValue(), 3);
      },
    );

    test('mixed ValueListenable parents (plain ValueNotifier) work', () {
      final notifier = ValueNotifier<int>(10);
      final pod = Pod<int>(5);
      final sum = ReducerPod<int>(
        responder: () => [Some(pod), Some(notifier)],
        reducer: (vs) {
          var total = 0;
          for (final v in vs) {
            UNSAFE:
            if (v.isSome()) total += v.unwrap() as int;
          }
          return Some(total);
        },
      );
      expect(sum.getValue(), 15);

      notifier.value = 20;
      expect(sum.getValue(), 25);

      pod.set(6);
      expect(sum.getValue(), 26);

      notifier.dispose();
    });

    test('disposing a ReducerPod does NOT dispose its parents', () {
      final a = Pod<int>(1);
      final b = Pod<int>(2);
      final r = ReducerPod<int>(
        responder: () => [Some(a), Some(b)],
        reducer: (vs) {
          var total = 0;
          for (final v in vs) {
            UNSAFE:
            if (v.isSome()) total += v.unwrap() as int;
          }
          return Some(total);
        },
      );
      expect(r.getValue(), 3);

      r.dispose();
      expect(r.isDisposed, isTrue);
      expect(a.isDisposed, isFalse);
      expect(b.isDisposed, isFalse);

      // Parents still functional and won't try to fire the dead reducer.
      a.set(10);
      b.set(20);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // cond() abuse
  // ───────────────────────────────────────────────────────────────────────────
  group('cond() abuse', () {
    test('predicate that throws on the initial sync check propagates', () {
      final pod = Pod<int>(0);
      expect(
        () => pod.cond((_) => throw StateError('bad predicate')),
        throwsStateError,
      );
      // No listener was added; subsequent fires don't re-throw.
      pod.set(1);
    });

    test(
      'predicate that throws on a later notify is reported via FlutterError, '
      'not propagated to the setter',
      () {
        final pod = Pod<int>(0);
        var checks = 0;
        // ignore: unused_local_variable
        final unused = pod.cond((v) {
          checks++;
          if (checks > 1) throw StateError('later boom');
          return false;
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
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PodCollectionBuilder — plain Listenable interop
  // ───────────────────────────────────────────────────────────────────────────
  group('PodCollectionBuilder interop', () {
    testWidgets('source is a plain ValueNotifier (not a WeakChangeNotifier)', (
      tester,
    ) async {
      final source = ValueNotifier<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => const <Listenable>[],
            builder: (_) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(buildCount, 1);

      source.value = 1;
      await tester.pump();
      expect(buildCount, 2);

      // Detach via teardown — ValueNotifier should not be leaked.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      // No reliable runtime introspection of ValueNotifier listeners, but
      // we can fire it post-detach and confirm no callback runs.
      source.value = 2;
      await tester.pump();
      expect(buildCount, 2);

      source.dispose();
    });

    testWidgets('mixed inner pods: Pod + ValueNotifier in the same list', (
      tester,
    ) async {
      final source = Pod<int>(0);
      final pod = Pod<int>(0);
      final vn = ValueNotifier<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => [pod, vn],
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
      expect(buildCount, initial + 1);

      vn.value = 99;
      await tester.pump();
      expect(buildCount, initial + 2);

      vn.dispose();
    });

    testWidgets('innerPods returning the same pod twice fires twice per set', (
      tester,
    ) async {
      // _syncSubscriptions diffs by identity but does not dedupe duplicates
      // within a single returned list — duplicates produce parallel
      // subscriptions, so a single fire causes two _onChange invocations.
      // Flutter coalesces the resulting setState calls, but we can probe
      // the underlying invariant by counting using a manual listenable.
      final source = Pod<int>(0);
      final inner = Pod<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        _wrap(
          PodCollectionBuilder(
            source: source,
            innerPods: () => [inner, inner],
            builder: (_) {
              buildCount++;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final initial = buildCount;

      inner.set(1);
      await tester.pump();
      // setState coalesces within a frame, so the user-visible rebuild count
      // is 1 even if the listener fired twice.
      expect(buildCount - initial, 1);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PollingPodBuilder timer hygiene
  // ───────────────────────────────────────────────────────────────────────────
  group('PollingPodBuilder', () {
    testWidgets(
      'poller returning None never resolves; rebuilds zero times after mount',
      (tester) async {
        var pollerCalls = 0;
        var builds = 0;

        await tester.pumpWidget(
          _wrap(
            PollingPodBuilder<int>(
              podPoller: () {
                pollerCalls++;
                return const None();
              },
              interval: const Duration(milliseconds: 50),
              builder: (_, __) {
                builds++;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(pollerCalls, 1);
        expect(builds, 1);

        // Let the timer tick a couple of times.
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump(const Duration(milliseconds: 60));
        expect(pollerCalls, greaterThan(1));
        // No build: setState is only called when the poller returns Some.
        expect(builds, 1);

        // Detach.
        await tester.pumpWidget(_wrap(const SizedBox.shrink()));
        final beforeDetach = pollerCalls;
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          pollerCalls,
          beforeDetach,
          reason: 'timer cancelled on dispose',
        );
      },
    );

    testWidgets('poller transitions None → Some and the timer self-cancels', (
      tester,
    ) async {
      Pod<int>? resolved;
      var pollerCalls = 0;

      await tester.pumpWidget(
        _wrap(
          PollingPodBuilder<int>(
            podPoller: () {
              pollerCalls++;
              final r = resolved;
              return r == null ? const None() : Some(r);
            },
            interval: const Duration(milliseconds: 30),
            builder: (_, snap) {
              return Text(
                snap.value.isSome()
                    // ignore: invalid_use_of_visible_for_testing_member
                    ? '${snap.value.unwrap().unwrap()}'
                    : 'pending',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );
      expect(find.text('pending'), findsOneWidget);

      resolved = Pod<int>(99);
      // Wait a couple of ticks for the poll to fire.
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump();
      expect(find.text('99'), findsOneWidget);

      final settledCalls = pollerCalls;
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        pollerCalls,
        settledCalls,
        reason: 'timer self-cancels once a pod resolves',
      );

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // ValueListenableExt — wrong-cast TypeErrors
  // ───────────────────────────────────────────────────────────────────────────
  group('ValueListenableExt cast failures', () {
    test('asRootPod on a ChildPod throws TypeError', () {
      final parent = Pod<int>(1);
      final ValueListenable<int> child = parent.map((v) => v + 1);
      expect(() => child.asRootPod(), throwsA(isA<TypeError>()));
    });

    test('asChildPod on a RootPod throws TypeError', () {
      final ValueListenable<int> root = Pod<int>(1);
      expect(() => root.asChildPod<int>(), throwsA(isA<TypeError>()));
    });

    test('asSharedPod on a RootPod throws TypeError', () {
      final ValueListenable<int> root = Pod<int>(1);
      expect(() => root.asSharedPod<int>(), throwsA(isA<TypeError>()));
    });

    test('asDisposablePod on a plain ValueNotifier throws TypeError', () {
      final vn = ValueNotifier<int>(1);
      expect(() => vn.asDisposablePod(), throwsA(isA<TypeError>()));
      vn.dispose();
    });

    test('asValueListenable returns the same instance (identity preserved)',
        () {
      final pod = Pod<int>(1);
      expect(identical(pod.asValueListenable(), pod), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // SharedPod — full primitive matrix
  // ───────────────────────────────────────────────────────────────────────────
  group('Shared*Pod round-trip', () {
    test('SharedBoolPod persists and reads back', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedBoolPodCreator.create(
        'abuse_bool',
        initialValue: false,
      );
      expect(pod.getValue(), isFalse);
      await pod.set(true);
      expect(pod.getValue(), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('abuse_bool'), isTrue);
    });

    test('SharedIntPod persists and reads back', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedIntPodCreator.create(
        'abuse_int',
        initialValue: 0,
      );
      await pod.set(123);
      expect(pod.getValue(), 123);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('abuse_int'), 123);
    });

    test('SharedDoublePod persists and reads back', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedDoublePodCreator.create(
        'abuse_double',
        initialValue: 0.0,
      );
      await pod.set(3.14);
      expect(pod.getValue(), 3.14);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('abuse_double'), 3.14);
    });

    test('SharedStringPod persists and reads back', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedStringPodCreator.create(
        'abuse_string',
        initialValue: '',
      );
      await pod.set('hello');
      expect(pod.getValue(), 'hello');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('abuse_string'), 'hello');
    });

    test('SharedStringListPod persists and reads back', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedStringListPodCreator.create(
        'abuse_strlist',
        initialValue: const [],
      );
      await pod.set(['a', 'b', 'c']);
      expect(pod.getValue(), ['a', 'b', 'c']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('abuse_strlist'), ['a', 'b', 'c']);
    });

    test('SharedEnumPod uses case-insensitive lookup on read', () async {
      // Storage might be mutated by another app version using a different
      // casing convention — the lookup tolerates that.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'abuse_enum': 'B', // stored as uppercase
      });
      final pod = await SharedEnumPodCreator.create<_Color>(
        'abuse_enum',
        options: _Color.values,
        initialValue: _Color.a,
      );
      expect(pod.getValue(), _Color.b);
    });

    test('SharedEnumPod falls back to initialValue for unknown names',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'abuse_enum_unknown': 'not_an_option',
      });
      final pod = await SharedEnumPodCreator.create<_Color>(
        'abuse_enum_unknown',
        options: _Color.values,
        initialValue: _Color.a,
      );
      expect(pod.getValue(), _Color.a);
    });

    test('SharedPod.delete resets to initialValue', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedPod.create<String, String>(
        'abuse_del',
        fromValue: (v) => v ?? 'INIT',
        toValue: (v) => v,
        initialValue: 'INIT',
      );

      await pod.set('value');
      expect(pod.getValue(), 'value');

      await pod.delete();
      expect(pod.getValue(), 'INIT');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('abuse_del'), isFalse);
    });

    test('SharedPod with unsupported toValue type throws on set', () async {
      // toValue produces a `DateTime`, which SharedPreferences does not
      // accept — the switch in `set` should reject it with an Err.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final pod = await SharedPod.create<DateTime, DateTime>(
        'abuse_bad_type',
        fromValue: (_) => DateTime.utc(2024),
        toValue: (v) => v,
        initialValue: DateTime.utc(2024),
      );

      // The error surfaces through the write queue's future.
      await expectLater(
        pod.set(DateTime.utc(2025)),
        throwsA(isA<Object>()),
      );
    });

    test(
      'SharedPod dispose during pending write — write completes without '
      'firing a disposed-pod assertion',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final pod = await SharedPod.create<String, String>(
          'abuse_dispose_pending',
          fromValue: (v) => v ?? '',
          toValue: (v) => v,
          initialValue: '',
        );

        final pending = pod.set('hello');
        pod.dispose();
        await pending; // must not throw

        // Storage still got written even though the pod skipped _set.
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('abuse_dispose_pending'),
          anyOf(isNull, 'hello'),
        );
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Builder cache — key / type collisions
  // ───────────────────────────────────────────────────────────────────────────
  group('PodBuilder cache key/type collisions', () {
    testWidgets(
      'cache entry from a previous pod with the same key is overwritten '
      'by the new pod on mount',
      (tester) async {
        final key =
            ValueKey('abuse_cache_${DateTime.now().microsecondsSinceEpoch}');
        final podA = Pod<int>(111);
        var seen = -1;

        Widget make(Pod<int> p) => _wrap(
              PodBuilder<int>(
                key: key,
                pod: p,
                cacheDuration: const Duration(seconds: 30),
                builder: (_, snapshot) {
                  UNSAFE:
                  seen = snapshot.value.unwrap().unwrap();
                  return const SizedBox.shrink();
                },
              ),
            );

        await tester.pumpWidget(make(podA));
        expect(seen, 111);

        // Tear down and remount with a new pod under the same key.
        await tester.pumpWidget(_wrap(const SizedBox.shrink()));

        final podB = Pod<int>(222);
        await tester.pumpWidget(make(podB));
        // First build uses the cached value from podA.
        expect(seen, 111);

        // After podB fires, the live value wins.
        podB.set(333);
        await tester.pump();
        expect(seen, 333);

        // Drain the cache TTL so the entry is gone for next time.
        PodBuilderCacheManager.i.cache(
          key.toString(),
          const Object(),
          cacheDuration: Duration.zero,
        );
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // WeakChangeNotifier — last-resort invariants
  // ───────────────────────────────────────────────────────────────────────────
  group('WeakChangeNotifier invariants', () {
    test('set on a pod with zero listeners is a no-op (no crash)', () {
      final pod = Pod<int>(0);
      pod.set(1);
      pod.set(2);
      pod.set(3);
      expect(pod.getValue(), 3);
    });

    test(
      'listener that removes EVERY listener mid-cycle keeps the dispatch '
      'consistent',
      () {
        final pod = Pod<int>(0);
        final ls = <VoidCallback>[];
        var fires = 0;
        for (var i = 0; i < 10; i++) {
          final l = () => fires++;
          ls.add(l);
          pod.addStrongRefListener(strongRefListener: l);
        }
        // Insert a nuker at the front that removes all of the above.
        final nuker = () {
          for (final l in ls) {
            pod.removeListener(l);
          }
        };
        // Add nuker LAST so it runs after all 10 fired in this cycle.
        pod.addStrongRefListener(strongRefListener: nuker);

        pod.set(1);
        expect(fires, 10);

        fires = 0;
        pod.set(2);
        // All 10 removed; only the nuker remains.
        expect(fires, 0);
      },
    );

    test(
      'addSingleExecutionListener whose body throws still self-removes',
      () {
        // Documents that a one-shot listener is removed *after* its body
        // runs (via the try/finally inside the temp wrapper), so a throw
        // does not leave the wrapper attached.
        final pod = Pod<int>(0);
        var fires = 0;
        pod.addSingleExecutionListener(() {
          fires++;
          throw StateError('one-shot boom');
        });

        final prev = FlutterError.onError;
        FlutterError.onError = (_) {};
        try {
          pod.set(1);
          pod.set(2);
        } finally {
          FlutterError.onError = prev;
        }
        expect(fires, 1, reason: 'self-removed after the throw');
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // ChildPod / map() chain lifecycle
  // ───────────────────────────────────────────────────────────────────────────
  group('map() chain lifecycle', () {
    test('same parent mapped twice produces independent children', () {
      final parent = Pod<int>(1);
      final c1 = parent.map((v) => v * 2);
      final c2 = parent.map((v) => v + 100);
      expect(c1.getValue(), 2);
      expect(c2.getValue(), 101);

      parent.set(5);
      expect(c1.getValue(), 10);
      expect(c2.getValue(), 105);

      // Disposing c1 should not affect c2.
      c1.dispose();
      parent.set(7);
      expect(c2.getValue(), 107);
    });

    test('map() called on a disposed pod throws via the disposed assertion',
        () {
      final pod = Pod<int>(1);
      pod.dispose();
      // map() registers a listener on the parent, which is the disposed pod.
      // addStrongRefListener has an assert(!_isDisposed, …).
      expect(() => pod.map((v) => v + 1), throwsA(isA<AssertionError>()));
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class _Point extends Equatable {
  final int x;
  final int y;
  const _Point(this.x, this.y);
  @override
  List<Object?> get props => [x, y];
}

enum _Color { a, b, c }
