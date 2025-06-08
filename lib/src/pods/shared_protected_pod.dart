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

import 'package:df_safer_dart/df_safer_dart.dart' show Async;
import 'package:meta/meta.dart' show protected;

import '/src/_mixins/protected_pod_mixin.dart';
import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A [SharedPod] that protects [addStrongRefListener] and [dispose], hiding
/// these methods from external access to prevent misuse or unintended behavior.
///
/// This is useful when you want to restrict direct access to lifecycle
/// management methods of the Pod, ensuring that these operations are only
/// handled internally or through controlled mechanisms.
///
/// Extends [SharedPod] and uses [ProtectedPodMixin] to encapsulate and manage
/// the protection of these critical methods.
base class SharedProtectedPod<A extends Object, B extends Object>
    extends SharedPod<A, B>
    with ProtectedPodMixin {
  //
  //
  //

  @protected
  SharedProtectedPod(
    super.key, {
    required super.fromValue,
    required super.toValue,
    required super.initialValue,
  });

  //
  //
  //

  /// Creates and initializes a [SharedProtectedPod] by loading its value from storage.
  static Async<SharedProtectedPod<A, B>>
  create<A extends Object, B extends Object>(
    String key, {
    required A Function(B? rawValue) fromValue,
    required B Function(A value) toValue,
    required A initialValue,
  }) => Async(() async {
    final instance = SharedProtectedPod<A, B>(
      key,
      fromValue: fromValue,
      toValue: toValue,
      initialValue: initialValue,
    );
    await instance.refresh();
    return instance;
  });
}
