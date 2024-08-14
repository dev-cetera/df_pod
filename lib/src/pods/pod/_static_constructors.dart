//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'parts.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// /// Reduces many Pod [instances] to a single [ChildPod] instance via [reducer].
// /// Optionally provide [updateParents] to define how parent Pods should be
// /// updated when this Pod changes.
// // ChildPod<T1, T2> _fromMany<T1, T2>(
// //   List<Pod<T1>> instances,
// //   T2 Function(ManyPods<T1> instances) reducer, [
// //   List<T1> Function(List<T1> parentValues, T2 childValue)? updateParents,
// // ]) {
// //   return reduceManyPods(
// //     instances,
// //     reducer,
// //     updateParents,
// //     _createChildPod,
// //   );
// // }

/// Reduces a tuple of 2 Pod [instances]to a single [ChildPod] instance via
/// [reducer]. Optionally provide [feedback] to define how parent Pods
/// should be updated when this Pod changes.
// ChildPod<dynamic, T> _from2<T, T1, T2>(
//   (Pod<T1>? p1, Pod<T2>? p2) Function() responder,
//   T Function(Pod<T1>? p1, Pod<T2>? p2) reducer, [
//   (T1, T2) Function((T1, T2) parentValues, T childValue)? feedback,
// ]) {
//   return reduce2Pods(
//     responder,
//     reducer,
//     feedback,
//     _createChildPod,
//   );
// }

// // /// Reduces a tuple of 3 Pod [instances]to a single [ChildPod] instance via
// // /// [reducer]. Optionally provide [updateParents] to define how parent Pods
// // /// should be updated when this Pod changes.
// // ChildPod<dynamic, T> _from3<T, T1, T2, T3>(
// //   Pods3<T1, T2, T3> instances,
// //   T Function(Pods3<T1, T2, T3> instances) reducer, [
// //   (T1?, T2?, T3?) Function(Tuple3<T1, T2, T3> parentValues, T childValue)? updateParents,
// // ]) {
// //   return reduce3Pods(
// //     instances,
// //     reducer,
// //     updateParents,
// //     _createChildPod,
// //   );
// // }

// // /// Reduces a tuple of 4 Pod [instances]to a single [ChildPod] instance via
// // /// [reducer]. Optionally provide [updateParents] to define how parent Pods
// // /// should be updated when this Pod changes.
// // ChildPod<dynamic, T> _from4<T, T1, T2, T3, T4>(
// //   Pods4<T1, T2, T3, T4> instances,
// //   T Function(Pods4<T1, T2, T3, T4> instances) reducer, [
// //   (T1?, T2?, T3?, T4?) Function(
// //     Tuple4<T1, T2, T3, T4> parentValues,
// //     T childValue,
// //   )? updateParents,
// // ]) {
// //   return reduce4Pods(
// //     instances,
// //     reducer,
// //     updateParents,
// //     _createChildPod,
// //   );
// // }

// // /// Reduces a tuple of 5 Pod [instances]to a single [ChildPod] instance via
// // /// [reducer]. Optionally provide [updateParents] to define how parent Pods
// // /// should be updated when this Pod changes.
// // ChildPod<dynamic, T> _from5<T, T1, T2, T3, T4, T5>(
// //   Pods5<T1, T2, T3, T4, T5> instances,
// //   T Function(Pods5<T1, T2, T3, T4, T5> instances) reducer, [
// //   (T1?, T2?, T3?, T4?, T5?) Function(
// //     Tuple5<T1, T2, T3, T4, T5> parentValues,
// //     T childValue,
// //   )? updateParents,
// // ]) {
// //   return reduce5Pods(
// //     instances,
// //     reducer,
// //     updateParents,
// //     _createChildPod,
// //   );
// // }

// // /// Reduces a tuple of 7 Pod [instances]to a single [ChildPod] instance via
// // /// [reducer]. Optionally provide [updateParents] to define how parent Pods
// // /// should be updated when this Pod changes.
// // ChildPod<dynamic, T> _from6<T, T1, T2, T3, T4, T5, T6>(
// //   Pods6<T1, T2, T3, T4, T5, T6> instances,
// //   T Function(Pods6<T1, T2, T3, T4, T5, T6> instances) reducer, [
// //   (T1?, T2?, T3?, T4?, T5?, T6?) Function(
// //     Tuple6<T1, T2, T3, T4, T5, T6> parentValues,
// //     T childValue,
// //   )? updateParents,
// // ]) {
// //   return reduce6Pods(
// //     instances,
// //     reducer,
// //     updateParents,
// //     _createChildPod,
// //   );
// // }

// // /// Reduces a tuple of 7 Pod [instances]to a single [ChildPod] instance via
// // /// [reducer]. Optionally provide [updateParents] to define how parent Pods
// // /// should be updated when this Pod changes.
// // ChildPod<dynamic, T> _from7<T, T1, T2, T3, T4, T5, T6, T7>(
// //   Pods7<T1, T2, T3, T4, T5, T6, T7> instances,
// //   T Function(Pods7<T1, T2, T3, T4, T5, T6, T7> instances) reducer, [
// //   (T1?, T2?, T3?, T4?, T5?, T6?, T7?) Function(
// //     Tuple7<T1, T2, T3, T4, T5, T6, T7> parentValues,
// //     T childValue,
// //   )? updateParents,
// // ]) {
// //   return reduce7Pods(
// //     instances,
// //     reducer,
// //     updateParents,
// //     _createChildPod,
// //   );
// // }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

ChildPod<T1, T2> _createChildPod<T1, T2>({
  required List<Pod<T1>?> Function() responder,
  required T2 Function(List<T1?> parentValues) reducer,
  required List<T1> Function(List<T1?> parentValues, T2 childValue)? feedback,
}) {
  return ChildPod<T1, T2>(
    responder: responder,
    reducer: reducer,
  );
}
