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

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A Pod that listens to changes to existing Pods returned by the [responder].
/// When any of these returned Pods update, it recalculates its value using the
/// [reducer] function, then calls the [responder] again to refresh Pods to
/// listen to. This recursive behaviour ensures that the Pod continuously
/// listens to new changes from any updated Pods.
///
/// [T] is the type of this Pod and the value produced by the [reducer]
/// function.
///
/// Note that when this pod disposes via [dispose], it will not dispose the Pods
/// provided by [responder]. Explicit disposal is needed.
base class ReducerPod<T extends Object> extends PodNotifier<T>
    with GenericPod<T> {
  //
  //
  //

  /// Produces a list of Pods to listen to. This gets called recursively each
  /// time any of the Pods in the returned list change.
  final Iterable<Option<ValueListenable<Object>>> Function() responder;

  /// Reduces the values of the current Pods returned by [responder] to a
  /// single value of type [T], to update this Pod's [value].
  final Option<T> Function(List<Option> values) reducer;

  //
  //
  //

  factory ReducerPod.single(Option<ValueListenable<T>> Function() responder) {
    return ReducerPod(
      responder: () => [responder()],
      reducer: (values) {
        UNSAFE:
        return values.first.transf<T>().unwrap();
      },
    );
  }

  //
  //
  //

  @override
  // ignore: overridden_fields
  late T value;

  ReducerPod({required this.responder, required this.reducer}) {
    // First-pass: subscribe to parents AND compute the initial value, then
    // initialize `value` directly. Going through `_set` here would crash on a
    // [LateInitializationError] for any [Comparable]/[num]/[bool]/[Enum] T,
    // because `_set`'s equality short-circuit reads `value` before it has been
    // assigned. Subsequent fires go through `_refresh` -> `_set` normally.
    final initial = _getValue();
    if (initial.isSome()) {
      UNSAFE:
      value = initial.unwrap();
    }
  }

  //
  //
  //

  bool _isDirty = false;

  late VoidCallback? _refresh = () {
    // Re-entrance guard: a listener fired during `_set` below could cascade
    // back into us. The body is fully synchronous, so the flag is only ever
    // true while we are mid-refresh. Mirrors the guard in `ChildPod._refresh`.
    if (_isDirty) return;
    _isDirty = true;
    try {
      final option = _getValue();
      if (option.isSome()) {
        UNSAFE:
        _set(option.unwrap());
      }
    } finally {
      _isDirty = false;
    }
  };

  //
  //
  //

  final _listenables = <ValueListenable<Object>>[];

  //
  //
  //

  Option<T> _getValue() {
    for (final listenable in _listenables) {
      listenable.removeListener(_refresh!);
    }
    _listenables.clear();
    final values = responder().toList();
    final newListenables = <ValueListenable<Object>>[];
    for (var n = 0; n < values.length; n++) {
      final option = values[n];
      if (option.isNone()) continue;
      UNSAFE:
      final value = option.unwrap();
      newListenables.add(value);
      value.addListener(_refresh!);
    }
    try {
      final valuesToReduce = values.map((e) => e.map((e) => e.value)).toList();
      final result = reducer(valuesToReduce);
      _listenables.addAll(newListenables);
      return result;
    } catch (e) {
      // Clean up listeners if reducer throws to prevent memory leaks
      for (final listenable in newListenables) {
        listenable.removeListener(_refresh!);
      }
      rethrow;
    }
  }

  //
  //
  //

  @override
  void dispose() {
    final refresh = _refresh;
    _refresh = null;
    if (refresh != null) {
      for (final listenable in _listenables) {
        listenable.removeListener(refresh);
      }
    }
    super.dispose();
  }
}
