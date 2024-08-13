//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_type/df_type.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A shorthand alias for [PodListenable].
typedef P<T> = PodListenable<T>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An extension of [ValueListenable], providing a foundational layer for the
/// [Pod].
///
/// The [PodListenable] class serves as a simplified interface to [Pod],
/// designed specifically for passing to [PodBuilder] or other supported
/// builders.
///
/// It restricts access to modification methods, focusing solely on the
/// listenable aspect without exposing setters or updaters.
///
/// This abstraction is useful for scenarios where you want to expose only
/// necessary functionalities, ensuring that developers interact with the Pod's
/// state in a controlled manner, preventing accidental changes.
///
/// [PodListenable] is intended for use in UI components where you need to
/// respond to state changes without altering the state directly. In contrast,
/// regular Pods provide methods like `set` or `update` for state modifications.
///
/// ### Example:
///
/// ```dart
/// PodListenable<int> pNumber = Pod<int>(55);
/// ```
///
/// In this example, `pNumber` is limited to the interface provided by
/// [PodListenable], ensuring that it can only be used for listening to changes,
/// while retaining the ability to cast back to [Pod] if advanced operations
/// are needed, e.g.:
///
/// ```dart
/// Pod.cast(pNumber).set(2);
/// ```
abstract class PodListenable<T> extends ValueListenable<T> {}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An extension on [PodListenable] that provides utility methods for casting
/// to a [Pod] instance.
extension AsPodOnPodListenableX<T> on PodListenable<T> {
  /// Attempts to cast this [PodListenable] to a [Pod] instance. Returns `null`
  /// if the cast is unsuccessful.
  ///
  /// Prefer using [asPod] unless there is a specific need for [asPodOrNull].
  ///
  /// This method is marked as [visibleForTesting] to remind developers
  /// to structure their code in a way that avoids frequent casting,
  /// ensuring clearer and more maintainable code.
  @visibleForTesting
  Pod<T>? asPodOrNull() => letAsOrNull<Pod<T>>(this);

  /// Attempts to cast this [PodListenable] to a [Pod] instance. Throw an if
  /// the cast is unsuccessful.
  ///
  /// This method is marked as [visibleForTesting] to remind developers
  /// to structure their code in a way that avoids frequent casting,
  /// ensuring clearer and more maintainable code.
  @visibleForTesting
  Pod<T> asPod() => this as Pod<T>;
}
