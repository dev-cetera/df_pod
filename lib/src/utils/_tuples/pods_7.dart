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

import 'package:tuple/tuple.dart';

import '/src/_mixins/pod_values_where_mixin.dart';
import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A tuple of 7 [GenericPod] instances.
final class Pods7<P1, P2, P3, P4, P5, P6, P7>
    extends Tuple7<P1?, P2?, P3?, P4?, P5?, P6?, P7?>
    implements PodValuesWhereMixin<dynamic> {
  final GenericPod<P1>? p1;
  final GenericPod<P2>? p2;
  final GenericPod<P3>? p3;
  final GenericPod<P4>? p4;
  final GenericPod<P5>? p5;
  final GenericPod<P6>? p6;
  final GenericPod<P7>? p7;

  Pods7(this.p1, this.p2, this.p3, this.p4, this.p5, this.p6, this.p7)
    : super(null, null, null, null, null, null, null);

  @override
  P1? get item1 => p1?.value;

  @override
  P2? get item2 => p2?.value;

  @override
  P3? get item3 => p3?.value;

  @override
  P4? get item4 => p4?.value;

  @override
  P5? get item5 => p5?.value;

  @override
  P6? get item6 => p6?.value;

  @override
  P7? get item7 => p7?.value;

  @override
  List<GenericPod<dynamic>?> get pods => [p1, p2, p3, p4, p5, p6, p7];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}
