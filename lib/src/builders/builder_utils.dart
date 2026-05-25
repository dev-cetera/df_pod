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

class BuilderSnapshot {
  final Widget? child;
  const BuilderSnapshot({required this.child});
}

/// Process-wide value cache for keyed builders ([PodBuilder] /
/// [PodListBuilder]).
///
/// **Scope warning**: this is a singleton. Two `PodBuilder`s anywhere in
/// the app with the same `key` share entries. The type-cast on read
/// (`cached is Result<T>`) prevents type confusion across mismatched
/// types, but you can still see silent cross-screen value sharing if two
/// widgets reuse a `Key`. Prefer scoped, unique keys (`ValueKey('feature:patientId')`)
/// over short generic ones.
///
/// **Expiration semantics**:
/// - `cacheDuration > 0`: entry expires after the duration; eviction is
///   lazy (the next [get] notices the timestamp has passed and clears
///   both maps).
/// - `cacheDuration == Duration.zero`: stored but immediately evicted on
///   first [get] — effectively "no cache."
/// - `cacheDuration == null`: **the store is skipped entirely**. Earlier
///   revisions treated null as "cache forever" which caused entries to
///   accumulate indefinitely on long-running deployments; that footgun
///   is now closed. Callers that want unbounded caching should pass an
///   explicit large `Duration`.
///
/// Expiration is lazy: nothing fires when an entry ages out, the next
/// [get] for that key sees the timestamp has passed and evicts it from
/// both the value map and the expiry map. This avoids leaving real
/// [Timer]s pending in [flutter_test] (which fails with
/// "A Timer is still pending even after the widget tree was disposed").
final class PodBuilderCacheManager {
  final CacheManager<Object> _inner;
  final _expirations = <String, DateTime>{};
  PodBuilderCacheManager._(this._inner);

  static final i = PodBuilderCacheManager._(CacheManager<Object>());

  /// Hard cap on simultaneously-cached entries. Prevents unbounded
  /// memory growth in long-running deployments (medical-grade apps may
  /// run for days). When the cap is reached on a *new-key* insert, the
  /// oldest entries (insertion-order) are evicted to make room.
  ///
  /// Tunable for unusual workloads — assignable via [maxEntries].
  static int maxEntries = 256;

  void cache(String key, Object value, {Duration? cacheDuration}) {
    if (cacheDuration == null) {
      // Null means "do not cache." Clear any prior entry under this key
      // so subsequent reads do not pick up a stale value.
      _evict(key);
      return;
    }
    // If we are at capacity and this is a *new* key, evict the oldest
    // entry first. Refreshing an existing key never grows the map and
    // does not trigger eviction.
    if (!_expirations.containsKey(key) && _expirations.length >= maxEntries) {
      final overflow = _expirations.length - maxEntries + 1;
      final toEvict = _expirations.keys.take(overflow).toList();
      for (final k in toEvict) {
        _evict(k);
      }
    }
    _inner.cache(key, value);
    _expirations[key] = DateTime.now().add(cacheDuration);
  }

  Object? get(String? key) {
    if (key == null) return null;
    final expiration = _expirations[key];
    if (expiration != null && !expiration.isAfter(DateTime.now())) {
      _evict(key);
      return null;
    }
    return _inner.get(key);
  }

  /// Removes [key] from both maps together. The previous behavior of
  /// removing only from [_expirations] turned every short-lived widget key
  /// into a permanent entry in [_inner].
  void _evict(String key) {
    _expirations.remove(key);
    _inner.remove(key);
  }

  /// Clears every entry. Intended for tests; production code should let
  /// entries expire naturally.
  @visibleForTesting
  void clear() {
    _expirations.clear();
    _inner.clear();
  }

  /// Current entry count. Exposed for tests and diagnostics; production
  /// code should not depend on this for behaviour.
  @visibleForTesting
  int get length => _expirations.length;
}

typedef TGlobalPod<T extends Object>
    = Resolvable<GenericPod<Option<Result<T>>>>;
