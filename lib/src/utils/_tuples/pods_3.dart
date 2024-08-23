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

import 'package:tuple/tuple.dart';

import '../../_mixins/pod_values_where_mixin.dart';
import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// T3 tuple of 3 [GenericPod] instances.
final class Pods3<P1, P2, P3> extends Tuple3<P1?, P2?, P3?>
    implements PodValuesWhereMixin<dynamic> {
  final GenericPod<P1>? p1;
  final GenericPod<P2>? p2;
  final GenericPod<P3>? p3;

  Pods3(this.p1, this.p2, this.p3) : super(null, null, null);

  @override
  P1? get item1 => p1?.value;

  @override
  P2? get item2 => p2?.value;

  @override
  P3? get item3 => p3?.value;

  @override
  List<GenericPod<dynamic>?> get pods => [
        p1,
        p2,
        p3,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}
