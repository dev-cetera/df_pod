//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. See LICENSE file
// in root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:tuple/tuple.dart';

import '_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension ReduceManyPodsOnPodIterableExtension on List<Pod> {
  /// Reduces a set of [Pod] instances to a single [ChildPod] instance.
  ChildPod<dynamic, T> reduceManyPods<T>(
    T Function(ManyPods values) reducer,
    List<dynamic> Function(List<dynamic> parentValues, T childValue)?
        updateParents,
  ) {
    return _reduceToSinglePod(
      this,
      reducer,
      updateParents,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces many [Pod] * [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<A, B> reduceManyPods<A, B>(
  final List<Pod<A>> instances,
  B Function(ManyPods<A> values) reducer,
  List<A> Function(List<A> parentValues, B childValue)? updateParents,
) {
  return ChildPod<A, B>(
    parents: instances,
    reducer: (_) => reducer(ManyPods(instances.toList())),
    updateParents: updateParents,
  );
}

const _reduceToSinglePod = reduceManyPods;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A tuple of many [Pod] instances.
base class ManyPods<A> {
  //
  //
  //

  final List<Pod<A>?> pods;

  //
  //
  //

  const ManyPods(this.pods);

  //
  //
  //

  List<A?> toList() => pods.map((pod) => pod?.value).toList();

  //
  //
  //

  /// Returns a list of Pod values where the type matches the generic type [T].
  List<T> valuesWhereType<T>() {
    final results = <T>[];
    for (var pod in pods) {
      if (pod?.value is T) {
        results.add(pod?.value as T);
      }
    }
    return results;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 2 [Pod] * [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce2Pods<T, A, B>(
  Pods2<A, B> instances,
  T Function(Pods2<A, B> values) reducer,
  (A?, B?) Function(Tuple2<A, B> parentValues, T childValue)? updateParents,
) {
  return ChildPod<dynamic, T>(
    parents: instances.pods.nonNulls.toList(),
    reducer: (_) => reducer(instances),
    updateParents: updateParents != null
        ? (oldParentValues, childValue) {
            final temp = updateParents(
              Tuple2.fromList(oldParentValues),
              childValue,
            );
            return [temp.$1, temp.$2];
          }
        : null,
  );
}

/// A tuple of 2 [Pod] instances.
final class Pods2<A, B> extends Tuple2<A?, B?> implements ManyPods {
  final Pod<A>? pA;
  final Pod<B>? pB;

  Pods2([
    this.pA,
    this.pB,
  ]) : super(
          pA?.value,
          pB?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        pA,
        pB,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 3 [Pod] * [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce3Pods<T, A, B, C>(
  Pods3<A, B, C> instances,
  T Function(Pods3<A, B, C> values) reducer,
  (A?, B?, C?) Function(Tuple3<A, B, C> parentValues, T childValue)?
      updateParents,
) {
  return ChildPod<dynamic, T>(
    parents: instances.pods.nonNulls.toList(),
    reducer: (_) => reducer(instances),
    updateParents: updateParents != null
        ? (oldParentValues, childValue) {
            final temp = updateParents(
              Tuple3.fromList(oldParentValues),
              childValue,
            );
            return [temp.$1, temp.$2, temp.$3];
          }
        : null,
  );
}

/// A tuple of 3 [Pod] instances.
final class Pods3<A, B, C> extends Tuple3<A?, B?, C?> implements ManyPods {
  final Pod<A>? pA;
  final Pod<B>? pB;
  final Pod<C>? pC;

  Pods3([
    this.pA,
    this.pB,
    this.pC,
  ]) : super(
          pA?.value,
          pB?.value,
          pC?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        pA,
        pB,
        pC,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 4 [Pod] * [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce4Pods<T, A, B, C, D>(
  Pods4<A, B, C, D> instances,
  T Function(Pods4<A, B, C, D> values) reducer,
  (A?, B?, C?, D?) Function(Tuple4<A, B, C, D> parentValues, T childValue)?
      updateParents,
) {
  return ChildPod<dynamic, T>(
    parents: instances.pods.nonNulls.toList(),
    reducer: (_) => reducer(instances),
    updateParents: updateParents != null
        ? (oldParentValues, childValue) {
            final temp = updateParents(
              Tuple4.fromList(oldParentValues),
              childValue,
            );
            return [temp.$1, temp.$2, temp.$3, temp.$4];
          }
        : null,
  );
}

/// A tuple of 4 [Pod] instances.
final class Pods4<A, B, C, D> extends Tuple4<A?, B?, C?, D?>
    implements ManyPods {
  final Pod<A>? pA;
  final Pod<B>? pB;
  final Pod<C>? pC;
  final Pod<D>? pD;

  Pods4([
    this.pA,
    this.pB,
    this.pC,
    this.pD,
  ]) : super(
          pA?.value,
          pB?.value,
          pC?.value,
          pD?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        pA,
        pB,
        pC,
        pD,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 5 [Pod] * [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce5Pods<T, A, B, C, D, E>(
  Pods5<A, B, C, D, E> instances,
  T Function(Pods5<A, B, C, D, E> values) reducer,
  (A?, B?, C?, D?, E?) Function(Tuple5<A, B, C, D, E>, T childValue)?
      updateParents,
) {
  return ChildPod<dynamic, T>(
    parents: instances.pods.nonNulls.toList(),
    reducer: (_) => reducer(instances),
    updateParents: updateParents != null
        ? (oldParentValues, childValue) {
            final temp = updateParents(
              Tuple5.fromList(oldParentValues),
              childValue,
            );
            return [temp.$1, temp.$2, temp.$3, temp.$4, temp.$5];
          }
        : null,
  );
}

/// A tuple of 5 [Pod] instances.
final class Pods5<A, B, C, D, E> extends Tuple5<A?, B?, C?, D?, E?>
    implements ManyPods {
  final Pod<A>? pA;
  final Pod<B>? pB;
  final Pod<C>? pC;
  final Pod<D>? pD;
  final Pod<E>? pE;

  Pods5([
    this.pA,
    this.pB,
    this.pC,
    this.pD,
    this.pE,
  ]) : super(
          pA?.value,
          pB?.value,
          pC?.value,
          pD?.value,
          pE?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        pA,
        pB,
        pC,
        pD,
        pE,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 6 [Pod] * [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce6Pods<T, A, B, C, D, E, F>(
  Pods6<A, B, C, D, E, F> instances,
  T Function(Pods6<A, B, C, D, E, F> instances) reducer,
  (A?, B?, C?, D?, E?, F?) Function(Tuple6<A, B, C, D, E, F>, T childValue)?
      updateParents,
) {
  return ChildPod<dynamic, T>(
    parents: instances.pods.nonNulls.toList(),
    reducer: (_) => reducer(instances),
    updateParents: updateParents != null
        ? (oldParentValues, childValue) {
            final temp = updateParents(
              Tuple6.fromList(oldParentValues),
              childValue,
            );
            return [temp.$1, temp.$2, temp.$3, temp.$4, temp.$5, temp.$6];
          }
        : null,
  );
}

/// A tuple of 6 [Pod] instances.
final class Pods6<A, B, C, D, E, F> extends Tuple6<A?, B?, C?, D?, E?, F?>
    implements ManyPods {
  final Pod<A>? pA;
  final Pod<B>? pB;
  final Pod<C>? pC;
  final Pod<D>? pD;
  final Pod<E>? pE;
  final Pod<F>? pF;

  Pods6([
    this.pA,
    this.pB,
    this.pC,
    this.pD,
    this.pE,
    this.pF,
  ]) : super(
          pA?.value,
          pB?.value,
          pC?.value,
          pD?.value,
          pE?.value,
          pF?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        pA,
        pB,
        pC,
        pD,
        pE,
        pF,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 7 [Pod] * [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce7Pods<T, A, B, C, D, E, F, G>(
  Pods7<A, B, C, D, E, F, G> instances,
  T Function(Pods7<A, B, C, D, E, F, G> instances) reducer,
  (A?, B?, C?, D?, E?, F?, G?) Function(
    Tuple7<A, B, C, D, E, F, G>,
    T childValue,
  )? updateParents,
) {
  return ChildPod<dynamic, T>(
    parents: instances.pods.nonNulls.toList(),
    reducer: (_) => reducer(instances),
    updateParents: updateParents != null
        ? (oldParentValues, childValue) {
            final temp = updateParents(
              Tuple7.fromList(oldParentValues),
              childValue,
            );
            return [
              temp.$1,
              temp.$2,
              temp.$3,
              temp.$4,
              temp.$5,
              temp.$6,
              temp.$7,
            ];
          }
        : null,
  );
}

/// A tuple of 7 [Pod] instances.
final class Pods7<A, B, C, D, E, F, G>
    extends Tuple7<A?, B?, C?, D?, E?, F?, G?> implements ManyPods {
  final Pod<A>? pA;
  final Pod<B>? pB;
  final Pod<C>? pC;
  final Pod<D>? pD;
  final Pod<E>? pE;
  final Pod<F>? pF;
  final Pod<G>? pG;

  Pods7([
    this.pA,
    this.pB,
    this.pC,
    this.pD,
    this.pE,
    this.pF,
    this.pG,
  ]) : super(
          pA?.value,
          pB?.value,
          pC?.value,
          pD?.value,
          pE?.value,
          pF?.value,
          pG?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        pA,
        pB,
        pC,
        pD,
        pE,
        pF,
        pG,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}
