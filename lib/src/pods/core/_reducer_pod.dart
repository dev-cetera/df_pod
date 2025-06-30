//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
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
    _refresh!();
  }

  //
  //
  //

  late VoidCallback? _refresh = () {
    final option = _getValue();
    if (option.isSome()) {
      UNSAFE:
      _set(option.unwrap());
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
    final values = responder().toList();
    for (var n = 0; n < values.length; n++) {
      final option = values[n];
      if (option.isNone()) continue;
      UNSAFE:
      final value = option.unwrap();
      _listenables.add(value);
      value.addListener(_refresh!);
    }
    final valuesToReduce = values.map((e) => e.map((e) => e.value)).toList();
    return reducer(valuesToReduce);
  }

  //
  //
  //

  @override
  void dispose() {
    super.dispose();
    for (final listenable in _listenables) {
      listenable.removeListener(_refresh!);
    }
    _refresh = null;
  }
}
