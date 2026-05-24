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
/// Expiration is lazy: nothing fires when an entry ages out, the next
/// [get] for that key sees the timestamp has passed and evicts it from
/// both the value map and the expiry map. This avoids leaving real
/// [Timer]s pending in [flutter_test] (which fails with
/// "A Timer is still pending even after the widget tree was disposed").
///
/// Earlier revisions only deleted from [_expirations] on expiry, leaving
/// [_inner] entries leaking forever. Always evict both maps together.
final class PodBuilderCacheManager {
  final CacheManager<Object> _inner;
  final _expirations = <String, DateTime>{};
  PodBuilderCacheManager._(this._inner);

  static final i = PodBuilderCacheManager._(CacheManager<Object>());

  void cache(String key, Object value, {Duration? cacheDuration}) {
    _inner.cache(key, value);
    if (cacheDuration != null) {
      _expirations[key] = DateTime.now().add(cacheDuration);
    } else {
      _expirations.remove(key);
    }
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
}

typedef TGlobalPod<T extends Object> =
    Resolvable<GenericPod<Option<Result<T>>>>;
