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
    if (expiration != null && expiration.isBefore(DateTime.now())) {
      _expirations.remove(key);
      return null;
    }
    return _inner.get(key);
  }
}

typedef TGlobalPod<T extends Object> =
    Resolvable<GenericPod<Option<Result<T>>>>;
