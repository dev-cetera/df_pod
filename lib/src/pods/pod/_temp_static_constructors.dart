//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'pod.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces many Pod [instances] to a single [ChildPod.temp] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<A, B> _tempFromMany<A, B>(
  List<Pod<A>> instances,
  B Function(ManyPods<A> instances) reducer,
  List<A> Function(List<A> parentValues, B childValue)? updateParents,
) {
  return reduceManyPods(
    instances,
    reducer,
    updateParents,
    _createTempChildPod,
  );
}

/// Reduces a tuple of 2 Pod [instances] to a single [ChildPod.temp] instance
/// via [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> _tempFrom2<T, A, B>(
  Pods2<A, B> instances,
  T Function(Pods2<A, B> instances) reducer,
  (A?, B?) Function(Tuple2<A, B> parentValues, T childValue)? updateParents,
) {
  return reduce2Pods(
    instances,
    reducer,
    updateParents,
    _createTempChildPod,
  );
}

/// Reduces a tuple of 3 Pod [instances] to a single [ChildPod.temp] instance
/// via [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> _tempFrom3<T, A, B, C>(
  Pods3<A, B, C> instances,
  T Function(Pods3<A, B, C> instances) reducer,
  (A?, B?, C?) Function(Tuple3<A, B, C> parentValues, T childValue)? updateParents,
) {
  return reduce3Pods(
    instances,
    reducer,
    updateParents,
    _createTempChildPod,
  );
}

/// Reduces a tuple of 4 Pod [instances] to a single [ChildPod.temp] instance
/// via [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> _tempFrom4<T, A, B, C, D>(
  Pods4<A, B, C, D> instances,
  T Function(Pods4<A, B, C, D> instances) reducer,
  (A?, B?, C?, D?) Function(Tuple4<A, B, C, D> parentValues, T childValue)? updateParents,
) {
  return reduce4Pods(
    instances,
    reducer,
    updateParents,
    _createTempChildPod,
  );
}

/// Reduces a tuple of 5 Pod [instances] to a single [ChildPod.temp] instance
/// via [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> _tempFrom5<T, A, B, C, D, E>(
  Pods5<A, B, C, D, E> instances,
  T Function(Pods5<A, B, C, D, E> instances) reducer,
  (A?, B?, C?, D?, E?) Function(
    Tuple5<A, B, C, D, E> parentValues,
    T childValue,
  )? updateParents,
) {
  return reduce5Pods(
    instances,
    reducer,
    updateParents,
    _createTempChildPod,
  );
}

/// Reduces a tuple of 7 Pod [instances] to a single [ChildPod.temp] instance
/// via [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> _tempFrom6<T, A, B, C, D, E, F>(
  Pods6<A, B, C, D, E, F> instances,
  T Function(Pods6<A, B, C, D, E, F> instances) reducer,
  (A?, B?, C?, D?, E?, F?) Function(
    Tuple6<A, B, C, D, E, F> parentValues,
    T childValue,
  )? updateParents,
) {
  return reduce6Pods(
    instances,
    reducer,
    updateParents,
    _createTempChildPod,
  );
}

/// Reduces a tuple of 7 Pod [instances] to a single [ChildPod.temp] instance
/// via [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> _tempFrom7<T, A, B, C, D, E, F, G>(
  Pods7<A, B, C, D, E, F, G> instances,
  T Function(Pods7<A, B, C, D, E, F, G> instances) reducer,
  (A?, B?, C?, D?, E?, F?, G?) Function(
    Tuple7<A, B, C, D, E, F, G> parentValues,
    T childValue,
  )? updateParents,
) {
  return reduce7Pods(
    instances,
    reducer,
    updateParents,
    _createTempChildPod,
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

ChildPod<A, B> _createTempChildPod<A, B>({
  required List<Pod<A>> parents,
  required B Function(List<A> parentValues) reducer,
  required List<A> Function(List<A> parentValues, B childValue)? updateParents,
}) {
  return ChildPod<A, B>.temp(
    parents: parents,
    reducer: reducer,
    updateParents: updateParents,
  );
}
