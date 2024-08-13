//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:tuple/tuple.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension ReduceManyPodsOnPodIterableExtension on List<Pod> {
  /// Reduces a set of [Pod] instances to a single [ChildPod] instance.
  ChildPod<dynamic, T> reduceManyPods<T>(
    T Function(ManyPods<dynamic> values) reducer,
    List<dynamic> Function(List<dynamic> parentValues, T childValue)?
        updateParents,
    _ChildPodInstantiator<dynamic, T> instantiator,
  ) {
    return _reduceToSinglePod(
      this,
      reducer,
      updateParents,
      instantiator,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces many Pod [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<T1, T2> reduceManyPods<T1, T2>(
  final List<Pod<T1>> instances,
  T2 Function(ManyPods<T1> values) reducer,
  List<T1> Function(List<T1> parentValues, T2 childValue)? updateParents,
  _ChildPodInstantiator<T1, T2> instantiator,
) {
  return instantiator(
    parents: instances,
    reducer: (_) => reducer(ManyPods(instances.toList())),
    updateParents: updateParents,
  );
}

const _reduceToSinglePod = reduceManyPods;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// T1 tuple of many [Pod] instances.
base class ManyPods<T> {
  //
  //
  //

  final List<Pod<T>?> pods;

  //
  //
  //

  const ManyPods(this.pods);

  //
  //
  //

  List<T?> toList() => pods.map((pod) => pod?.value).toList();

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

/// Reduces a tuple of 2 Pod [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce2Pods<T, T1, T2>(
  Pods2<T1, T2> instances,
  T Function(Pods2<T1, T2> values) reducer,
  (T1?, T2?) Function(Tuple2<T1, T2> parentValues, T childValue)? updateParents,
  _ChildPodInstantiator<dynamic, T> instantiator,
) {
  return instantiator(
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

/// T1 tuple of 2 [Pod] instances.
final class Pods2<T1, T2> extends Tuple2<T1?, T2?>
    implements ManyPods<dynamic> {
  final Pod<T1>? p1;
  final Pod<T2>? p2;

  Pods2([
    this.p1,
    this.p2,
  ]) : super(
          p1?.value,
          p2?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        p1,
        p2,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 3 Pod [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce3Pods<T, T1, T2, T3>(
  Pods3<T1, T2, T3> instances,
  T Function(Pods3<T1, T2, T3> values) reducer,
  (T1?, T2?, T3?) Function(Tuple3<T1, T2, T3> parentValues, T childValue)?
      updateParents,
  _ChildPodInstantiator<dynamic, T> instantiator,
) {
  return instantiator(
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

/// T1 tuple of 3 [Pod] instances.
final class Pods3<T1, T2, T3> extends Tuple3<T1?, T2?, T3?>
    implements ManyPods<dynamic> {
  final Pod<T1>? p1;
  final Pod<T2>? p2;
  final Pod<T3>? p3;

  Pods3([
    this.p1,
    this.p2,
    this.p3,
  ]) : super(
          p1?.value,
          p2?.value,
          p3?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        p1,
        p2,
        p3,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 4 Pod [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce4Pods<T, T1, T2, T3, T4>(
  Pods4<T1, T2, T3, T4> instances,
  T Function(Pods4<T1, T2, T3, T4> values) reducer,
  (T1?, T2?, T3?, T4?) Function(
          Tuple4<T1, T2, T3, T4> parentValues, T childValue,)?
      updateParents,
  _ChildPodInstantiator<dynamic, T> instantiator,
) {
  return instantiator(
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

/// T1 tuple of 4 [Pod] instances.
final class Pods4<T1, T2, T3, T4> extends Tuple4<T1?, T2?, T3?, T4?>
    implements ManyPods<dynamic> {
  final Pod<T1>? p1;
  final Pod<T2>? p2;
  final Pod<T3>? p3;
  final Pod<T4>? p4;

  Pods4([
    this.p1,
    this.p2,
    this.p3,
    this.p4,
  ]) : super(
          p1?.value,
          p2?.value,
          p3?.value,
          p4?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        p1,
        p2,
        p3,
        p4,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 5 Pod [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce5Pods<T, T1, T2, T3, T4, T5>(
  Pods5<T1, T2, T3, T4, T5> instances,
  T Function(Pods5<T1, T2, T3, T4, T5> values) reducer,
  (T1?, T2?, T3?, T4?, T5?) Function(Tuple5<T1, T2, T3, T4, T5>, T childValue)?
      updateParents,
  _ChildPodInstantiator<dynamic, T> instantiator,
) {
  return instantiator(
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

/// T1 tuple of 5 [Pod] instances.
final class Pods5<T1, T2, T3, T4, T5> extends Tuple5<T1?, T2?, T3?, T4?, T5?>
    implements ManyPods<dynamic> {
  final Pod<T1>? p1;
  final Pod<T2>? p2;
  final Pod<T3>? p3;
  final Pod<T4>? p4;
  final Pod<T5>? p5;

  Pods5([
    this.p1,
    this.p2,
    this.p3,
    this.p4,
    this.p5,
  ]) : super(
          p1?.value,
          p2?.value,
          p3?.value,
          p4?.value,
          p5?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        p1,
        p2,
        p3,
        p4,
        p5,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 6 Pod [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce6Pods<T, T1, T2, T3, T4, T5, T6>(
  Pods6<T1, T2, T3, T4, T5, T6> instances,
  T Function(Pods6<T1, T2, T3, T4, T5, T6> instances) reducer,
  (T1?, T2?, T3?, T4?, T5?, T6?) Function(
          Tuple6<T1, T2, T3, T4, T5, T6>, T childValue,)?
      updateParents,
  _ChildPodInstantiator<dynamic, T> instantiator,
) {
  return instantiator(
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

/// T1 tuple of 6 [Pod] instances.
final class Pods6<T1, T2, T3, T4, T5, T6>
    extends Tuple6<T1?, T2?, T3?, T4?, T5?, T6?> implements ManyPods<dynamic> {
  final Pod<T1>? p1;
  final Pod<T2>? p2;
  final Pod<T3>? p3;
  final Pod<T4>? p4;
  final Pod<T5>? p5;
  final Pod<T6>? p6;

  Pods6([
    this.p1,
    this.p2,
    this.p3,
    this.p4,
    this.p5,
    this.p6,
  ]) : super(
          p1?.value,
          p2?.value,
          p3?.value,
          p4?.value,
          p5?.value,
          p6?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        p1,
        p2,
        p3,
        p4,
        p5,
        p6,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reduces a tuple of 7 Pod [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [updateParents] to define how parent Pods
/// should be updated when this Pod changes.
ChildPod<dynamic, T> reduce7Pods<T, T1, T2, T3, T4, T5, T6, T7>(
  Pods7<T1, T2, T3, T4, T5, T6, T7> instances,
  T Function(Pods7<T1, T2, T3, T4, T5, T6, T7> instances) reducer,
  (T1?, T2?, T3?, T4?, T5?, T6?, T7?) Function(
    Tuple7<T1, T2, T3, T4, T5, T6, T7>,
    T childValue,
  )? updateParents,
  _ChildPodInstantiator<dynamic, T> instantiator,
) {
  return instantiator(
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

/// T1 tuple of 7 [Pod] instances.
final class Pods7<T1, T2, T3, T4, T5, T6, T7>
    extends Tuple7<T1?, T2?, T3?, T4?, T5?, T6?, T7?>
    implements ManyPods<dynamic> {
  final Pod<T1>? p1;
  final Pod<T2>? p2;
  final Pod<T3>? p3;
  final Pod<T4>? p4;
  final Pod<T5>? p5;
  final Pod<T6>? p6;
  final Pod<T7>? p7;

  Pods7([
    this.p1,
    this.p2,
    this.p3,
    this.p4,
    this.p5,
    this.p6,
    this.p7,
  ]) : super(
          p1?.value,
          p2?.value,
          p3?.value,
          p4?.value,
          p5?.value,
          p6?.value,
          p7?.value,
        );

  @override
  List<Pod<dynamic>?> get pods => [
        p1,
        p2,
        p3,
        p4,
        p5,
        p6,
        p7,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _ChildPodInstantiator<T1, T2> = ChildPod<T1, T2> Function({
  required List<Pod<T1>> parents,
  required T2 Function(List<T1> parentValues) reducer,
  required List<T1> Function(List<T1> parentValues, T2 childValue)?
      updateParents,
});
