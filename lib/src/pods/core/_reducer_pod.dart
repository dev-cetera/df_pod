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
  final Iterable<FutureOr<dynamic>> Function() responder;

  /// Reduces the values of the current Pods returned by [responder] to a
  /// single value of type [T], to update this Pod's [value].
  final T Function(List<dynamic> values) reducer;

  /// The currently active Pods being listened to.
  var _current = <dynamic>[];

  //
  //
  //

  ReducerPod({
    required this.responder,
    required this.reducer,
  }) : super(null) {
    final value = _getValue();
    _cachedValue = value;
  }

  //
  //
  //

  Future<void> _refresh() async {
    final value = _getValue();
    _cachedValue = value;
    await _set(value);
  }

  //
  //
  //

  T _getValue() {
    final values = responder();

    if (_current.isEmpty) {
      _current = List.filled(values.length, null);
    }

    for (var n = 0; n < values.length; n++) {
      final value = values.elementAt(n);

      if (_current[n] == null) {
        if (value is PodListenable) {
          value.addListener(_refresh);
          _current[n] = value;
        } else if (value is Future) {
          _current[n] = const _Placeholder();
          value.then((value1) {
            if (value1 is PodListenable) {
              value1.addListener(_refresh);
              _current[n] = value1;
            } else {
              _current[n] = value1;
            }
            _refresh();
          });
        } else {
          _current[n] = value;
        }
      }
    }
    final valuesToReduce =
        _current.map((e) => e is PodListenable ? e.value : e).toList();
    return reducer(valuesToReduce);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _Placeholder {
  const _Placeholder();
}
