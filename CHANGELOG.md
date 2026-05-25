# Changelog

## [0.23.0]

- Released @ 5/2026 (UTC)
- Performance optimization pass targeting hot paths used during sustained
  notify cycles (e.g. sensor streams at 60 Hz, dashboards with many tiles).
  All optimizations are *correctness-preserving* — the existing 287
  behavior tests still pass unchanged; 9 new regression tests in
  `pod_optimizations_v023_test.dart` document the new behavior. Test
  suite: 306 → 315.
- **Performance**:
  - **O1**: `ReducerPod` now diffs its parent subscriptions instead of
    removing-all-then-adding-all on every refresh. For a `ReducerPod`
    watching N stable parents that update at high frequency, this
    avoids 2·N listener-list mutations per parent fire. **Bonus
    correctness fix**: a reducer that throws now rolls back any
    subscription mutation, so the pod can keep observing its previous
    parents — pre-O1 a throwing reducer left the pod with zero
    subscriptions and silently frozen.
  - **O2**: `WeakChangeNotifier._compactListeners` fast-paths when
    nothing was reentrantly removed during the notify cycle. Pre-O2,
    every notify walked the entire listener array looking for dead
    weak references even when none had died. GC'd targets are now
    detected inline during the notify loop (one branch per slot, no
    extra walk).
  - **O3**: `ChildPod._refresh` element-identity-shortcuts the
    subscription diff when the parent list is unchanged — the common
    case for `.map()` and arity reducer helpers whose responder
    returns the same parents on every fire. Skips two `Set` allocations
    per refresh.
  - **O4**: `PodBuilder` / `PodListBuilder` cache keys are memoized on
    the State and invalidated in `didUpdateWidget`. Saves the
    `'$widgetKey|$identityHashCode'` string allocation on every pod
    fire (each fire previously triggered two: one for `_setValue`,
    one for `_cacheValue`).
  - **MO1**: `PodCollectionBuilder._syncSubscriptions` diff is now
    O(N + M) using identity sets, down from O(N · M) with nested
    `containsIdentical` scans. Negligible for small inner-pod lists
    but quadratic improvement for dashboards with many tiles.
- **Internal**:
  - `_pod_list_builder.dart` and `_pod_collection_builder.dart` lost
    their unused `_containsIdentical` helper (folded into the new
    set-based diff).
  - All `Log.*` call sites in `lib/` now consistently include
    `tags: {#df_pod}` — one missing site in `disposable_pod.dart`'s
    `onAfterDispose` catch was fixed.
  - `df_safer_dart_annotations` is now an explicit dependency (was
    transitive via `df_safer_dart`) — the web build (`flutter run -d
    chrome`) requires the direct import for `mustBeStrongRefOrError`,
    even though `dart analyze` reports it as unnecessary on native.
- **Example**:
  - Fixed a cast bug in `example/lib/main.dart`'s `SearchSummary`
    that was double-unwrapping (`Option → Result`) incorrectly,
    surfacing as a `TypeError: Ok<Object> is not int` on the web build.

## [0.22.0]

- Released @ 5/2026 (UTC)
- Second medical-grade audit pass — addresses silent data-integrity
  hazards, hang-after-throw paths, and unbounded resource growth that
  were still latent after v0.21.0. Test suite grew 287 → 306 (12 new
  regression tests in `pod_audit_v022_test.dart`).
- **Behavior changes — critical (medical-grade)**:
  - `PodBuilder` / `PodListBuilder` cache keys now incorporate the
    pod's `identityHashCode`. A fresh mount with the same widget `Key`
    but a different pod can **no longer** read the previous pod's
    cached value — pre-v0.22.0 it showed stale data for the first
    frame, which is unacceptable when the pods represent different
    patients / sensors / readings. (Finding **A1**.)
  - `pod.cond((v) => predicate)` whose predicate throws now resolves
    the returned `Resolvable` to `Err` instead of either propagating
    a sync throw out of `cond()` or leaving the completer stuck
    pending until the pod is disposed. Callers awaiting cond get a
    clean failure path. (Finding **A2**.)
  - `pod.set(x)` no longer propagates exceptions from a buggy
    `operator ==`. The equality short-circuit is wrapped in a
    try/catch — a throwing comparison falls back to "definitely
    changed" (over-notify is safer than missing a notify and safer
    than blowing up the caller). (Finding **A5**.)
- **Robustness**:
  - `PodCollectionBuilder._syncSubscriptions` now contains exceptions:
    a throwing `innerPods()` keeps the previous subscription set
    intact (logged via `df_log`); a throwing `addListener` /
    `removeListener` on a misbehaving `Listenable` is caught so the
    widget tree stays alive and bookkeeping stays consistent.
    (Finding **A3**.)
  - `PodBuilderCacheManager` is now bounded by
    `PodBuilderCacheManager.maxEntries` (default 256). On overflow
    the oldest entries are evicted in insertion order. Refreshing an
    existing key never triggers eviction. Long-running deployments
    (medical apps running for days) can no longer accumulate cache
    entries indefinitely. The `length` getter is exposed via
    `@visibleForTesting` for diagnostics. (Finding **A4**.)
- **Tests**:
  - `pod_audit_v022_test.dart` adds 12 regression tests covering A1–A6.
  - `PodFinalizerWrapper` now has explicit test coverage (construct,
    detach, multi-wrap, wrap-already-disposed). (Finding **A6**.)
- **Behavior changes — tests**:
  - The two cache tests that previously asserted the v0.18.18 "same
    key, different pod, briefly serves stale" behaviour have been
    flipped to assert the new safe behaviour (the new pod's live
    value wins immediately).

## [0.21.0]

- Released @ 5/2026 (UTC)
- Soundness audit pass — addresses several silent-failure paths and
  semantic landmines uncovered while preparing the package for
  medical-grade use. Test suite grew from 271 to 287 (15 new regression
  tests in `pod_audit_v021_test.dart`).
- **Behavior changes**:
  - `pod.set(x)` / `pod.update(fn)` on a disposed pod is now a strict
    no-op. Earlier the `value` field was silently mutated in release
    builds, which was the package's most dangerous failure mode (the
    debug-only assert in `notifyListeners` was the only guard).
  - `pod.cond((v) => predicate)` whose predicate never matches before
    the pod is disposed now resolves the returned `Resolvable` to `Err`
    instead of hanging forever. `await pod.cond(...)` callers no longer
    deadlock.
  - `RootPod.refresh()` now returns `Future<void>` (was `void`). Callers
    can `await` to read post-notify state.
  - `PodBuilderCacheManager.cache(..., cacheDuration: null)` now skips
    caching entirely and clears any prior entry under the same key.
    Earlier null meant "cache forever," causing entries to accumulate
    indefinitely on long-running deployments. Pass an explicit large
    `Duration` for the previous behavior.
  - `Pod<(int, int)>` and other `Record`-valued pods now short-circuit
    `set` on equal content (Dart 3 structural record equality). Earlier
    every set notified.
  - `PollingPodBuilder` now catches exceptions thrown by the poller and
    logs them via `df_log`. Earlier a throwing poller propagated out of
    the `Timer.periodic` callback, leaving the timer alive and throwing
    on every tick (unbounded log spam, no recovery).
  - `AsyncPodBuilder` now surfaces pod-creation errors via
    `snapshot.pod = Some(Err(...))`. Earlier errors were silently mapped
    to `None`, indistinguishable from the loading state.
  - `PodResultBuilder` / `PodListBuilder` now read `widget.debounceDuration`
    at each event (was captured at first build, so parent rebuilds that
    swapped the duration were silently ignored).
- **Internal soundness**:
  - `DisposablePod` no longer maintains a duplicate `_isDisposed` field.
    `WeakChangeNotifier.isDisposed` (now public getter) is the single
    source of truth. Closes a window where the two flags briefly
    disagreed inside `dispose()`.
  - `GenericPodMixin.dispose` is wrapped in try/finally so a throwing
    child does not abort `super.dispose`. Half-disposed pods are no
    longer reachable.
  - `GenericPodMixin._children` switched to `WeakReference` storage so a
    derived `ChildPod` the caller forgot to retain can be GC'd instead
    of being pinned for the lifetime of the parent.
  - `_set` with `notifyImmediately: false` now falls back to
    `scheduleMicrotask` if `WidgetsBinding.instance` is unavailable
    (background isolate, dart-only test).
  - `RootPod.fromStream` wires `onAfterDispose` before calling
    `stream.listen`, so a synchronous emit during listen cannot leak the
    subscription.
  - `ChildPod._refresh` materialises its responder output to a `List`
    on every refresh so a `sync*` generator responder is consumed
    exactly once instead of being walked 3+ times.
  - `SharedPod._enqueue` now logs `catchError`-absorbed errors so
    fire-and-forget callers (`pod.set(x); // no await`) do not lose
    visibility on failed writes.
  - Dead-code purge: ~290 lines of commented-out historical
    `WeakChangeNotifier` implementation removed from
    `weak_change_notifier.dart`.
- **Isolate and web friendliness**:
  - Core pods (`RootPod`, `ChildPod`, `ReducerPod`, `WeakChangeNotifier`,
    `RootPod.fromStream`, `cond`, `set`, `update`, `refresh`) are usable
    in Flutter worker isolates. The H6 fix above means the
    `notifyImmediately: false` path no longer crashes when
    `WidgetsBinding.instance` is unavailable.
  - `SharedPod` now wraps `SharedPreferences.getInstance()` failures
    with an actionable `StateError` that explains the
    `BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken)`
    requirement — the most common worker-isolate misconfiguration. No
    more opaque `MissingPluginException` from the platform channel.
  - Added a *Platform support* matrix to `AGENTS.md` documenting which
    APIs work on native vs web vs worker isolates, plus a worker-isolate
    setup snippet for `SharedPod`.
  - Builders remain UI-only by nature (they are `Widget`s).
  - Web caveat: `WeakReference` / `Finalizer` map to JS `WeakRef` /
    `FinalizationRegistry` — they work but collection timing is
    best-effort. The C5 weak-`_children` fix relies on this; for
    known-dead pods prefer explicit `dispose()` to avoid relying on GC.

## [0.20.0]

- Released @ 5/2026 (UTC)
- Bump cross-package dependencies: `df_safer_dart ^0.18.0`, `df_log ^0.5.0`, `df_debouncer ^0.5.0`, dev `df_safer_dart_lints ^0.4.0`.
- No public API breakage; coordinated major bump with the rest of the state-management stack.

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
