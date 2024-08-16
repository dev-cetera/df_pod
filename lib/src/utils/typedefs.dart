//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';

import 'package:flutter/widgets.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Builds a [Widget] when given a concrete value of a [Pod<T>].
///
/// If the `child` parameter provided to the [PodBuilder] is not
/// null, the same `child` widget is passed back to this [PodBuilder]
/// and should typically be incorporated in the returned widget tree.
///
/// See Also:
///
///  - [PodBuilder], a widget which invokes this builder each time a [Pod]
/// changes value.
typedef TOnDataBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  Widget? child,
);

typedef TOnLoadingBuilder = Widget Function(
  BuildContext context,
  Widget? child,
);

typedef TOnNoDataBuilder = Widget Function(
  BuildContext context,
  Widget? child,
);

typedef TPodList<T extends Object?> = Iterable<PodListenable<T>>;
typedef TPodDataList<T extends Object?> = Iterable<T>;

typedef TPodListN<T extends Object?> = Iterable<PodListenable<T?>?>;
typedef TPodDataListN<T extends Object?> = Iterable<T?>;
typedef TPodListCallbackN<T extends Object?> = TPodListN<T> Function();

typedef TFutureOrPod<T> = FutureOr<PodListenable<T>>;

// typedef TGlobalPodCompleter<T> = Completer<GlobalPod<T>>;

typedef TReducerFn<T> = AnyPod<T>? Function();

typedef TPodsResponderFn<T> = Iterable<AnyPod<T>?> Function();

// For a funcion that reduces multiple parent values to a child Pod.
typedef TValuesReducerFn<TChild, TParentList> = TChild Function(
  List<TParentList?> parentValues,
);
