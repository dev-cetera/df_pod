# Changelog


## [0.21.0]

- chore: standardize README and CI/CD workflows, remove donation links, update contact info and repository links
- chore: resolve analyzer issues

## [0.20.1]

- Released @ 10/2026 (UTC)
- Widen `df_log` to `^0.6.1` so apps on the current `df_log` (and `df_flutter_services` 0.2.1) resolve without a dependency override.

## [0.20.0]

- Released @ 2026-05 (UTC)
- Major release: medical-grade safety audit + isolate/web friendliness
  + performance pass. Test suite grew from 271 → 342 (71 new tests
  across `pod_audit_dispose_safety_test.dart`,
  `pod_audit_cache_safety_test.dart`, `pod_isolate_test.dart`,
  `pod_optimizations_test.dart`, and `pod_optimizations_listeners_test.dart`).
  All existing tests continue to pass; behaviour changes (where they
  exist) are called out below.

### Safety — silent-failure paths fixed

Medical-grade comes first. Every fix in this section addresses a path
that previously failed *silently* in release builds (where the
debug-only `assert(!_isDisposed)` guards are stripped). For a UI
showing patient data, a single frame of wrong data — or an
indefinitely-hung `await` — is unacceptable.

- **`pod.set(x)` / `pod.update(fn)` on a disposed pod is now a strict
  no-op.** Previously the `value` field was silently mutated in
  release; the dead pod kept its new value but never notified anyone,
  so any reader of `pod.value` saw stale-or-fresh data with no signal.
- **`pod.cond((v) => predicate)` on a disposed pod resolves the
  returned `Resolvable` to `Err`** instead of hanging forever. A
  predicate that *throws* (sync or on later notify) also resolves to
  `Err` — pre-0.20.0 a throwing predicate either propagated out of
  `cond()` or left the `SafeCompleter` permanently pending.
- **`PodBuilder` / `PodListBuilder` cache keys now incorporate the
  pod's `identityHashCode`.** A fresh mount under the same widget
  `Key` but with a different pod can no longer read the previous
  pod's cached value — pre-0.20.0 it showed stale data for the first
  frame. The most dangerous medical-grade hazard the audit found.
- **`PodBuilderCacheManager.cache(..., cacheDuration: null)` now
  skips caching entirely** and clears any prior entry under the
  same key. Earlier `null` meant "cache forever," which let entries
  accumulate indefinitely on long-running deployments.
- **`PodBuilderCacheManager` is now bounded** by
  `PodBuilderCacheManager.maxEntries` (default 256). On overflow the
  oldest entries are evicted in insertion order; refreshing an
  existing key never triggers eviction.
- **`PollingPodBuilder` catches exceptions from the poller** and
  logs them via `df_log`. Earlier a throwing poller propagated out
  of the `Timer.periodic` callback, leaving the timer alive and
  throwing on every tick.
- **`AsyncPodBuilder` surfaces pod-creation errors** via
  `snapshot.pod = Some(Err(...))`. Earlier errors were silently
  mapped to `None`, indistinguishable from the loading state.
- **`PodCollectionBuilder._syncSubscriptions` is now
  exception-safe.** A throwing `innerPods()` keeps the previous
  subscription set intact (logged); a throwing `addListener` /
  `removeListener` on a misbehaving Listenable is caught so the
  widget tree stays alive and bookkeeping stays consistent.
- **`pod.set(x)` no longer propagates exceptions from a buggy
  `operator ==`.** The equality short-circuit is wrapped in a
  try/catch — a throwing comparison falls back to "definitely
  changed" (over-notify is safer than missing a notify and safer
  than blowing up the caller).
- **`GenericPodMixin.dispose` is wrapped in try/finally** so a
  throwing child does not abort `super.dispose`. Half-disposed pods
  are no longer reachable.
- **`RootPod.fromStream` wires `onAfterDispose` before calling
  `stream.listen`**, so a synchronous emit during listen cannot leak
  the subscription.
- **`ChildPod._refresh` materialises its responder output to a
  `List`** so a `sync*` generator responder is consumed exactly
  once instead of being walked 3+ times (parents could otherwise
  desync silently).
- **`SharedPod._enqueue` logs `catchError`-absorbed errors** so
  fire-and-forget callers (`pod.set(x); // no await`) do not lose
  visibility on failed writes.
- **`WeakChangeNotifier.pinListener` is a no-op after dispose** so
  a pin call that escapes the disposed-pod check in
  `addStrongRefListener` cannot resurrect the pinned-listener set.

### Semantic landmines

- **`DisposablePod` no longer maintains a duplicate `_isDisposed`
  field.** `WeakChangeNotifier.isDisposed` (now public getter) is
  the single source of truth. Closes a window where the two flags
  briefly disagreed inside `dispose()`.
- **`GenericPodMixin._children` switched to `WeakReference`
  storage** so a derived `ChildPod` the caller forgot to retain can
  be GC'd instead of being pinned for the lifetime of the parent.
- **`RootPod.refresh()` now returns `Future<void>`** (was `void`).
  Callers can `await` to read post-notify state.
- **`Pod<(int, int)>` and other `Record`-valued pods short-circuit
  `set` on equal content** (Dart 3 structural record equality).
  Earlier every set notified.
- **`PodResultBuilder` / `PodListBuilder` read
  `widget.debounceDuration` at each event** (was captured at first
  build, so parent rebuilds that swapped the duration were silently
  ignored).

### Isolate and web friendliness

- **Core pods are usable in Flutter worker isolates.** The
  `notifyImmediately: false` path falls back to `scheduleMicrotask`
  when `WidgetsBinding.instance` is unavailable.
- **`SharedPod` wraps `SharedPreferences.getInstance()` failures**
  with an actionable `StateError` that explains the
  `BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken)`
  requirement — the most common worker-isolate misconfiguration. No
  more opaque `MissingPluginException` from the platform channel.
- **Added a *Platform support* matrix to `AGENTS.md`** documenting
  which APIs work on native vs web vs worker isolates, plus a
  worker-isolate setup snippet for `SharedPod`.
- **Builders remain UI-only** by nature (they are `Widget`s).
- Web caveat: `WeakReference` / `Finalizer` map to JS `WeakRef` /
  `FinalizationRegistry` — they work but collection timing is
  best-effort. The weak-`_children` design relies on this; for
  known-dead pods prefer explicit `dispose()` to avoid relying on GC.

### Performance — hot-path optimizations

Targeted at sustained notify cycles (sensor streams at 60 Hz,
dashboards with many tiles). All correctness-preserving; the test
suite grew rather than shrank.

- **ReducerPod diffs subscriptions** instead of remove-all-then-add-all
  per refresh. For N stable parents at high frequency this avoids
  2·N listener-list mutations per parent fire. Reducer throws now
  roll back any subscription mutation (pre-fix, a throwing reducer
  left the pod with zero subscriptions and silently frozen).
- **ReducerPod uses type-aware listener dispatch** —
  `addStrongRefListener` for `WeakChangeNotifier`-based pods,
  `addListener` for stock `ValueNotifier` / `ChangeNotifier` — same
  pattern as `PodCollectionBuilder._attach`.
- **`ReducerPod._listenables` is an identity-keyed `Set`** so the
  per-refresh "already subscribed?" check is O(1) without
  allocating a temporary `oldSet`.
- **`WeakChangeNotifier._compactListeners` fast-paths** when
  nothing was reentrantly removed. GC'd targets are detected inline
  during the notify loop, so the previous always-on post-notify
  scan is gone.
- **`ChildPod._refresh` identity-shortcuts** the subscription diff
  when the parent list is unchanged — common case for `.map()` and
  arity reducer helpers. Skips two `Set` allocations per refresh.
- **`PodBuilder` / `PodListBuilder` cache keys are memoised** on
  the State and invalidated in `didUpdateWidget`. Saves the
  `'$widgetKey|$identityHashCode'` string allocation on every pod
  fire.
- **`PodCollectionBuilder._syncSubscriptions` is adaptive** —
  linear identity scan for small inner lists (≤ 8 elements; the
  common case), set-based O(N + M) diff above that. Pre-0.20.0
  was O(N · M) for all sizes.
- **Deferred notifications coalesce** — multiple
  `set(.., notifyImmediately: false)` calls within one frame now
  produce one notification, not N. Previously each call scheduled
  its own post-frame callback and every listener was invoked N
  times in the same frame.
- **`_pendingConds` (used by `cond()`) is lazy-initialised** —
  pods that never call `cond()` no longer allocate the Set. Same
  for `WeakChangeNotifier._pinnedListeners` (used by
  `addSingleExecutionListener` and `cond`).

### Behaviour changes worth knowing

These are intentional consequences of the changes above:

- `responder: () => [pod, pod]` in `ReducerPod` (the same pod listed
  twice) now subscribes the pod **once**, not twice. The reducer
  still receives both entries in its arguments — only the
  subscription is dedup'd by identity. ChildPod already behaved
  this way via `_addChild`'s identity scan.
- Multiple back-to-back `set(.., notifyImmediately: false)` calls
  within one frame produce **1** listener notification, not N.
  Intermixed immediate `set(x)` calls remain uncoalesced (they
  fire synchronously as before).
- `pod.cond` with a throwing predicate no longer propagates the
  throw out of `cond()`; the throw becomes an `Err` on the returned
  `Resolvable`.
- `pod.set(x)` post-dispose is silently dropped; readers see the
  pre-dispose value.

### Tests

- 71 new tests across 5 new files. The audit-specific tests
  (`pod_audit_dispose_safety_test.dart`,
  `pod_audit_cache_safety_test.dart`) document every behaviour
  change called out above. `pod_isolate_test.dart` spawns real
  worker isolates from inside `flutter_test` and verifies core
  pod usage end-to-end. `pod_optimizations_test.dart` and
  `pod_optimizations_listeners_test.dart` exercise the perf
  changes for correctness (no perf assertions in CI).
- `PodFinalizerWrapper` now has explicit test coverage (construct,
  detach, multi-wrap, wrap-already-disposed).

### Internal cleanups

- **`df_safer_dart_annotations` is now an explicit dependency.**
  The web build (`flutter run -d chrome`) requires the direct
  import for `mustBeStrongRefOrError`, even though `dart analyze`
  reports it as unnecessary on native.
- All `Log.*` call sites in `lib/` now consistently include
  `tags: {#df_pod}`.
- ~290 lines of commented-out historical `WeakChangeNotifier`
  implementation removed from `weak_change_notifier.dart`.

### Example app

- `example/lib/main.dart` cleaned up: no `as` casts, no
  `.unwrap()` calls. Uses Dart 3 sealed-class pattern matching
  throughout. Fixed a long-standing cast bug in `SearchSummary`
  that surfaced on the web build as `TypeError: Ok<Object> is not
  int`.

## [0.19.1]

- Released @ 5/2026 (UTC)
- Update dependencies
- AI updates

## [0.19.0]

- Released @ 5/2026 (UTC)
- Fix caching issue with builders

## [0.18.17]

- Released @ 5/2026 (UTC)
- Fix issues with Claude

## [0.18.14]

- Released @ 2/2026 (UTC)
- Minor bugfixes

## [0.18.13]

- Released @ 12/2025 (UTC)
- Tiny fix

## [0.18.12]

- Released @ 12/2025 (UTC)
- Add fromStream constructor for Pod

## [0.18.11]

- Released @ 7/2025 (UTC)
- Update dependencies

## [0.18.10]

- Released @ 7/2025 (UTC)
- Update dependencies

## [0.18.9]

- Released @ 7/2025 (UTC)
- Refector and cleaning
- Update dependencies

## [0.18.8]

- Released @ 6/2025 (UTC)
- Update dependencies

## [0.18.7]

- Released @ 6/2025 (UTC)
- Update dependencies

## [0.18.6]

- Released @ 6/2025 (UTC)
- Update dependencies

## [0.18.5]

- Released @ 6/2025 (UTC)
- Update dependencies

## [0.18.4]

- Released @ 6/2025 (UTC)
- Update dependencies

## [0.18.3]

- Released @ 6/2025 (UTC)
- Update dependencies

## [0.18.2]

- Released @ 6/2025 (UTC)
- chore: Update dependencies

## [0.18.1]

- Released @ 6/2025 (UTC)
- feat: Add reduce function to OnOptionSnapshot and OnOptionListSnapshot

## [0.18.0]

- Released @ 6/2025 (UTC)
- breaking: Improved PodBuilders

## [0.17.1]

- Released @ 6/2025 (UTC)
- chore: Update dependencies

## [0.17.0]

- Released @ 6/2025 (UTC)
- breaking: Remove null, use monads and update documentatipn

## [0.16.10]

- Released @ 6/2025 (UTC)
- feat: Add notifyImmediately to set and update

## [0.16.9]

- Released @ 5/2025 (UTC)
- chore: Update dependencies

## [0.16.8]

- Released @ 3/2025 (UTC)
- docs: Update readme

## [0.16.7]

- Released @ 3/2025 (UTC)
- chore: Tidy code and remove deprecated elements

## [0.16.6]

- Released @ 3/2025 (UTC)
- chore: Update dependencies

## [0.16.4]

- Released @ 2/2025 (UTC)
- chore: Update dependencies

## [0.16.3]

- Released @ 2/2025 (UTC)
- fix: Fix debouncing logic in PodBuilder and PodListBuilder

## [0.16.2]

- Released @ 2/2025 (UTC)
- chore: Small fix

## [0.16.1]

- Released @ 2/2025 (UTC)
- chore: Upgrade dependencies

## [0.16.0]

- Released @ 2/2025 (UTC)
- chore: Update dependencies

## [0.15.1]

- Released @ 2/2025 (UTC)
- feat: Add caching mechnism to PodBuilders

## [0.15.0]

- Released @ 2/2025 (UTC)
- breaking: Update dependencies

## [0.14.12]

- Released @ 2/2025 (UTC)
- feat: Add additional constructors for PodBuilder, PollingPodBuilder and PodListBuilder

## [0.14.11]

- Released @ 2/2025 (UTC)
- feat: Add optional debouncers to builders

## [0.14.10]

- Released @ 2/2025 (UTC)
- chore: Add nonNull and cond methods; rename untilPredicate method to cond

## [0.14.9]

- Released @ 2/2025 (UTC)
- feat: Add a very useful untilPredicate methods to pods

## [0.14.8]

- Released @ 2/2025 (UTC)
- fix: Fix null issue

## [0.14.7]

- Released @ 2/2025 (UTC)
- fix: Another annoying bugfix

## [0.14.6]

- Released @ 2/2025 (UTC)
- chore: Update F

## [0.14.5]

- Released @ 2/2025 (UTC)
- fix: Stupid bugfix

## [0.14.4]

- Released @ 2/2025 (UTC)
- chore: Change FuturePod to SafeFuturePod that uses Option and Result

## [0.14.3]

- Released @ 2/2025 (UTC)
- chore: Update dependencies

## [0.14.1]

- Released @ 2/2025 (UTC)
- chore: Minor performance update

## [0.14.0]

- Released @ 2/2025 (UTC)
- breaking: Update dependencies and docs

## [0.13.9]

- Released @ 2/2025 (UTC)
- docs: Improve documentation

## [0.13.8]

- Released @ 2/2025 (UTC)
- chore: Update dependencies

## [0.13.7]

- Released @ 2/2025 (UTC)
- fix: Add back PodListenable that was accidentally deleted

## [0.13.6]

- Released @ 2/2025 (UTC)
- fix: Add back asPodDisposable() that was accidentally deleted

## [0.13.5]

- Released @ 2/2025 (UTC)
- chore: Add compatibility with ValueListenable

## [0.13.4]

- Released @ 2/2025 (UTC)
- chore: Add safety features to discourage the use of weak referenced listeners for Pod and WeakChangeNotifier

## [0.13.3]

- Released @ 2/2025 (UTC)
- chore: Update SharedPod

## [0.13.2]

- Released @ 2/2025 (UTC)
- chore: Add initialValue property to SharedPod

## [0.13.1]

- Released @ 2/2025 (UTC)
- chore: Improve SharedPod

## [0.13.0]

- Released @ 2/2025 (UTC)
- breaking: Implement automatic resource disposal for Pods via WeakReference

## [0.12.2]

- Released @ 2/2025 (UTC)
- chore: Update dependencies

## [0.12.1]

- Released @ 2/2025 (UTC)
- fix: Fix null issue with ReducerPod

## [0.12.0]

- Released @ 2/2025 (UTC)
- breaking: Remove deprecated ListCalbackBuilder, ListCallbackStateBuilder, and PoldListCallbackBuilder, and simplify ReducerPod

## [0.11.23]

- Released @ 2/2025 (UTC)
- fix: Change static constructor to factory constructor in ReducerPod

## [0.11.22]

- Released @ 2/2025 (UTC)
- chore: Improve ReducerPod

## [0.11.21]

- Released @ 2/2025 (UTC)
- refactor: Move ResponderPod to ReducerPod.single

## [0.11.20]

- Released @ 2/2025 (UTC)
- chore: Change set method of Pods to be sync and not async

## [0.11.19]

- Released @ 2/2025 (UTC)
- feat: Update responder in ReducerPod to return FutureOr

## [0.11.18]

- Released @ 2/2025 (UTC)
- refactor: Update return type from dynamic to generic in responder of ResponsivePod

## [0.11.17]

- Released @ 2/2025 (UTC)
- feat: Add a single element ReducerPod called ResponsivePod

## [0.11.16]

- Released @ 2/2025 (UTC)
- chore: Simplify ReducerPod

## [0.11.15]

- Released @ 2/2025 (UTC)
- feat: Add reset method to ReducerPod

## [0.11.14]

- Released @ 2/2025 (UTC)
- feat: Pass current pod(s) of builders to their onDispose

## [0.11.13]

- Released @ 2/2025 (UTC)
- feat: Improve responder of ReducerPod to take Futures

## [0.11.12]

- Released @ 2/2025 (UTC)
- chore: Upgrade dependencies

## [0.11.11]

- Released @ 2/2025 (UTC)
- refactor: FutureToPod now use FutureOr<T>

## [0.11.10]

- Released @ 2/2025 (UTC)
- feat: Add FutureToPod

## [0.11.9]

- Released @ 2/2025 (UTC)
- chore: Add new ReducerPod

## [0.11.8]

- Released @ 2/2025 (UTC)
- chore: Update dependencies

## [0.11.7]

- Released @ 2/2025 (UTC)
- chore: Update dependencies

## [0.11.6]

- Released @ 2/2025 (UTC)
- chore: Minor issue fix, update dependencies

## [0.11.4]

- Released @ 2/2025 (UTC)
- chore: Improve comments, readme and update dependencies

## [0.11.2]

- Released @ 2/2025 (UTC)
- refactor: Update GenericPodMixin to improve performance

## [0.11.1]

- Released @ 2/2025 (UTC)
- tidy: Tidy code and update workflow scripts

## [0.11.0]

- Released @ 2/2025 (UTC)
- breaking: Replace df_will_dispose with df_cleanup dependency, remove state management utils

## [0.10.1]

- Released @ 2/2025 (UTC)
- feat: Add additional callbacks for PodService

## [0.10.0]

- Released @ 2/2025 (UTC)
- breaking: Simplify PodService and add the DI class to manage dependency injection

## [0.9.5]

- Released @ 2/2025 (UTC)
- chore: TempPod and GlobalPod now extends ProtectedPod
- chore: Add more casting methods to the extension CastPodListenableX

## [0.9.4]

- Released @ 2/2025 (UTC)
- chore: Add casting methods for ValueListenable types

## [0.9.3]

- Released @ 2/2025 (UTC)
- chore: Update dependencies, add experimental EasyPod
- docs: Update comments

## [0.9.2]

- Released @ 2/2025 (UTC)
- chore: Update df_cleanup dependency

## [0.9.1]

- Released @ 2/2025 (UTC)
- chore: Update dependencies

## [0.9.0]

- Released @ 2/2025 (UTC)
- breaking: Update structure, examples and implement df_cleanup package

## [0.8.0+1]

- Released @ 2/2025 (UTC)
- docs: Improve readme

## [0.8.0]

- Released @ 2/2025 (UTC)
- breaking: Refactor code to address minor complexity and stability issues
- docs: Update readme

## [0.7.2]

- Released @ 2/2025 (UTC)
- refactor: Simplify temp and global Pods

## [0.7.1]

- Released @ 2/2025 (UTC)
- refactor: Update OnLoadingSnapshot to use createdAt instead of elapsed

## [0.7.0]

- Released @ 2/2025 (UTC)
- refactor: Update builders to pass context again

## [0.6.0]

- Released @ 2/2025 (UTC)
- fix: Fix issues with ListCallbackBuilder and ListCallbackStateBuilder and simplify

## [0.5.0]

- Released @ 2/2025 (UTC)
- refactor: Rename CallbackBuilder to ListCallbackBuilder, add ListCallbackStateBuilder, refactor
- chore: Update dependencies

## [0.4.0]

- Released @ 2/2025 (UTC)
- chore: Fix and rename builders and provide usage example of CallbackBuilder and PodListCallbackBuilder
- refactor: Simplify code structure

## [0.3.4]

- Released @ 2/2025 (UTC)
- docs: Update library description comment
- chore: Update topics to pubspec.yaml

## [0.3.3]

- Released @ 2/2025 (UTC)
- chore: Rename tests folder to more_tests and address pub warnings
- fix: Fix potential issues in pubspec.yaml and update dependencies
- docs: Update readme and details in pubspec.yaml

## [0.3.2]

- Released @ 2/2025 (UTC)
- chore: Update dependencies for Flutter compatibility

## [0.3.1]

- Released @ 2/2025 (UTC)
- chore: Update Flutter SDK version

## [0.3.0]

- Released @ 2/2025 (UTC)
- refactor: Address null issues
- refactor: Move Pod reducers to classes and refactor typedefs
- chore: Remove unused exceptions and update comments
- feat: Separate global and temp Pods into their own Pods
- docs: Improve readme and usage example

## [0.2.3]

- Released @ 2/2025 (UTC)
- refactor: Remove unnecessary await in shared_pod.dart

## [0.2.2]

- Released @ 2/2025 (UTC)
- feat: Remove FuturePodBuilder and FuturePodListBuilder
- feat: PodBuilder, PodListBuilder and PollingPodBuilder can now use FutureOr

## [0.2.1]

- Released @ 2/2025 (UTC)
- feat: Add FuturePodBuilder and FuturePodListBuilder

## [0.2.0]

- Released @ 2/2025 (UTC)
- feat: Add SharedPod
- refactor: Refactor for clarity

## [0.1.0]

- Released @ 2/2025 (UTC)
- Initial release
