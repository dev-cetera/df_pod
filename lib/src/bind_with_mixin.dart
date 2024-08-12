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

import '_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin for classes that need to implement a `dispose` method.
mixin Disposable {
  void dispose();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin to manage the disposal of `Pod` instances.
mixin BindWithMixin on Disposable {
  //
  //
  //

  @protected
  final List<ChangeNotifier> $children = [];

  //
  //
  //

  /// Binds the ChangeNotifier [child] to this (the parent) so that the child
  /// will be disposed when this is disposed.
  T bindChild<T extends ChangeNotifier>(T child) {
    $children.add(child);
    return child;
  }

  //
  //
  //

  @override
  void dispose() {
    for (final child in $children) {
      child.dispose();
    }
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension BindParentOnChangeNotifierExtension<T extends ChangeNotifier> on T {
  /// Binds this ChangeNotifier to [parent] so that it will be disposed when
  /// [parent] is disposed.
  T bindParent<P extends BindWithMixin>(P parent) => parent.bindChild(this);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class _StatefulWidgetWithDisposable<T extends StatefulWidget>
    extends State<T> implements Disposable {}

/// Use `BindWithMixinState<T>` instead of `State<T>` to incorporate
/// `BindWithMixin`.
///
/// Example:
/// ```dart
/// class ExampleState extends BindWithMixinState<ExampleWidget> {
///   late final pStatus = Pod<String>('init').bindParent(this);
/// }
/// ```
abstract class BindWithMixinState<T extends StatefulWidget>
    extends _StatefulWidgetWithDisposable<T> with BindWithMixin {}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class _ValueNotifierWithDisposable<T> extends ValueNotifier<T>
    implements Disposable {
  _ValueNotifierWithDisposable(super.value);
}

/// Use `BindWithMixinValueNotifier<T>` instead of ValueNotifier<T> to incorporate
/// `BindWithMixin`.
///
/// Example:
/// ```dart
/// class ExampleValueNotifier<T> extends BindWithMixinValueNotifier<T>> {
///   late final pStatus = Pod<String>('init').bindParent(this);;
/// }
/// ```
abstract class BindWithMixinValueNotifier<T>
    extends _ValueNotifierWithDisposable<T> with BindWithMixin {
  BindWithMixinValueNotifier(super.value);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class _ChangeNotifierWithDisposable extends ChangeNotifier
    implements Disposable {}

/// Use `BindWithMixinChangeNotifier` instead of ChangeNotifier to incorporate
/// `BindWithMixin`.
///
/// Example:
/// ```dart
/// class MyChangeNotifier extends BindWithMixinChangeNotifier> {
///   late final pStatus = Pod<String>('init').bindParent(this);;
/// }
/// ```
abstract class BindWithMixinChangeNotifier extends _ChangeNotifierWithDisposable
    with BindWithMixin {}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class _PodListenableWithDisposable<T> extends PodListenable<T>
    implements Disposable {
  _PodListenableWithDisposable(super.value);
}

/// Use `BindWithMixinPodListenable<T>` instead of PodListenable<T> to incorporate
/// `BindWithMixin`.
///
/// Example:
/// ```dart
/// class ExamplePodListenable<T> extends BindWithMixinPodListenable<T>> {
///   late final pStatus = Pod<String>('init').bindParent(this);;
/// }
/// ```
abstract class BindWithMixinPodListenable<T>
    extends _PodListenableWithDisposable<T> with BindWithMixin {
  BindWithMixinPodListenable(super.value);
}
