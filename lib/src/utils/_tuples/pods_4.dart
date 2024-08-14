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

/// T4 tuple of 4 [PodMixin] instances.
final class Pods4<P1, P2, P3, P4> extends Tuple4<P1?, P2?, P3?, P4?>
    implements ManyPods<dynamic> {
  final PodMixin<P1>? p1;
  final PodMixin<P2>? p2;
  final PodMixin<P3>? p3;
  final PodMixin<P4>? p4;

  Pods4(this.p1, this.p2, this.p3, this.p4) : super(null, null, null, null);

  @override
  P1? get item1 => p1?.value;

  @override
  P2? get item2 => p2?.value;

  @override
  P3? get item3 => p3?.value;

  @override
  P4? get item4 => p4?.value;

  @override
  List<PodMixin<dynamic>?> get pods => [
        p1,
        p2,
        p3,
        p4,
      ];

  @override
  List<T> valuesWhereType<T>() => toList().whereType<T>().toList();
}
