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
/// Previously this pattern required manual `addStrongRefListener` calls
/// plus a hand-rolled bookkeeping list (e.g. `_subscribedJobServices`) to
/// track which inner pods were currently observed. [PodCollectionBuilder]
/// subsumes that machinery.
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
    if (l is WeakChangeNotifier) {
      l.addStrongRefListener(strongRefListener: _listener);
    } else {
      l.addListener(_listener);
    }
  }

  void _detach(Listenable l) {
    l.removeListener(_listener);
  }

  void _onChange() {
    if (!mounted) return;
    _syncSubscriptions();
    setState(() {});
  }

  void _syncSubscriptions() {
    final next = widget.innerPods();
    if (_listsIdentical(_subscribed, next)) return;
    for (final p in _subscribed) {
      if (!_containsIdentical(next, p)) _detach(p);
    }
    for (final p in next) {
      if (!_containsIdentical(_subscribed, p)) _attach(p);
    }
    _subscribed = List.unmodifiable(next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

bool _containsIdentical(List<Listenable> list, Listenable target) {
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
