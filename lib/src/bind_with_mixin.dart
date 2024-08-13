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

/// A mixin to manage the disposal of `Pod` instances.
mixin BindWithMixin on DisposeMixin {
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

/// Use `BindWithMixinState<T>` instead of `State<T>` to incorporate
/// `BindWithMixin`.
///
/// Example:
/// ```dart
/// class ExampleWidgetState extends BindWithMixinState<ExampleWidget> {
///   late final pStatus = Pod<String>('init').bindParent(this);
/// }
/// ```
abstract class BindWithMixinState<T extends StatefulWidget>
    extends _StatefulWidgetWithDisposable<T> with BindWithMixin {}

abstract class _StatefulWidgetWithDisposable<T extends StatefulWidget> extends State<T>
    implements DisposeMixin {}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

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

abstract class _ValueNotifierWithDisposable<T> extends ValueNotifier<T> implements DisposeMixin {
  _ValueNotifierWithDisposable(super.value);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Use `BindWithMixinChangeNotifier` instead of ChangeNotifier to incorporate
/// `BindWithMixin`.
///
/// Example:
/// ```dart
/// class ExampleChangeNotifier extends BindWithMixinChangeNotifier> {
///   late final pStatus = Pod<String>('init').bindParent(this);;
/// }
/// ```
abstract class BindWithMixinChangeNotifier extends _ChangeNotifierWithDisposable
    with BindWithMixin {}

abstract class _ChangeNotifierWithDisposable extends ChangeNotifier implements DisposeMixin {}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Use `BindWithMixinPodNotifier<T>` instead of PodNotifier<T> to incorporate
/// `BindWithMixin`.
///
/// Example:
/// ```dart
/// class ExamplePodNotifier<T> extends BindWithMixinPodNotifier<T>> {
///   late final pStatus = Pod<String>('init').bindParent(this);;
/// }
/// ```
abstract class BindWithMixinPodNotifier<T> extends _PodNotifierWithDisposable<T>
    with BindWithMixin {
  BindWithMixinPodNotifier(
    super.value, {
    required super.disposable,
    required super.temp,
  });
}

abstract class _PodNotifierWithDisposable<T> extends PodNotifier<T> implements DisposeMixin {
  _PodNotifierWithDisposable(
    super.value, {
    required super.disposable,
    required super.temp,
  });
}
