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
  final FutureOr<Iterable<FutureOr<dynamic>>> Function() responder;

  /// Reduces the values of the current Pods returned by [responder] to a
  /// single value of type [T], to update this Pod's [value].
  final T Function(List<dynamic> values) reducer;

  /// Tracks the current PodListenable instances being listened to.
  final _listenables = <PodListenable<dynamic>>[];

  //
  //
  //

  static FutureOr<ReducerPod<T>> create<T>({
    required FutureOr<Iterable<FutureOr<dynamic>>> Function() responder,
    required T Function(List<dynamic> values) reducer,
  }) {
    final instance = ReducerPod<T>._(
      responder: responder,
      reducer: reducer,
    );
    return mapSyncOrAsync(
      instance._refresh,
      (_) => instance,
    );
  }

  static FutureOr<ReducerPod<T>> single<T>({
    required FutureOr<PodListenable<T>> Function() responder,
  }) {
    return ReducerPod.create(
      responder: () => [responder()],
      reducer: (values) => values.first as T,
    );
  }

  //
  //
  //

  ReducerPod._({
    required this.responder,
    required this.reducer,
  }) : super(null);

  //
  //
  //

  FutureOr<void> _refresh() async {
    return mapSyncOrAsync(_getValue(), (value) => _set(value));
  }

  //
  //
  //

  FutureOr<T> _getValue() {
    final seqential = Sequential();
    final values = responder();
    return mapSyncOrAsync(values, (values) {
      for (final listenable in _listenables) {
        listenable.removeListener(_refresh);
      }

      final resolvedValues = <dynamic>[];

      for (var n = 0; n < values.length; n++) {
        seqential.add(
          (_) => mapSyncOrAsync(
            values.elementAt(n),
            (value) {
              if (value is PodListenable) {
                _listenables.add(value);
                resolvedValues.add(value.value);
              } else {
                resolvedValues.add(value);
              }
            },
          ),
        );
      }

      return mapSyncOrAsync(seqential.last, (_) {
        for (final listenable in _listenables) {
          listenable.addListener(_refresh);
        }
        final valuesToReduce = resolvedValues.map((e) => e is PodListenable ? e.value : e).toList();
        return reducer(valuesToReduce);
      });
    });
  }
}
