//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_visible_for_testing_member

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
base class ReducerPod<T> extends PodNotifier<T?> with GenericPod<T?> {
  //
  //
  //

  /// Produces a list of Pods to listen to. This gets called recursively each
  /// time any of the Pods in the returned list change.
  final List<PodListenable<dynamic>?> Function() responder;

  /// Reduces the values of the current Pods returned by [responder] to a
  /// single value of type [T], to update this Pod's [value].
  final T Function(List<dynamic> values) reducer;

  /// The currently active Pods being listened to.
  final List<PodListenable<dynamic>?> _current = [];

  //
  //
  //

  ReducerPod({
    required this.responder,
    required this.reducer,
  }) : super(null) {
    _cachedValue = _getValue();
    _value = _cachedValue;
  }

  //
  //
  //

  void _refresh() {
    final value = _getValue();
    /*await*/ _set(value);
  }

  //
  //
  //

  T _getValue() {
    // Remove all listeners from _current Pods and clear.
    {
      for (final pod in _current) {
        pod?.removeListener(_refresh);
      }
      _current.clear();
    }
    // Add new Pods from responder to _current and dd listeners.
    {
      final pods = responder();
      for (var pod in pods) {
        _current.add(pod);
        pod?.addListener(_refresh);
      }
    }
    // Reduce all Pod values to a single value and return.
    {
      final values = _current.map((e) => e?.value).toList();
      final value = reducer(values);
      return value;
    }
  }
}
