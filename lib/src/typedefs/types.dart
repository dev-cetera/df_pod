//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/widgets.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

//
typedef TPodList<T extends Object?> = Iterable<PodListenable<T>?>;
typedef TPodDataList<T extends Object?> = Iterable<T>;
typedef TPodListResponder<T extends Object?> = TPodList<T> Function();

typedef TOnDataBuilder<T> = Widget Function(
  BuildContext context,
  Widget? child,
  T snapshot,
);

typedef TOnLoadingBuilder = Widget Function(
  BuildContext context,
  Widget? child,
);

typedef TOnNoDataBuilder = Widget Function(
  BuildContext context,
  Widget? child,
);

typedef TRespondingBuilder<T> = Widget Function(
  BuildContext context,
  Widget? child,
  RespondingBuilderSnapshot<T> snapshot,
);

mixin PodServiceMixin {
  Future<void> startService();
  Future<void> stopService();
}
