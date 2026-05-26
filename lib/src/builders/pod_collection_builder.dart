//.title
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
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Observes a "source of pods" — a source [Listenable] whose changes imply
/// that the set of **inner pods** to watch may have changed — and rebuilds
/// when either:
///
/// 1. the [source] fires, or
/// 2. any pod currently returned by [innerPods] fires.
///
/// Subscription lifecycle for the inner pods is managed automatically —
/// when the source changes, the widget re-invokes [innerPods], diffs the
/// new set against the current subscriptions by identity, adds new
/// listeners, removes gone ones, and rebuilds.
///
/// ## Example
///
/// ```dart
/// // `pJobServices` is a pod whose value is a list of services, each
/// // exposing a `.pData` pod. Rebuild when the list changes OR when any
/// // listed service's `.pData` fires.
/// PodCollectionBuilder(
///   source: pJobServices,
///   innerPods: () => pJobServices.getValue().map((s) => s.pData).toList(),
///   builder: (context) => MyList(jobs: resolveCurrentJobs()),
/// )
/// ```
///
/// ## Type compatibility
///
/// Accepts any [Listenable] — including [Pod] (via [WeakChangeNotifier])
/// and stock Flutter `ValueNotifier`/`ChangeNotifier`. For
/// [WeakChangeNotifier]s the widget automatically uses
/// `addStrongRefListener` so the internal tear-off isn't GC'd between
/// fires; for plain `Listenable`s it falls back to `addListener`.
class PodCollectionBuilder extends StatefulWidget {
  const PodCollectionBuilder({
    super.key,
    required this.source,
    required this.innerPods,
    required this.builder,
  });

  /// The source pod. Fires signal "the collection of inner pods may have
  /// changed." [innerPods] is invoked once at [State.initState] and again
  /// after every [source] fire.
  final Listenable source;

  /// Returns the current list of inner pods to subscribe to. Identity is
  /// significant — the builder uses `identical()` to diff against the
  /// previous subscription set.
  final List<Listenable> Function() innerPods;

  /// Builds the subtree. Rebuilt on every source fire and every
  /// inner-pod fire.
  final WidgetBuilder builder;

  @override
  State<PodCollectionBuilder> createState() => _PodCollectionBuilderState();
}

class _PodCollectionBuilderState extends State<PodCollectionBuilder> {
  // Stored as `late final` so the WeakChangeNotifier's WeakRef has a stable
  // strong-reachable closure to point at for the lifetime of this state.
  late final VoidCallback _listener = _onChange;

  List<Listenable> _subscribed = const [];

  @override
  void initState() {
    super.initState();
    _attach(widget.source);
    _syncSubscriptions();
  }

  @override
  void didUpdateWidget(PodCollectionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.source, widget.source)) {
      _detach(oldWidget.source);
      _attach(widget.source);
      _syncSubscriptions();
    }
  }

  @override
  void dispose() {
    _detach(widget.source);
    for (final p in _subscribed) {
      _detach(p);
    }
    _subscribed = const [];
    super.dispose();
  }

  void _attach(Listenable l) {
    try {
      if (l is WeakChangeNotifier) {
        l.addStrongRefListener(strongRefListener: _listener);
      } else {
        l.addListener(_listener);
      }
    } catch (e, s) {
      // A misbehaving Listenable (e.g. a disposed pod's addListener) is
      // logged and skipped. The widget tree stays alive; the bad pod is
      // simply not subscribed. Without this guard, an exception from
      // addListener would unwind out of [_onChange] / [_syncSubscriptions]
      // mid-mutation, leaving `_subscribed` desynced from the actual
      // listener registrations and causing leaks on subsequent rebuilds.
      Log.err(e, tags: {#df_pod});
      assert(() {
        debugPrint('PodCollectionBuilder attach failed: $e\n$s');
        return true;
      }());
    }
  }

  void _detach(Listenable l) {
    try {
      l.removeListener(_listener);
    } catch (e, s) {
      // Same defensiveness as [_attach]. removeListener should be a
      // no-op on unknown listeners, but if a custom Listenable throws,
      // we don't want one rogue pod to corrupt our bookkeeping.
      Log.err(e, tags: {#df_pod});
      assert(() {
        debugPrint('PodCollectionBuilder detach failed: $e\n$s');
        return true;
      }());
    }
  }

  void _onChange() {
    if (!mounted) return;
    _syncSubscriptions();
    setState(() {});
  }

  /// Diffs [_subscribed] against the result of [widget.innerPods] and
  /// adjusts subscriptions to match.
  ///
  /// Exception safety: each attach/detach is independently guarded
  /// inside [_attach]/[_detach] so one rogue Listenable cannot leave
  /// the bookkeeping desynced. If [widget.innerPods] itself throws,
  /// we leave the current subscription set unchanged and log.
  ///
  /// Adaptive algorithm: a linear identity scan for small collections
  /// (the common case), Set-based O(N+M) above the threshold.
  /// `Set.identity()` is correct here: `Listenable` subclasses all
  /// inherit default `Object.==` so identity == equality.
  void _syncSubscriptions() {
    List<Listenable> next;
    try {
      next = widget.innerPods();
    } catch (e, s) {
      Log.err(e, tags: {#df_pod});
      assert(() {
        debugPrint('PodCollectionBuilder innerPods threw: $e\n$s');
        return true;
      }());
      return;
    }
    if (_listsIdentical(_subscribed, next)) return;

    const smallThreshold = 8;
    if (_subscribed.length <= smallThreshold && next.length <= smallThreshold) {
      // Linear: zero-allocation.
      for (final p in _subscribed) {
        if (!_listContainsIdentical(next, p)) _detach(p);
      }
      for (final p in next) {
        if (!_listContainsIdentical(_subscribed, p)) _attach(p);
      }
    } else {
      // Set-based: O(N+M) for >8 inner pods.
      final nextSet = Set<Listenable>.identity()..addAll(next);
      final oldSet = Set<Listenable>.identity()..addAll(_subscribed);
      for (final p in _subscribed) {
        if (!nextSet.contains(p)) _detach(p);
      }
      for (final p in next) {
        if (!oldSet.contains(p)) _attach(p);
      }
    }
    _subscribed = List.unmodifiable(next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

bool _listContainsIdentical(List<Listenable> list, Listenable target) {
  for (final e in list) {
    if (identical(e, target)) return true;
  }
  return false;
}

bool _listsIdentical(List<Listenable> a, List<Listenable> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}
