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

/// An enhanced alternative to [ValueNotifier] that provides additional
/// lifecycle management capabilities through the [PodDisposableMixin].
abstract class PodNotifier<T> extends ChangeNotifier
    with PodDisposableMixin<T> {
  //
  //
  //

  @override
  final bool disposable;

  @override
  final bool temp;

  T _value;

  @override
  T get value => _value;

  final TOnBeforeDispose<T>? onBeforeDispose;

  /// Creates a new [Pod] from the given [value]. Calls [onBeforeDispose]
  /// immediately before disposing.
  ///
  /// This [Pod] is not automatically disposed of, so it is important to
  /// manually [dispose] of it when it is no longer needed to free up resources.
  PodNotifier(
    T value, {
    TOnBeforeDispose<T>? onBeforeDispose,
  }) : this._unsafe(
          value,
          disposable: true,
          temp: false,
        );

  /// Creates a new temporary [PodNotifier] from the given [value]. Calls
  /// [onBeforeDispose] immediately before disposing.
  ///
  /// Temporary Pods are designed to be used with widgets that support them,
  /// such as [PodBuilder] and other builders in the `df_pod` package.
  /// These Pods are automatically disposed of when the associated widget
  /// is removed from the widget tree, ensuring efficient resource management
  /// without manual intervention.
  ///
  /// Use temporary Pods when you want a Pod to have a lifecycle tied to
  /// the widget tree, avoiding the need to manage disposal explicitly.
  PodNotifier.temp(
    T value, {
    TOnBeforeDispose<T>? onBeforeDispose,
  }) : this._unsafe(
          value,
          disposable: true,
          temp: true,
        );

  /// Creates a new non-disposable/global [PodNotifier] from the given [value].
  /// Calls [onBeforeDispose] immediately before disposing.
  ///
  /// These Pods cannot be disposed of, and attempting to do so will throw a
  /// [DoNotDisposePodException].
  ///
  /// Non-disposable Pods should not be used in local scopes. They are intended
  /// to be used as global variables that persist throughout the lifetime of
  /// your app.
  PodNotifier.global(
    T value,
  ) : this._unsafe(
          value,
          disposable: false,
          temp: false,
        );

  PodNotifier._unsafe(
    this._value, {
    required this.disposable,
    required this.temp,
    this.onBeforeDispose,
  })  : assert(
          temp && disposable == true || !temp,
          'A PodNotifier marked as "temp" must also be marked as "disposable".',
        ),
        assert(
          disposable || onBeforeDispose == null,
          'A non-disposable PodNotifier cannot have an onBeforeDispose callback.',
        );

  /// Adds a [listener] to this [PodNotifier] that will be triggered only once.
  /// Once the [listener] is called, it is automatically removed, unlike the
  /// persistent behavior of [addListener].
  ///
  /// This method is useful when you need a callback to execute a single time
  /// in response to a change, ensuring it does not linger in memory or respond
  /// to future changes.
  void addSingleExecutionListener(VoidCallback listener) {
    late final VoidCallback tempListener;
    tempListener = () {
      listener();
      removeListener(tempListener);
    };
    addListener(tempListener);
  }

  /// Calls [onBeforeDispose] then dipsoses this [PodNotifier] if [disposable],
  /// then sets [isDisposed] to `true`. Successive calls to this method will be
  /// ignored.
  @override
  void dispose() {
    super.maybeDispose(() {
      onBeforeDispose?.call(this.value);
      super.dispose();
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TOnBeforeDispose<T> = void Function(T value)?;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An extension on [PodNotifier] that provides utility methods for
/// down-casting to [Pod] instances.
extension AsPodOnPodNotifierX<T> on PodNotifier<T> {
  /// Attempts to cast this [PodNotifier] to a [Pod] instance. Returns `null`
  /// if the cast is unsuccessful.
  ///
  /// Prefer using [asPod] unless there is a specific need for [asPodOrNull].
  ///
  /// Note: This method is marked as [visibleForTesting] to remind developers
  /// to structure their code in a way that avoids frequent casting,
  /// ensuring clearer and more maintainable code.
  @visibleForTesting
  Pod<T>? asPodOrNull() => letAsOrNull<Pod<T>>(this);

  /// Attempts to cast this [PodListenable] to a [PodNotifier] instance.
  /// Throws a [CannotCastPodException] an if the cast is unsuccessful.
  ///
  /// Note: This method is marked as [visibleForTesting] to remind developers
  /// to structure their code in a way that avoids frequent casting,
  /// ensuring clearer and more maintainable code.
  @visibleForTesting
  Pod<T> asPod() {
    try {
      return this as Pod<T>;
    } catch (_) {
      throw CannotCastPodException();
    }
  }
}
