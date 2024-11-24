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

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A Pod that is initially [None] then sets its [value] when a [FutureOr]
/// completes as [Ok] or fails as [Err].
base class SafeFuturePod<T> extends PodNotifier<Option<Result<T, Object>>>
    with GenericPod<Option<Result<T, Object>>> {
  /// Creates a [SafeFuturePod] with the specified [future].
  SafeFuturePod(FutureOr<T> future) : super(const None()) {
    consec(
      future,
      (e) => _set(Some(Ok(e))),
      onError: (e) => _set(Some(Err(e))),
    );
  }

  /// Creates a [SafeFuturePod] with the specified [value].
  SafeFuturePod.value(T value) : super(Some(Ok(value)));

  /// Unwraps the Pod's value.
  T unwrap() => value.some.unwrap().ok.value;
}
