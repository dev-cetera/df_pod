# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About this package

`df_pod` is a Flutter state-management package built around **Pods** — `ValueListenable<T>` containers with monadic safety (`Option`/`Result` from `df_safer_dart`), automatic memory management via weak-reference listeners, and composable derived state. It is published to pub.dev and developed inside the `compledo` monorepo at `packages/df_pod/` (its own git repo, independent of the parent project's `CLAUDE.md`).

`README.md` is the user-facing API tour with runnable examples — read it first when an API is unfamiliar. `state_management_approach.md` is the longer architectural narrative covering how `df_pod` integrates with `df_di` / `df_flutter_services` / `df_safer_dart` (only relevant when working on that integration).

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

- `DisposablePod<T>` (`disposable_pod.dart`) — base class extending `WeakChangeNotifier`, owns `isDisposed` + `onAfterDispose`. The deprecation on `addListener` is intentional; weak refs go through `addStrongRefListener` from `WeakChangeNotifier`.
- `PodNotifier<T>` (`_pod_notifier.dart`) — abstract base over `DisposablePod`, adds `onBeforeDispose`.
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

## Releasing

`pubspec.yaml` `version` and `CHANGELOG.md` are kept in lockstep with git tags (`v0.18.x`). The README badge versions are updated at release time. Recent commits show the cadence is `+<change>` → `ci: bump version to vX.Y.Z`. CI lives in `.github/` (workflows present) — inspect there before changing release tooling.
