# DF Packages State Management Architecture

A comprehensive guide to implementing reactive, service-oriented state management in Flutter applications using the **df_di**, **df_flutter_services**, **df_safer_dart**, and **df_pod** packages.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Package Responsibilities](#package-responsibilities)
4. [df_safer_dart - Functional Types](#df_safer_dart---functional-types)
5. [df_pod - Reactive State Containers](#df_pod---reactive-state-containers)
6. [df_di - Dependency Injection](#df_di---dependency-injection)
7. [df_flutter_services - Service Lifecycle](#df_flutter_services---service-lifecycle)
8. [Integration Patterns](#integration-patterns)
9. [Complete Implementation Example](#complete-implementation-example)
10. [Best Practices](#best-practices)
11. [Known Issues and Considerations](#known-issues-and-considerations)

---

## Overview

This state management architecture follows these key principles:

| Principle | Description |
|-----------|-------------|
| **Service-Centric** | All application state flows through Services registered in DI containers |
| **Pod-Based Reactivity** | State exposed via `Pod<T>` for reactive UI updates |
| **Hierarchical Containers** | DI containers form parent-child relationships for scoped lifecycles |
| **Type-Safe Resolution** | Dependencies retrieved by type with compile-time checking |
| **Async-First Design** | `Resolvable<T>` unifies sync/async operations |
| **Functional Safety** | `Option<T>` and `Result<T>` eliminate null and exception handling boilerplate |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Flutter Application                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        UI Layer (Widgets)                            │   │
│  │                                                                      │   │
│  │   PodBuilder ←──── Listens to ────→ Pod<T> from Services            │   │
│  └──────────────────────────────┬───────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    DI Containers (df_di)                             │   │
│  │                                                                      │   │
│  │   DI.root                                                           │   │
│  │     └── DI.global ─────────────────────────────────────────────┐    │   │
│  │           │ • Firebase, Auth, PackageInfo                      │    │   │
│  │           │ • RouteController, SessionControlService           │    │   │
│  │           │                                                    │    │   │
│  │           └── DI.session ──────────────────────────────────┐   │    │   │
│  │                 │ • SessionService (created on login)      │   │    │   │
│  │                 │ • UserService, DataStreamServices        │   │    │   │
│  │                 └──────────────────────────────────────────┘   │    │   │
│  │                    (destroyed on logout)                       │    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   Services (df_di + df_flutter_services)             │   │
│  │                                                                      │   │
│  │   Service<TParams>  (df_di)                                         │   │
│  │     │ • Lifecycle: init() → pause() → resume() → dispose()          │   │
│  │     │ • State tracking via ServiceState enum                        │   │
│  │     │                                                               │   │
│  │     ├── StreamService<TData, TParams>  (df_di)                      │   │
│  │     │     │ • Manages stream subscriptions                          │   │
│  │     │     │                                                         │   │
│  │     │     └── DataStreamService<TData, TParams>  (df_di)            │   │
│  │     │           • Contains pData: Pod<Option<Result<TData>>>        │   │
│  │     │           • Auto-updates Pod on stream emissions              │   │
│  │     │                                                               │   │
│  │     └── ObservedService  (df_flutter_services)                      │   │
│  │           • Responds to Flutter app lifecycle events                │   │
│  │           • Auto pause/resume when app backgrounds/foregrounds      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Reactive State (df_pod)                           │   │
│  │                                                                      │   │
│  │   Pod<T> (RootPod)                                                   │   │
│  │     • set(value), update(fn), getValue()                            │   │
│  │     • WeakChangeNotifier for memory-safe listeners                  │   │
│  │                                                                      │   │
│  │   ReducerPod<T>                                                      │   │
│  │     • Derives state from multiple parent Pods                       │   │
│  │     • responder() → returns Pods to listen to                       │   │
│  │     • reducer(values) → computes derived value                      │   │
│  │                                                                      │   │
│  │   ChildPod<TParent, TChild>                                         │   │
│  │     • Immutable derived state from parent Pod                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   Functional Types (df_safer_dart)                   │   │
│  │                                                                      │   │
│  │   Option<T>           Result<T>           Resolvable<T>             │   │
│  │   ├── Some(value)     ├── Ok(value)       ├── Sync(result)          │   │
│  │   └── None()          └── Err(error)      └── Async(future)         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Package Responsibilities

| Package | Purpose | Key Types |
|---------|---------|-----------|
| **df_safer_dart** | Functional programming primitives for safe code | `Option<T>`, `Result<T>`, `Resolvable<T>` |
| **df_pod** | Reactive state containers with listener management | `Pod<T>`, `ReducerPod<T>`, `PodBuilder` |
| **df_di** | Dependency injection + base service classes | `DI`, `Service`, `StreamService`, `DataStreamService` |
| **df_flutter_services** | Flutter-specific services with app lifecycle integration | `ObservedService`, `ObservedDataStreamService` |

Note: The base service classes (`Service`, `StreamService`, `DataStreamService`) are in **df_di**. The **df_flutter_services** package adds Flutter-specific variants that respond to app lifecycle events (pause when backgrounded, resume when foregrounded).

---

## df_safer_dart - Functional Types

### Option<T> - Nullable Value Handling

Represents a value that may or may not exist. Eliminates null pointer exceptions.

```dart
// Creating Options
Option<String> name = Some("Alice");
Option<String> missing = const None();
Option<String> fromNullable = Option.from(nullableValue); // Some or None

// Pattern matching
final greeting = name.fold(
  ifSome: (value) => "Hello, $value!",
  ifNone: () => "Hello, stranger!",
);

// Chaining operations
Option<int> length = name.map((s) => s.length);  // Some(5)
Option<String> upper = name.flatMap((s) => Some(s.toUpperCase()));

// Safe extraction
String? nullable = name.orNull();           // "Alice" or null
String value = name.unwrapOr("default");    // "Alice" or "default"

// Combining Options
Option<(String, int)> combined = Option.combine2(
  Some("Alice"),
  Some(25),
);  // Some(("Alice", 25)) - None if any input is None
```

### Result<T> - Error Handling

Represents success or failure. Replaces try-catch with composable error handling.

```dart
// Creating Results
Result<int> success = Ok(42);
Result<int> failure = Err("Something went wrong");
Result<int> failure2 = Err("API Error", statusCode: 404);

// Pattern matching
final message = success.fold(
  ifOk: (value) => "Got: $value",
  ifErr: (error) => "Error: ${error.error}",
);

// Chaining operations (short-circuits on first Err)
Result<String> result = Ok(42)
    .map((n) => n * 2)
    .flatMap((n) => n > 0 ? Ok("Positive: $n") : Err("Not positive"));

// Error handling
Result<int> handled = failure.mapErr((e) => Err("Wrapped: ${e.error}"));

// Safe extraction
int? nullable = success.orNull();           // 42 or null
int value = success.unwrapOr(0);            // 42 or 0
int unsafe = success.unwrap();              // 42, throws if Err

// Combining Results
Result<(int, String)> combined = Result.combine2(
  Ok(42),
  Ok("hello"),
  onErr: (results) => results.first.transfErr(), // Handle first error
);
```

### Resolvable<T> - Sync/Async Unification

Represents a value that resolves either synchronously or asynchronously. Unifies `T` and `Future<T>`.

```dart
// Creating Resolvables
Resolvable<int> syncValue = Sync.okValue(42);
Resolvable<int> asyncValue = Async.okValue(fetchNumber());
Resolvable<int> fromFunction = Resolvable(() async => await compute());

// The value is FutureOr<Result<T>>
FutureOr<Result<int>> value = syncValue.value;  // Sync: Result directly
FutureOr<Result<int>> value = asyncValue.value; // Async: Future<Result>

// Pattern matching
final result = resolvable.fold(
  ifSync: (sync) => sync.value,
  ifAsync: (async) => async.value,
);

// Chaining (preserves sync/async nature when possible)
Resolvable<String> mapped = syncValue.resultMap((r) => r.map((n) => "$n"));

// Await-like access
int value = await resolvable.unwrap();  // Awaits and unwraps Result
int value = await resolvable.unwrapOr(0);

// Combining Resolvables
Resolvable<List<int>> combined = combineResolvable([
  Sync.okValue(1),
  Async.okValue(Future.value(2)),
]);  // Becomes Async since one input is Async
```

### Type Hierarchy

```
Outcome<T> (sealed)
├── Option<T> (sealed)
│   ├── Some<T> (final) - contains value
│   └── None<T> (final) - empty
├── Result<T> (sealed)
│   ├── Ok<T> (final) - success with value
│   └── Err<T> (final) - error with message, stack trace, optional statusCode
└── Resolvable<T> (sealed)
    ├── Sync<T> (final) - immediate Result<T>
    └── Async<T> (final) - Future<Result<T>>
```

---

## df_pod - Reactive State Containers

### Pod<T> (RootPod)

The fundamental reactive state container with weak reference listener management.

```dart
// Create a Pod
final pCounter = Pod<int>(0);
final pUser = Pod<Option<User>>(const None());

// Update the Pod
pCounter.set(42);                           // Direct set
pCounter.update((current) => current + 1);  // Functional update

// Read current value
int count = pCounter.getValue();

// Listen to changes (uses weak references)
pCounter.addStrongRefListener(
  strongRefListener: () => print("Counter changed: ${pCounter.getValue()}"),
);

// Dispose when done (cleans up all listeners)
pCounter.dispose();
```

### ReducerPod<T>

Derives state from multiple parent Pods. Automatically re-computes when any dependency changes.

```dart
final pFirstName = Pod<String>("John");
final pLastName = Pod<String>("Doe");

// Create a ReducerPod that combines first and last name
final pFullName = ReducerPod<String>(
  responder: () => [
    Some(pFirstName),
    Some(pLastName),
  ],
  reducer: (values) {
    final first = values[0].unwrapOr("");
    final last = values[1].unwrapOr("");
    return Some("$first $last");
  },
);

// pFullName automatically updates when pFirstName or pLastName changes
pFirstName.set("Jane");  // pFullName becomes "Jane Doe"

// Dynamic dependencies - responder can return different Pods each time
final pDynamicReducer = ReducerPod<int>(
  responder: () {
    // Return different pods based on some condition
    if (someCondition) {
      return [Some(podA), Some(podB)];
    }
    return [Some(podC)];
  },
  reducer: (values) => Some(values.fold(0, (sum, v) => sum + (v.orNull() ?? 0))),
);
```

### PodBuilder Widget

Flutter widget that rebuilds when a Pod changes.

```dart
// Basic usage
PodBuilder(
  pod: pCounter,
  builder: (context, snapshot) {
    return Text('Count: ${snapshot.value}');
  },
)

// With Result handling
PodBuilder<Option<Result<User>>>(
  pod: g.pCurrentUser,
  builder: (context, snapshot) {
    final value = snapshot.value;
    return value.fold(
      ifNone: () => CircularProgressIndicator(),
      ifSome: (result) => result.fold(
        ifOk: (user) => Text(user.name),
        ifErr: (error) => Text('Error: ${error.error}'),
      ),
    );
  },
)

// With debouncing (useful for rapid updates)
PodBuilder(
  pod: pSearchQuery,
  debounceDuration: Duration(milliseconds: 300),
  builder: (context, _) => SearchResults(query: pSearchQuery.getValue()),
)

// With caching
PodBuilder(
  key: ValueKey('user-profile'),
  pod: pUser,
  cacheDuration: Duration(minutes: 5),
  builder: (context, _) => UserProfile(user: pUser.getValue()),
)
```

### Weak Reference Listener System

Pods use weak references to prevent memory leaks from forgotten listener cleanup.

```dart
// The listener variable must be stored in a field to prevent GC
late final VoidCallback _listener;

void initState() {
  _listener = () => setState(() {});
  pod.addStrongRefListener(strongRefListener: _listener);
}

void dispose() {
  pod.removeListener(_listener);
  super.dispose();
}

// WARNING: This will be garbage collected immediately!
pod.addStrongRefListener(strongRefListener: () => print("oops"));
```

---

## df_di - Dependency Injection

### Container Hierarchy

```dart
final class DI extends DIBase with /* mixins */ {
  // Root container - base of all containers
  static final root = DI();

  // Application-wide dependencies (child of root)
  static DI get global => root.child(groupEntity: const GlobalEntity());

  // Session-specific dependencies (child of global)
  static DI get session => global.child(groupEntity: const SessionEntity());

  // User-specific dependencies (child of session)
  static DI get user => session.child(groupEntity: const UserEntity());

  // Environment-specific containers
  static DI get dev => root.child(groupEntity: const DevEntity());
  static DI get prod => root.child(groupEntity: const ProdEntity());
  static DI get test => root.child(groupEntity: const TestEntity());
}
```

### Registration

```dart
// Simple registration
DI.global.register<FirebaseAuth>(firebaseAuth);

// Registration with lifecycle callbacks
DI.global.register<MyService>(
  myService,
  onRegister: (service) => service.init(),
  onUnregister: Service.unregister,  // Calls dispose() automatically
);

// Lazy registration (created on first access)
DI.global.registerLazy<ExpensiveService>(
  () => Sync.okValue(ExpensiveService()),
);

// Factory registration (new instance each time)
DI.global.registerFactory<Widget>(
  () => Sync.okValue(MyWidget()),
);

// Register and init service helper
await DI.global.registerAndInitService(MyService()).unwrap();
```

### Retrieval

```dart
// Synchronous retrieval (returns Option)
Option<MyService> service = DI.global.getSyncOrNone<MyService>();

// Direct retrieval (throws if not found)
MyService service = DI.global<MyService>();

// Wait until registered (returns Resolvable)
Resolvable<MyService> service = DI.global.untilSuper<MyService>();

// Await the resolvable
MyService service = await DI.global.untilSuper<MyService>().unwrap();

// Check registration
bool isRegistered = DI.global.isRegistered<MyService>();
```

### Unregistration

```dart
// Unregister single dependency
DI.global.unregister<MyService>();

// Unregister all in container (used during logout)
DI.session.unregisterAll(
  onAfterUnregister: (value) {
    Log.stop('Unregistered $value');
    return null;
  },
);
```

### Parent Traversal

Child containers can access parent dependencies automatically:

```dart
// Register in global
DI.global.register<AuthService>(authService);

// Access from session (traverses to global)
AuthService auth = DI.session<AuthService>();  // Finds it in parent

// Override in child
DI.session.register<AuthService>(mockAuthService);
AuthService auth = DI.session<AuthService>();  // Now returns mock
```

---

## df_flutter_services - Service Lifecycle

### Service States

```dart
enum ServiceState {
  NOT_INITIALIZED,
  RUN_ATTEMPT,     // init() called
  RUN_SUCCESS,     // init() completed successfully
  RUN_ERROR,       // init() failed
  PAUSE_ATTEMPT,   // pause() called
  PAUSE_SUCCESS,   // pause() completed successfully
  PAUSE_ERROR,     // pause() failed
  RESUME_ATTEMPT,  // resume() called
  RESUME_SUCCESS,  // resume() completed successfully
  RESUME_ERROR,    // resume() failed
  DISPOSE_ATTEMPT, // dispose() called
  DISPOSE_SUCCESS, // dispose() completed successfully
  DISPOSE_ERROR,   // dispose() failed
}
```

### Service Base Class

```dart
abstract class Service<TParams extends Object> {
  ServiceState get state;
  Option<TParams> params = const None();

  // Lifecycle methods - all return Resolvable<Unit>
  Resolvable<Unit> init({Option<TParams> params = const None()});
  Resolvable<Unit> pause();
  Resolvable<Unit> resume();
  Resolvable<Unit> dispose();

  // Override these to add lifecycle behavior
  TServiceResolvables<Unit> provideInitListeners(void _) => [];
  TServiceResolvables<Unit> providePauseListeners(void _) => [];
  TServiceResolvables<Unit> provideResumeListeners(void _) => [];
  TServiceResolvables<Unit> provideDisposeListeners(void _) => [];

  // Static helper for DI unregister callback
  static Resolvable<Option> unregister(Result<Service> serviceResult) {
    if (serviceResult.isErr()) {
      return const Sync.unsafe(Ok(None()));
    }
    return serviceResult.unwrap().dispose().map((_) => const None());
  }
}

typedef TServiceResolvables<T> = List<Resolvable Function(T data)>;
```

### StreamService

Service that manages a data stream with automatic lifecycle integration.

```dart
abstract class StreamService<TData extends Object, TParams extends Object>
    extends Service<TParams> {

  // Access initial data once available
  Option<Resolvable<TData>> get initialData;

  // Access the broadcast stream
  Option<Stream<Result<TData>>> get stream;

  // Override to provide the data stream
  Stream<Result<TData>> provideInputStream();

  // Override to react to stream emissions
  TServiceResolvables<Result<TData>> provideOnPushToStreamListeners() => [];
}
```

### DataStreamService

StreamService with automatic Pod updates.

```dart
abstract class DataStreamService<TData extends Object, TParams extends Object>
    extends StreamService<TData, TParams> {

  // Pod automatically updated when stream emits
  final pData = Pod<Option<Result<TData>>>(const None());

  @override
  TServiceResolvables<Result<TData>> provideOnPushToStreamListeners() {
    return [
      (data) {
        pData.set(Some(data));
        return syncUnit();
      },
    ];
  }
}
```

### Example: Custom DataStreamService

```dart
final class UserService extends DataStreamService<ModelUser, None> {
  final String userId;

  UserService({required this.userId});

  @override
  Stream<Result<ModelUser>> provideInputStream() {
    return Stream.fromFuture(
      DI.session.untilSuper<DatabaseService>().toAsync().unwrap(),
    ).asyncExpand(
      (db) => db.streamModel<ModelUser>(
        Schema.usersRef(userId: userId),
        ModelUser.fromJson,
      ),
    );
  }

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) {
    return [
      ...super.provideDisposeListeners(null),
      (_) {
        // Custom cleanup
        Log.info('UserService disposed');
        return syncUnit();
      },
    ];
  }
}
```

### SessionControlService

Abstract base for handling login/logout events.

```dart
abstract class SessionControlService extends Service {
  var _didAlreadyStartApp = false;

  @override
  TServiceResolvables<Unit> provideInitListeners(void _) {
    return [_initListener];
  }

  Resolvable<Unit> _initListener(void _) {
    return Async(() async {
      final auth = await DI.global.untilSuper<AuthServiceInterface>().unwrap();
      auth
        ..onLogin = (authUser) async {
          if (_didAlreadyStartApp) {
            await onLogin(authUser);
          } else {
            await onCachedLogin(authUser);
          }
          _didAlreadyStartApp = true;
        }
        ..onLogout = () async {
          if (_didAlreadyStartApp) {
            await onLogout();
          } else {
            await onCachedLogout();
          }
          _didAlreadyStartApp = true;
        };
      auth.checkAuthState();
      return Unit();
    });
  }

  // Override these in your implementation
  Future<void> onCachedLogin(ModelAuthUser authUser);
  Future<void> onLogin(ModelAuthUser authUser);
  Future<void> onCachedLogout();
  Future<void> onLogout();
}
```

### ObservedService

Service that responds to Flutter app lifecycle events.

```dart
abstract class ObservedService extends WidgetsBindingObserver
    with ServiceMixin, HandleServiceLifecycleStateMixin {

  ObservedService() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) {
    return [
      (_) {
        WidgetsBinding.instance.removeObserver(this);
        return syncUnit();
      },
    ];
  }
}

// Mixin to handle app lifecycle states
mixin HandleServiceLifecycleStateMixin {
  // Override to enable handling
  bool handlePausedState() => false;
  bool handleResumedState() => false;
  bool handleHiddenState() => false;
  bool handleInactiveState() => false;
  bool handleDetachedState() => false;
}
```

---

## Integration Patterns

### Pattern 1: Global Accessor (G Singleton)

Create a singleton for clean access to reactive state:

```dart
G get g => G.instance;

final class G {
  const G._();
  static const instance = G._();

  // Reactive accessor - returns Pod wrapped in Resolvable
  Resolvable<Pod<Option<Result<ModelUser>>>> get pCurrentUser {
    return DI.session.untilSuper<UserService>().map((e) => e.pData);
  }

  // Snapshot accessor - returns current value synchronously
  Option<Result<ModelUser>> get currentUserSnapshot {
    return DI.session
        .getSyncOrNone<UserService>()
        .map((e) => e.pData.getValue())
        .flatten();
  }

  // Derived state with ReducerPod
  Resolvable<Pod<List<Friend>>> get pFriends {
    return DI.session.untilSuper<FriendService>().map((e) {
      return ReducerPod(
        responder: () => [Some(e.pFriendIds), Some(e.pFriendData)],
        reducer: (values) => Some(computeFriendsList(values)),
      );
    });
  }
}
```

### Pattern 2: Service Registration Order

Register services in dependency order using `untilSuper`:

```dart
Future<void> initSession(ModelAuthUser authUser) async {
  // 1. Register base services first
  await DI.session.registerAndInitService(
    UserService(userId: authUser.id),
  ).unwrap();

  // 2. Services that depend on UserService
  final user = await DI.session.untilSuper<UserService>().unwrap();
  final userData = await user.initialData.unwrap().value;

  await DI.session.registerAndInitService(
    ProfileService(profileId: userData.unwrap().profileId),
  ).unwrap();

  // 3. Services that depend on ProfileService
  await DI.session.registerAndInitService(
    FriendService(),
  ).unwrap();
}
```

### Pattern 3: Screen Controller with Pods

Screen controllers manage local UI state using Pods:

```dart
final class LoginScreenController extends ScreenController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pPasswordVisible = Pod<bool>(false);
  final pIsLoading = Pod<bool>(false);
  final formKey = GlobalKey<FormState>();

  void togglePasswordVisibility() {
    pPasswordVisible.update((visible) => !visible);
  }

  Future<void> login({required VoidCallback onSuccess}) async {
    if (!formKey.currentState!.validate()) return;

    pIsLoading.set(true);
    try {
      final auth = DI.global<AuthServiceInterface>();
      await auth.logInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      ).unwrap();
      onSuccess();
    } finally {
      pIsLoading.set(false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    pPasswordVisible.dispose();
    pIsLoading.dispose();
    super.dispose();
  }
}
```

### Pattern 4: Combining Multiple Services

Use ReducerPod to combine data from multiple services:

```dart
Resolvable<Pod<DashboardData>> get pDashboardData {
  return DI.session.untilSuper<UserService>().then((userService) {
    return DI.session.untilSuper<StatsService>().map((statsService) {
      return ReducerPod(
        responder: () => [
          Some(userService.pData),
          Some(statsService.pStats),
        ],
        reducer: (values) {
          final user = values[0].flatMap((v) => v as Option<Result<User>>);
          final stats = values[1].flatMap((v) => v as Option<Result<Stats>>);

          if (user.isNone() || stats.isNone()) return const None();

          final userResult = user.unwrap();
          final statsResult = stats.unwrap();

          if (userResult.isErr()) return Some(Err(userResult.err().unwrap()));
          if (statsResult.isErr()) return Some(Err(statsResult.err().unwrap()));

          return Some(Ok(DashboardData(
            user: userResult.unwrap(),
            stats: statsResult.unwrap(),
          )));
        },
      );
    });
  });
}
```

---

## Complete Implementation Example

### 1. App Initialization

```dart
void main() async {
  runApp(MainWidget(initApp: initApp));
}

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 1: Core infrastructure
  final firebaseApp = await Firebase.initializeApp();
  DI.global
    ..register(FirebaseAuth.instanceFor(app: firebaseApp))
    ..register(FirebaseFirestore.instanceFor(app: firebaseApp));

  // Phase 2: Auth broker
  DI.global.register<AuthServiceInterface>(
    FirebaseAuthBroker(firebaseAuth: DI.global<FirebaseAuth>()),
  );

  // Phase 3: Session control (triggers login/logout flow)
  await DI.global.registerAndInitService(
    LoginLogoutControlService(),
  ).unwrap();
}
```

### 2. LoginLogoutControlService

```dart
final class LoginLogoutControlService extends SessionControlService {
  @override
  Future<void> onCachedLogin(ModelAuthUser authUser) async {
    Log.info('Cached login detected');
    await _initSession(authUser);
    DI.global<RouteController>().push(HomeScreenRouteState());
  }

  @override
  Future<void> onLogin(ModelAuthUser authUser) async {
    Log.info('Fresh login detected');
    await _initSession(authUser);
    DI.global<RouteController>().resetState();
    DI.global<RouteController>().push(HomeScreenRouteState());
  }

  @override
  Future<void> onCachedLogout() async {
    Log.info('Cached logout detected');
    DI.global<RouteController>().push(WelcomeScreenRouteState());
  }

  @override
  Future<void> onLogout() async {
    Log.info('Fresh logout detected');
    await _cleanupSession();
    DI.global<RouteController>().resetState();
    DI.global<RouteController>().push(WelcomeScreenRouteState());
  }

  Future<void> _initSession(ModelAuthUser authUser) async {
    final sessionService = SessionService();
    await sessionService.init(params: Some(authUser)).value;
    DI.global.register<SessionService>(
      sessionService,
      onUnregister: Service.unregister,
    );
  }

  Future<void> _cleanupSession() async {
    if (DI.global.isRegistered<SessionService>()) {
      DI.global.unregister<SessionService>();
    }
    DI.session.unregisterAll(
      onAfterUnregister: (value) {
        Log.stop('Unregistered: $value');
        return null;
      },
    );
  }
}
```

### 3. SessionService

```dart
final class SessionService extends Service<ModelAuthUser> {
  @override
  TServiceResolvables<Unit> provideInitListeners(void _) {
    return [_initListener];
  }

  Resolvable<Unit> _initListener(void _) {
    return Async(() async {
      // Clear any stale session data
      final registry = DI.session.registry;
      if (!registry.state.isEmpty) {
        Log.warn('Previous session not cleaned up, clearing...');
        registry.clear();
      }

      final userId = params.unwrap().id!;

      // Register UserService and wait for initial data
      final userService = UserService(userId: userId);
      await userService.init().value;
      await userService.initialData.unwrap().value;
      DI.session.register(userService, onUnregister: Service.unregister);

      // Register ProfileService
      final user = userService.pData.getValue().unwrap().unwrap();
      DI.session.register(
        ProfileService(profileId: user.profileId),
        onRegister: (e) => e.init(),
        onUnregister: Service.unregister,
      );

      return Unit();
    });
  }

  @override
  TServiceResolvables<Unit> provideDisposeListeners(void _) {
    return [(_) => _logout()];
  }

  Async<Unit> _logout() {
    return Async(() async {
      DI.session.unregisterAll(
        onAfterUnregister: (value) {
          Log.stop('Session cleanup: $value');
          return null;
        },
      );
      await DI.global<AuthServiceInterface>().logOut(cleanup: null).value;
      return Unit();
    });
  }
}
```

### 4. Using in UI

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResolvablePodBuilder(
        resolvablePod: g.pCurrentUser,
        builder: (context, pod) {
          return PodBuilder(
            pod: pod,
            builder: (context, _) {
              final value = pod.getValue();
              return value.fold(
                ifNone: () => Center(child: CircularProgressIndicator()),
                ifSome: (result) => result.fold(
                  ifOk: (user) => UserProfile(user: user),
                  ifErr: (error) => ErrorDisplay(error: error),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## Best Practices

### 1. Always Provide onUnregister for Services

```dart
DI.session.register(
  myService,
  onRegister: (e) => e.init(),
  onUnregister: Service.unregister,  // Ensures dispose() is called
);
```

### 2. Dispose Pods in Controllers

```dart
@override
void dispose() {
  pLocalState.dispose();
  pAnotherState.dispose();
  super.dispose();
}
```

### 3. Use PodBuilder for Reactive UI

```dart
// CORRECT - rebuilds when pod changes
PodBuilder(
  pod: pValue,
  builder: (context, _) => Text('${pValue.getValue()}'),
)

// WRONG - won't update
Text('${pValue.getValue()}')
```

### 4. Clean Session State on Logout

```dart
DI.session.unregisterAll(
  onAfterUnregister: (value) {
    Log.stop('Unregistered: $value');
    return null;
  },
);
```

### 5. Use Resolvable for Async Dependencies

```dart
// Wait for dependency before using
final service = await DI.session.untilSuper<MyService>().unwrap();

// Or chain with then()
DI.session.untilSuper<MyService>().then((service) {
  return service.doSomething();
});
```

### 6. Keep Store Listeners as Strong References

```dart
class MyWidget extends StatefulWidget {
  // ...
}

class _MyWidgetState extends State<MyWidget> {
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () => setState(() {});
    myPod.addStrongRefListener(strongRefListener: _listener);
  }

  @override
  void dispose() {
    myPod.removeListener(_listener);
    super.dispose();
  }
}
```

### 7. Use Snapshots for Synchronous Access

```dart
// When you need current value without waiting
Option<Result<User>> user = g.currentUserSnapshot;
if (user.isSome() && user.unwrap().isOk()) {
  final userName = user.unwrap().unwrap().name;
}
```

---

## Known Issues and Considerations

### df_flutter_services

1. **ObservedService Observer Removal**: Uses assertion for validation which is disabled in release builds. Consider explicit error handling for critical cleanup.

2. **No Timeout on Lifecycle Operations**: Async lifecycle listeners can hang indefinitely. Consider adding timeouts for production use.

3. **StreamService InitDataCompleter**: If disposed before any data arrives, awaiting `initialData` will hang. Design services to handle this case.

### df_pod

1. **ReducerPod Listener Cleanup**: If `reducer()` throws an exception, listeners may not be properly cleaned up. Wrap reducer logic in try-catch for safety.

2. **Weak Reference Listener GC**: Anonymous callbacks passed to `addStrongRefListener` will be garbage collected immediately. Always store callback references in fields.

3. **ChildPod Dirty Flag**: In rare edge cases with async operations, rapid updates could bypass the dirty flag debouncing.

### df_di

1. **Race Condition in Child Container**: Between checking `isChildRegistered()` and `registerChild()`, another operation could create the child. Low impact in single-threaded Dart.

2. **Completer Cleanup**: `ReservedSafeCompleter` instances for `until()` calls persist until resolved. Long-running apps should consider cleanup strategies.

### General

1. **UNSAFE Blocks**: Code marked with `UNSAFE:` comments uses unwrap operations that can throw if preconditions aren't met. Ensure proper validation before these sections.

2. **Memory Management**: Complex ReducerPod dependency graphs should be carefully designed to avoid circular references that delay garbage collection.

---

## Summary

This architecture provides:

- **Clear separation** between global and session state via DI container hierarchy
- **Reactive updates** through Pod-based state containers with weak reference listener management
- **Type-safe** dependency injection with compile-time checking
- **Proper lifecycle** management for all services (init, pause, resume, dispose)
- **Unified async/sync** handling via Resolvable
- **Functional error handling** with Option and Result types eliminating null checks and try-catch

The key insight is that **all application state flows through services registered in DI containers**, and **Pods provide the reactive bridge to the UI**. The functional types from df_safer_dart ensure safe data handling throughout the pipeline.
