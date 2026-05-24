//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Auto-disposes its wrapped [PodNotifier] when the wrapper itself becomes
/// unreachable.
///
/// Usage: hold the wrapper, NOT the pod directly. The pod is reachable for as
/// long as the wrapper is reachable; once the wrapper is collected, the
/// finalizer fires and disposes the pod, then the pod itself becomes
/// collectible.
///
/// Caveats:
/// - The pod IS pinned alive by the finalizer token until the wrapper is
///   collected. This is intentional — without it the pod could be collected
///   while still in use elsewhere and the finalizer would have nothing to
///   dispose.
/// - Finalizers are best-effort. Dart makes no guarantee about when (or
///   whether) a finalizer fires. Do NOT rely on this for resources that
///   absolutely must be released (use explicit [PodNotifier.dispose] for
///   those).
/// - If you also hold a strong reference to the pod elsewhere, the pod
///   stays alive via that other reference, the wrapper can be collected
///   independently (which detaches the finalizer), and nothing disposes
///   the pod automatically.
final class PodFinalizerWrapper<T extends Object> {
  /// The wrapped pod, kept as a [WeakReference] so the wrapper does not pin
  /// it beyond what the finalizer token does.
  final WeakReference<PodNotifier<T>> pod;

  static final _finalizer = Finalizer<PodNotifier<dynamic>>((pod) {
    if (!pod.isDisposed) pod.dispose();
  });

  PodFinalizerWrapper(PodNotifier<T> pod) : pod = WeakReference(pod) {
    // `detach: this` lets [detach] cancel the registration cleanly.
    _finalizer.attach(this, pod, detach: this);
  }

  /// Detach from the finalizer so the pod will NOT be auto-disposed when
  /// the wrapper is GC'd. Use this to transfer ownership back to a caller
  /// that will dispose manually.
  void detach() => _finalizer.detach(this);
}
