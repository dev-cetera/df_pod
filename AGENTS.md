# CLAUDE.md — df_pod

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role in the state-management stack

`df_pod` is the **reactive-containers layer** of a four-package Flutter state-management stack. The full stack lives next to this package in `/Users/robmllze/Projects/flutter/dev_cetera/df_packages/packages/`:

| Package | Path | Role |
| --- | --- | --- |
| `df_safer_dart` | `../df_safer_dart` | Foundation: `Option<T>`, `Result<T>`, `Resolvable<T>`, `Outcome<T>`, `UNSAFE`, `SafeCompleter`, `TaskSequencer` |
| `df_di` | `../df_di` | DI container hierarchy (`DI.root`/`global`/`session`/`user`), `Service`/`ServiceMixin`, `StreamServiceMixin`, `PollingStreamServiceMixin` |
| `df_pod` *(this)* | `.` | `Pod<T>` / `RootPod<T>`, `ChildPod`, `ReducerPod`, `SharedPod`, `WeakChangeNotifier`, `PodBuilder` / `PodListBuilder` / `PodCollectionBuilder` / `PollingPodBuilder` |
| `df_flutter_services` | `../df_flutter_services` | `ObservedService`, `ObservedDataStreamService`, `HandleServiceLifecycleStateMixin` (Flutter app-lifecycle glue) |

`pubspec_overrides.yaml` pins all siblings to local paths. Edits take effect without publishing.

### State-management guide

For the cross-package architecture (how Pods live on services, how DI scopes hold them, how Flutter lifecycle integrates, the `G` singleton pattern, login/logout flow, UI patterns, common pitfalls) read **`doc/state_management_approach.md`**. The same file is mirrored in every package of the stack (`df_safer_dart`, `df_di`, `df_pod`, `df_flutter_services`) — keep the copies in sync when editing.

## About this package

`df_pod` is built around **Pods** — `ValueListenable<T>` containers with monadic safety (`Option`/`Result` from `df_safer_dart`), automatic memory management via weak-reference listeners, and composable derived state. It is published to pub.dev and developed inside the `compledo` monorepo at `packages/df_pod/` (its own git repo, independent of the parent project's `CLAUDE.md`).

`README.md` is the user-facing API tour with runnable examples — read it first when an API is unfamiliar.

## Common commands

This is a pure Flutter package — no app to run, no codegen, no scripts. Everything is `flutter`/`dart` against `pubspec.yaml`.

```sh
# Install deps
flutter pub get

# Static analysis (custom_lint runs df_safer_dart_lints)
dart analyze
dart run custom_lint   # runs the custom_lint plugin defined in analysis_options.yaml

# Format
dart format .

# Test (uses flutter_test, not dart test — these widgets/tests bind WidgetsBinding)
flutter test

# Run a single test file
flutter test test/pod_core_test.dart

# Run a single test by name
flutter test test/pod_core_test.dart --plain-name "set updates value"

# Run the example app
cd example && flutter run
```

## Architecture

### Public surface

`lib/df_pod.dart` re-exports `lib/src/_src.g.dart`, which is a generated barrel. **Do not edit `_src.g.dart` by hand** — regenerate it with `df_generate_dart_indexes` after adding/removing files in `lib/src/`.

Internal files import via `/_common.dart` (the absolute path of `lib/_common.dart`), which re-exports the generated barrel plus the standard ambient deps (`flutter/foundation`, `flutter/widgets`, `df_safer_dart`, `df_log`, `df_debouncer`, `meta`). Use this single import in new internal files rather than enumerating each dependency.

### Pod hierarchy (`lib/src/pods/`)

The pod types are interlocking and live as `part`/`part of` files under one library — `lib/src/pods/core/core.dart` is the part-of root. Edit any of these and you are editing the same library:

- `DisposablePod<T>` (`disposable_pod.dart`) — base class extending `WeakChangeNotifier`, owns `onAfterDispose`. The deprecation on `addListener` is intentional; weak refs go through `addStrongRefListener` from `WeakChangeNotifier`. Note: the single source of truth for "is disposed?" is `WeakChangeNotifier.isDisposed`; do not introduce a duplicate flag.
- `PodNotifier<T>` (`_pod_notifier.dart`) — abstract base over `DisposablePod`, adds the abstract `value` field and `getValue()` accessor. Also declares the `TOnBeforeDispose<T>` typedef (currently unused — historical hook).
- `GenericPodMixin<T>` (`_generic_pod_mixin.dart`) — the mixin that adds `getValue`, `.map(...)`, `.reduce(...)` to anything that is both a `PodNotifier` and a `ValueListenable`. `typedef GenericPod<T> = GenericPodMixin<T>`.
- `RootPod<T>` (`_root_pod.dart`) — the mutable root. **`Pod<T>` is a typedef for `RootPod<T>`** — that's why user code writes `Pod(0)`. Has `set`, `update`, `refresh`, plus a `RootPod.fromStream` constructor that auto-cancels the subscription on dispose.
- `ChildPod<TParent, TChild>` (`_child_pod.dart`) — read-only derived pod from `.map(...)`.
- `ReducerPod<T>` (`_reducer_pod.dart` + `_reducers/`) — combines multiple parents. Variadic-arity reducers live in `_reducers/pod_reducer_1.dart` … `pod_reducer_7.dart` plus `multiple_pod_reducer.dart` for arbitrary lists.
- `SharedPod<A, B>` (`_shared_pod.dart`) — `RootPod` whose value is mirrored to `SharedPreferences`. Type-specific helpers in `more_shared_pods/` (`SharedBoolPod`, `SharedIntPod`, `SharedStringPod`, `SharedStringListPod`, `SharedDoublePod`, `SharedEnumPod`, `SharedJsonPod`).
- `ProtectedPod` / `SharedProtectedPod` (`protected_pod.dart`, `shared_protected_pod.dart`) — variants whose mutators are gated by `protected_pod_mixin.dart` (`lib/src/_mixins/`). The `invalid_use_of_protected_member: error` lint rule (in `analysis_options.yaml`) is what makes these enforceable at the API boundary — keep it on.

### Builders (`lib/src/builders/`)

- `PodBuilder<T>` — single pod, supports `Future<Pod<T>>` for async pods (loading/success/error via `Option<Result<T>>`), with `debounceDuration` and `cacheDuration` (cache via `PodBuilderCacheManager` in `builder_utils.dart`, keyed by widget `Key`).
- `PodListBuilder` — fixed list of pods, rebuilds when any fires.
- `PodCollectionBuilder` — added in 0.18.16. Source pod + a selector that returns a *dynamic* inner list of listenables. Auto-attaches/detaches as the inner list changes by identity. Uses `addStrongRefListener` for `WeakChangeNotifier` pods, `addListener` for plain `Listenable`s. Replaces hand-rolled `addStrongRefListener` + bookkeeping patterns.
- `PollingPodBuilder` — repeatedly evaluates a builder on a timer.

### Memory model (`lib/src/utils/weak_change_notifier.dart`)

This is the linchpin. `WeakChangeNotifier` stores listeners as `WeakReference`s — when a `PodBuilder` widget is unmounted, its listener is GC'd without manual `removeListener`. `addStrongRefListener` is the escape hatch for non-UI listeners that need a stable lifetime; it requires the caller to hold the function in a named variable (anonymous closures get GC'd immediately). This is why the `prefer_function_declarations_over_variables: false` lint rule is recommended in user `analysis_options.yaml`. Auto-disposal of `ChildPod`/`ReducerPod` when the parent is disposed is wired through `_pod_finalizer_wrapper.dart`.

### What goes where

- New pod type → `lib/src/pods/`, decide whether it's part of `core/core.dart`'s library (use `part of`) or standalone (own imports). Then regenerate `_src.g.dart`.
- New builder widget → `lib/src/builders/`, then regenerate `_src.g.dart`.
- New utility → `lib/src/utils/`, then regenerate `_src.g.dart`.
- Public API addition → also bump `version` in `pubspec.yaml` and add a `CHANGELOG.md` entry.

## Conventions

- **Pod variable prefix**: `p` (e.g. `pCounter`, `pUser`). User-facing convention from the README; follow it in examples and tests.
- **Internal imports use `/_common.dart`** (absolute) rather than per-file imports. The lint enforces `prefer_relative_imports: error` for everything else.
- **Strict analyzer**: `strict-casts`, `strict-inference`, `strict-raw-types` are all on. `analysis_options.yaml` upgrades many lints to errors (`always_declare_return_types`, `flutter_style_todos`, `invalid_use_of_protected_member`, `missing_return`, `prefer_relative_imports`, `unrelated_type_equality_checks`). Don't suppress — fix.
- **`@protected` matters**: protected members in this package rely on `invalid_use_of_protected_member: error` to prevent misuse. When adding mutator APIs that should only be called from within the pod machinery, mark them `@protected`.
- **Logging via `df_log`** (`Log.alert`, `Log.err`) — never `print` / `debugPrint`. Already enforced by convention in `disposable_pod.dart`.
- **Tests**: `flutter_test` only. Group by feature; the existing files (`pod_core_test.dart`, `pod_builder_test.dart`, `pod_collection_builder_test.dart`) are the templates.

## Platform support

The package targets **Flutter** (its `pubspec.yaml` depends on the
Flutter SDK and `lib/_common.dart` re-exports `dart:ui`,
`package:flutter/foundation`, `package:flutter/widgets`). It cannot be
used in a non-Flutter pure-Dart program. Within a Flutter app the
matrix is:

| Surface | Flutter native | Flutter web | Worker isolate |
| --- | --- | --- | --- |
| Core pods (`RootPod`, `ChildPod`, `ReducerPod`, `WeakChangeNotifier`, `cond`, `set`, `update`, `refresh`, `RootPod.fromStream`) | ✅ | ✅ | ✅ |
| `_set(notifyImmediately: false)` | ✅ via `WidgetsBinding.addPostFrameCallback` | ✅ same | ✅ falls back to `scheduleMicrotask` when no binding (v0.21.0 H6 fix) |
| `SharedPod` / `SharedProtectedPod` and the typed helpers | ✅ | ✅ via `shared_preferences_web` (`localStorage`) | ⚠️ requires `BackgroundIsolateBinaryMessenger.ensureInitialized` in the worker (see below) |
| Builders (`PodBuilder`, `PodListBuilder`, `PodCollectionBuilder`, `PollingPodBuilder`) | ✅ | ✅ | ❌ UI-only by nature |
| `WeakReference` / `Finalizer` (used for listener bookkeeping and `_children`) | ✅ deterministic timing | ⚠️ best-effort (maps to `WeakRef` / `FinalizationRegistry`) — collection can be delayed or skipped; prefer explicit `dispose()` for known-dead pods | ✅ |

### Worker isolate setup (for `SharedPod`)

Plain pods need no setup. `SharedPod` uses a Flutter platform channel,
so a worker isolate that touches storage must initialise the binary
messenger first. If you forget, `SharedPod` now fails loudly with a
fix-it hint that points to this exact section (see `_getPrefs` in
`_shared_pod.dart`).

```dart
// Root isolate, before spawning the worker:
final rootToken = RootIsolateToken.instance!;
await Isolate.spawn(workerMain, rootToken);

// Worker entry point:
void workerMain(RootIsolateToken token) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  // Safe to use SharedPod now.
  final pTheme = await SharedStringPodCreator.create('theme');
}
```

Builders cannot run in workers (they're `Widget`s — the framework
itself only runs on the UI isolate). Move the build logic to the UI
isolate and have the worker mutate pods that the UI isolate observes —
but note that pods themselves are not shared across isolates either,
so this means streaming state changes over a `SendPort`, not handing
the pod object across.

## Releasing

`pubspec.yaml` `version` and `CHANGELOG.md` are kept in lockstep with git tags (`v0.18.x`). The README badge versions are updated at release time. Recent commits show the cadence is `+<change>` → `ci: bump version to vX.Y.Z`. CI lives in `.github/` (workflows present) — inspect there before changing release tooling.
