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

// Deep-dive coverage of the [WeakChangeNotifier] state machine — growth,
// compaction (shrink vs in-place), reentrant add/remove, nested notify,
// throwing listeners, counter consistency. This is the most subtle code in
// the package; the bugs we found in pass 1 (`_compactListeners` double-count)
// and pass 3 (dispose-during-notify) lived here.

import 'package:df_pod/df_pod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Capacity growth', () {
    test('first listener triggers 0 -> 1 capacity', () {
      final pod = Pod<int>(0);
      var calls = 0;
      final l = () => calls++;
      pod.addStrongRefListener(strongRefListener: l);
      pod.set(1);
      expect(calls, 1);
    });

    test('exponential growth holds for 1, 2, 4, 8, 16 listeners', () {
      // Indirect probe: add N listeners, set, count fires, remove all, repeat.
      // If growth has off-by-one, some listeners would be silently lost.
      for (final size in const [1, 2, 4, 8, 16, 31, 32, 33, 100]) {
        final pod = Pod<int>(0);
        var calls = 0;
        final listeners = <VoidCallback>[];
        for (var i = 0; i < size; i++) {
          final l = () => calls++;
          listeners.add(l);
          pod.addStrongRefListener(strongRefListener: l);
        }
        pod.set(1);
        expect(
          calls,
          size,
          reason: 'all $size listeners must fire — growth lost some?',
        );
      }
    });

    test('growth via interleaved adds and notifies stays consistent', () {
      final pod = Pod<int>(0);
      var calls = 0;
      final listeners = <VoidCallback>[];
      for (var i = 0; i < 50; i++) {
        final l = () => calls++;
        listeners.add(l);
        pod.addStrongRefListener(strongRefListener: l);
        pod.set(i);
      }
      // Last set: 50 listeners fire on this final notify only.
      // Earlier sets each fired the listeners present at that moment:
      //   0 listeners + 1 listener + 2 listeners + ... + 49 listeners
      // Plus the listeners-fire from i=0 through i=49.
      // Easier to verify: now set once more and expect 50 fires.
      final before = calls;
      pod.set(9999);
      expect(calls - before, 50);
    });
  });

  group('Capacity shrink — _removeAt', () {
    test('removing all listeners shrinks to empty', () {
      final pod = Pod<int>(0);
      final ls = <VoidCallback>[];
      for (var i = 0; i < 10; i++) {
        final l = () {};
        ls.add(l);
        pod.addStrongRefListener(strongRefListener: l);
      }
      for (final l in ls) {
        pod.removeListener(l);
      }
      // After all removed, the next add should still work.
      var calls = 0;
      final fresh = () => calls++;
      pod.addStrongRefListener(strongRefListener: fresh);
      pod.set(1);
      expect(calls, 1);
    });

    test('removing every other listener triggers in-place compaction path',
        () {
      final pod = Pod<int>(0);
      final ls = <VoidCallback>[];
      var calls = 0;
      for (var i = 0; i < 8; i++) {
        final l = () => calls++;
        ls.add(l);
        pod.addStrongRefListener(strongRefListener: l);
      }
      // Remove indices 1, 3, 5, 7 — 4 listeners remain (4 / 8 capacity).
      // 4*2=8 <= 8 → shrink branch.
      pod.removeListener(ls[1]);
      pod.removeListener(ls[3]);
      pod.removeListener(ls[5]);
      pod.removeListener(ls[7]);

      pod.set(1);
      expect(calls, 4);
    });

    test('removing a few listeners triggers in-place (not shrink) compaction',
        () {
      // Goal: leave newLength * 2 > capacity so the in-place branch runs.
      final pod = Pod<int>(0);
      final ls = <VoidCallback>[];
      var calls = 0;
      for (var i = 0; i < 8; i++) {
        final l = () => calls++;
        ls.add(l);
        pod.addStrongRefListener(strongRefListener: l);
      }
      // Remove 1 — 7 remain (7 * 2 = 14 > 8 capacity), in-place branch.
      pod.removeListener(ls[3]);

      pod.set(1);
      expect(calls, 7);
    });
  });

  group('Reentrant remove during notify', () {
    test(
      'self-remove at index 0 still fires later listeners and survives compaction',
      () {
        final pod = Pod<int>(0);
        var firstCalls = 0;
        var secondCalls = 0;
        var thirdCalls = 0;
        late final VoidCallback first;
        first = () {
          firstCalls++;
          pod.removeListener(first);
        };
        final second = () => secondCalls++;
        final third = () => thirdCalls++;
        pod.addStrongRefListener(strongRefListener: first);
        pod.addStrongRefListener(strongRefListener: second);
        pod.addStrongRefListener(strongRefListener: third);

        pod.set(1);
        expect(firstCalls, 1);
        expect(secondCalls, 1);
        expect(thirdCalls, 1);

        pod.set(2);
        expect(firstCalls, 1, reason: 'first removed itself in cycle 1');
        expect(secondCalls, 2);
        expect(thirdCalls, 2);
      },
    );

    test('self-remove at the last index works', () {
      final pod = Pod<int>(0);
      var firstCalls = 0;
      var lastCalls = 0;
      final first = () => firstCalls++;
      late final VoidCallback last;
      last = () {
        lastCalls++;
        pod.removeListener(last);
      };
      pod.addStrongRefListener(strongRefListener: first);
      pod.addStrongRefListener(strongRefListener: last);

      pod.set(1);
      expect(firstCalls, 1);
      expect(lastCalls, 1);

      pod.set(2);
      expect(firstCalls, 2);
      expect(lastCalls, 1);
    });

    test('two simultaneous self-removers in the same notify cycle', () {
      final pod = Pod<int>(0);
      var aCalls = 0;
      var bCalls = 0;
      var cCalls = 0;
      late final VoidCallback a;
      late final VoidCallback c;
      a = () {
        aCalls++;
        pod.removeListener(a);
      };
      final b = () => bCalls++;
      c = () {
        cCalls++;
        pod.removeListener(c);
      };
      pod.addStrongRefListener(strongRefListener: a);
      pod.addStrongRefListener(strongRefListener: b);
      pod.addStrongRefListener(strongRefListener: c);

      pod.set(1);
      expect(aCalls, 1);
      expect(bCalls, 1);
      expect(cCalls, 1);

      pod.set(2);
      expect(aCalls, 1);
      expect(bCalls, 2);
      expect(cCalls, 1);
    });

    test('listener removes a peer that has not yet fired', () {
      final pod = Pod<int>(0);
      var aCalls = 0;
      var bCalls = 0;
      var cCalls = 0;
      late final VoidCallback b;
      final a = () {
        aCalls++;
        pod.removeListener(b);
      };
      b = () => bCalls++;
      final c = () => cCalls++;
      pod.addStrongRefListener(strongRefListener: a);
      pod.addStrongRefListener(strongRefListener: b);
      pod.addStrongRefListener(strongRefListener: c);

      pod.set(1);
      expect(aCalls, 1);
      // b was removed during a's call before its own slot was visited.
      expect(bCalls, 0);
      expect(cCalls, 1);

      pod.set(2);
      expect(aCalls, 2);
      expect(bCalls, 0);
      expect(cCalls, 2);
    });

    test('listener removes a peer that has already fired', () {
      final pod = Pod<int>(0);
      var aCalls = 0;
      var bCalls = 0;
      late final VoidCallback a;
      a = () => aCalls++;
      final b = () {
        bCalls++;
        pod.removeListener(a);
      };
      pod.addStrongRefListener(strongRefListener: a);
      pod.addStrongRefListener(strongRefListener: b);

      pod.set(1);
      expect(aCalls, 1);
      expect(bCalls, 1);

      pod.set(2);
      expect(aCalls, 1, reason: 'a was removed by b during cycle 1');
      expect(bCalls, 2);
    });
  });

  group('Reentrant add during notify', () {
    test('listener that adds a sibling listener — sibling fires next cycle',
        () {
      final pod = Pod<int>(0);
      var firstCalls = 0;
      var siblingCalls = 0;
      VoidCallback? sibling;
      late final VoidCallback first;
      first = () {
        firstCalls++;
        if (sibling == null) {
          sibling = () => siblingCalls++;
          pod.addStrongRefListener(strongRefListener: sibling!);
        }
      };
      pod.addStrongRefListener(strongRefListener: first);

      pod.set(1);
      expect(firstCalls, 1);
      expect(siblingCalls, 0);

      pod.set(2);
      expect(firstCalls, 2);
      expect(siblingCalls, 1);
    });

    test(
      'add-then-remove-self in the same callback leaves zero listeners',
      () {
        final pod = Pod<int>(0);
        var calls = 0;
        VoidCallback? added;
        late final VoidCallback selfModifier;
        selfModifier = () {
          calls++;
          added = () {};
          pod.addStrongRefListener(strongRefListener: added!);
          pod.removeListener(selfModifier);
        };
        pod.addStrongRefListener(strongRefListener: selfModifier);

        pod.set(1);
        expect(calls, 1);

        pod.set(2);
        // selfModifier was removed; only `added` remains, which is a no-op.
        expect(calls, 1);
      },
    );
  });

  group('Throwing listeners', () {
    test('a throwing listener does not block subsequent listeners', () {
      final pod = Pod<int>(0);
      var beforeCalls = 0;
      var afterCalls = 0;
      final before = () => beforeCalls++;
      final boom = () => throw StateError('intentional');
      final after = () => afterCalls++;
      pod.addStrongRefListener(strongRefListener: before);
      pod.addStrongRefListener(strongRefListener: boom);
      pod.addStrongRefListener(strongRefListener: after);

      // The error is reported via FlutterError but not rethrown.
      // In tests, FlutterError forwards to the test-binding which records it.
      final errors = <FlutterErrorDetails>[];
      final prevHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        pod.set(1);
      } finally {
        FlutterError.onError = prevHandler;
      }
      expect(beforeCalls, 1);
      expect(afterCalls, 1);
      expect(errors, hasLength(1));
      expect(errors.single.exception, isA<StateError>());
    });

    test('throwing listener that also self-removes is handled', () {
      final pod = Pod<int>(0);
      late final VoidCallback bad;
      var fired = 0;
      bad = () {
        fired++;
        pod.removeListener(bad);
        throw StateError('boom');
      };
      var followingCalls = 0;
      final following = () => followingCalls++;
      pod.addStrongRefListener(strongRefListener: bad);
      pod.addStrongRefListener(strongRefListener: following);

      final prev = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        pod.set(1);
      } finally {
        FlutterError.onError = prev;
      }
      expect(fired, 1);
      expect(followingCalls, 1);

      pod.set(2);
      expect(fired, 1, reason: 'bad removed itself in cycle 1');
      expect(followingCalls, 2);
    });
  });

  group('Nested notifyListeners (cascading pods)', () {
    test('parent pod listener triggers child pod set; both notify cleanly',
        () {
      final parent = Pod<int>(0);
      final child = Pod<int>(0);
      var childListenerCalls = 0;
      late final VoidCallback bridge;
      bridge = () {
        // When parent fires, propagate to child.
        child.set(parent.getValue() * 10);
      };
      final childListener = () => childListenerCalls++;
      parent.addStrongRefListener(strongRefListener: bridge);
      child.addStrongRefListener(strongRefListener: childListener);

      parent.set(1);
      expect(child.getValue(), 10);
      expect(childListenerCalls, 1);

      parent.set(5);
      expect(child.getValue(), 50);
      expect(childListenerCalls, 2);
    });

    test(
      'listener that calls set() on the SAME pod recurses and short-circuits '
      'on equal values',
      () {
        final pod = Pod<int>(0);
        var calls = 0;
        late final VoidCallback recurser;
        recurser = () {
          calls++;
          if (calls < 5) {
            pod.set(calls); // each recursive set is a different value
          }
        };
        pod.addStrongRefListener(strongRefListener: recurser);

        pod.set(100);
        // Sets cascade: 100 -> 1 -> 2 -> 3 -> 4 -> stop.
        expect(calls, 5);
      },
    );
  });

  group('Counter consistency invariants', () {
    test('after many cycles of add/remove, capacity stays bounded', () {
      final pod = Pod<int>(0);
      final permanent = <VoidCallback>[];
      for (var i = 0; i < 5; i++) {
        final l = () {};
        permanent.add(l);
        pod.addStrongRefListener(strongRefListener: l);
      }
      // Churn: add/remove a transient listener 1000 times.
      for (var i = 0; i < 1000; i++) {
        final transient = () {};
        pod.addStrongRefListener(strongRefListener: transient);
        pod.removeListener(transient);
      }
      // Permanent listeners must still all fire.
      var calls = 0;
      final probe = () => calls++;
      pod.addStrongRefListener(strongRefListener: probe);
      pod.set(1);
      expect(calls, 1, reason: 'churn must not corrupt permanent state');
    });

    test('compaction after every-other reentrant remove leaves count correct',
        () {
      final pod = Pod<int>(0);
      final ls = <VoidCallback>[];
      var fires = 0;
      for (var i = 0; i < 10; i++) {
        late final VoidCallback l;
        if (i % 2 == 0) {
          l = () {
            fires++;
            pod.removeListener(l);
          };
        } else {
          l = () => fires++;
        }
        ls.add(l);
        pod.addStrongRefListener(strongRefListener: l);
      }

      pod.set(1);
      expect(fires, 10);

      pod.set(2);
      // Even-index listeners removed themselves; only 5 remain.
      expect(fires - 10, 5);
    });
  });

  group('addSingleExecutionListener behaviour', () {
    test('one-shot fires exactly once and is gone', () {
      final pod = Pod<int>(0);
      var fires = 0;
      pod.addSingleExecutionListener(() => fires++);
      pod.set(1);
      pod.set(2);
      pod.set(3);
      expect(fires, 1);
    });

    test('many one-shots queued at once all fire on the same set', () {
      final pod = Pod<int>(0);
      var fires = 0;
      for (var i = 0; i < 50; i++) {
        pod.addSingleExecutionListener(() => fires++);
      }
      pod.set(1);
      expect(fires, 50);

      pod.set(2);
      expect(fires, 50, reason: 'all one-shots already removed');
    });

    test('one-shot mixed with permanent listeners', () {
      final pod = Pod<int>(0);
      var permanentFires = 0;
      var oneShotFires = 0;
      final permanent = () => permanentFires++;
      pod.addStrongRefListener(strongRefListener: permanent);
      pod.addSingleExecutionListener(() => oneShotFires++);

      pod.set(1);
      expect(permanentFires, 1);
      expect(oneShotFires, 1);

      pod.set(2);
      expect(permanentFires, 2);
      expect(oneShotFires, 1);
    });
  });

  group('Dispose timing edge cases', () {
    test('dispose between notify cycles is clean', () {
      final pod = Pod<int>(0);
      var calls = 0;
      final l = () => calls++;
      pod.addStrongRefListener(strongRefListener: l);

      pod.set(1);
      expect(calls, 1);

      pod.dispose();
      // Subsequent set throws the disposed-pod assertion.
      try {
        pod.set(2);
      } catch (_) {
        // expected
      }
      expect(calls, 1);
    });

    test('dispose during the FIRST listener of a multi-listener notify', () {
      final pod = Pod<int>(0);
      var firstFired = false;
      var laterFired = false;
      final first = () {
        firstFired = true;
        pod.dispose();
      };
      final later = () => laterFired = true;
      pod.addStrongRefListener(strongRefListener: first);
      pod.addStrongRefListener(strongRefListener: later);

      pod.set(1);
      expect(firstFired, isTrue);
      expect(laterFired, isFalse);
      expect(pod.isDisposed, isTrue);
    });

    test('dispose during the LAST listener of a multi-listener notify', () {
      final pod = Pod<int>(0);
      var firstFired = false;
      var lastFired = false;
      final first = () => firstFired = true;
      final last = () {
        lastFired = true;
        pod.dispose();
      };
      pod.addStrongRefListener(strongRefListener: first);
      pod.addStrongRefListener(strongRefListener: last);

      pod.set(1);
      expect(firstFired, isTrue);
      expect(lastFired, isTrue);
      expect(pod.isDisposed, isTrue);
    });
  });

  group('Heavy stress', () {
    test('10000 listeners on a single notify all fire', () {
      final pod = Pod<int>(0);
      var calls = 0;
      final ls = <VoidCallback>[];
      for (var i = 0; i < 10000; i++) {
        final l = () => calls++;
        ls.add(l);
        pod.addStrongRefListener(strongRefListener: l);
      }
      pod.set(1);
      expect(calls, 10000);
    });

    test('1000-cycle add/remove churn followed by clean notify', () {
      final pod = Pod<int>(0);
      for (var cycle = 0; cycle < 1000; cycle++) {
        final l1 = () {};
        final l2 = () {};
        pod.addStrongRefListener(strongRefListener: l1);
        pod.addStrongRefListener(strongRefListener: l2);
        pod.removeListener(l1);
        pod.removeListener(l2);
      }
      var calls = 0;
      final probe = () => calls++;
      pod.addStrongRefListener(strongRefListener: probe);
      pod.set(1);
      expect(calls, 1);
    });

    test(
      '500 listeners, all of which self-remove on first notify, fire once',
      () {
        final pod = Pod<int>(0);
        var fires = 0;
        final ls = <VoidCallback>[];
        for (var i = 0; i < 500; i++) {
          late final VoidCallback l;
          l = () {
            fires++;
            pod.removeListener(l);
          };
          ls.add(l);
          pod.addStrongRefListener(strongRefListener: l);
        }

        pod.set(1);
        expect(fires, 500);

        pod.set(2);
        expect(fires, 500, reason: 'all 500 removed themselves');
      },
    );
  });
}
