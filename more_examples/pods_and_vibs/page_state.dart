// View, Interpreter, Builder (VIB) State Management with Pod and GetIt
//
import 'dart:async';

import 'package:df_pod/df_pod.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// [V - VIEW] Create your page widget.
class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Page1InterpretedBuilder(
      builder: (context, interpreter) {
        return Column(
          children: [
            // Build the Pods you get from the iterpreter here.
            PodBuilder(
              pod: interpreter.pUserId,
              builder: (context, userId, child) {
                return Text('UserId: $userId');
              },
            ),
            // It's generally best not to put logic in your Page widget, but
            // if you have to, here's an example:
            PodListBuilder(
              podList: [
                interpreter.pConnectionCount,
                interpreter.pNotificationCount,
              ],
              builder: (context, values, child) {
                final [connectionCount!, notificationCount!] = values.toList();
                final notificationRatio = notificationCount / connectionCount;
                return Text('Notification ratio: $notificationRatio');
              },
            ),
            // This is what you might want to do instead:
            PodBuilder(
              pod: interpreter.pNotificationRatio,
              builder: (context, notificationRatio, child) {
                return Text('Notification ratio: $notificationRatio');
              },
            ),
            OutlinedButton(
              onPressed: () {
                interpreter.userService.login();
              },
              child: const Text('Login'),
            ),
            OutlinedButton(
              onPressed: () {
                interpreter.userService.login();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

// [B - BUILDER] Create an interpreted builder for your page.
class Page1InterpretedBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Page1Interpreter interpreter) builder;
  const Page1InterpretedBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Page1Interpreter(
        getIt<UserService>(),
        getIt<ConnectionService>(),
        getIt<NotificationService>(),
      ),
    );
  }
}

// [I - INTERPRETER] A interpreter maps and reduces global states (Pods) into a local states
// (Pods) for your page. It also specifies which serives are used by the
// current page.
class Page1Interpreter {
  final UserService userService;
  final ConnectionService connectionService;
  final NotificationService notificationService;

  Page1Interpreter(
    this.userService,
    this.connectionService,
    this.notificationService,
  );

  late final pUserId = userService.pUser.map((e) => e!.id);
  late final pNotificationCount = notificationService.pNotifications.map((e) => e!.length);
  late final pConnectionCount = connectionService.pConnections.map((e) => e!.length);
  late final pNotificationRatio =
      pNotificationCount.reduce(pConnectionCount, (a, b) => a.value / b.value);
  late final pPriorityNotifications =
      notificationService.pNotifications.map((e) => e!.where((e) => e.startsWith('priority:')));
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final getIt = GetIt.instance;

// Register services that should persist throughout the duration of the app.
// This can be called in main.dart.
void onAppStart() {
  getIt.registerLazySingleton<UserService>(
    () => UserService(),
    dispose: (e) => e.dispose(),
  );
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(),
    dispose: (e) => e.dispose(),
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Define your services somewhere in your app, e.g. lib/src/services
class UserService {
  final pUser = Pod<User?>(null);
  late final pIsLoggedIn = pUser.map((e) => e != null);

  Future<void> login() async {
    await Future.delayed(
      const Duration(seconds: 1),
      () async {
        await pUser.set(const User('123'));

        // Register logged in services.
        getIt.registerLazySingleton<ConnectionService>(
          () => ConnectionService(),
          dispose: (e) => e.dispose(),
        );
      },
    );
  }

  Future<void> logout() async {
    await Future.delayed(
      const Duration(seconds: 1),
      () => pUser.set(null),
    );
    // Unregister logged in services.
    getIt.unregister<ConnectionService>();
  }

  void dispose() {
    pUser.dispose();
  }
}

class ConnectionService {
  final pConnections = Pod<Iterable<User>>([]);

  void dispose() {
    pConnections.dispose();
  }
}

class NotificationService {
  final pNotifications = Pod<Iterable<String>>([]);

  void dispose() {
    pNotifications.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Define your data models somewhere in your app,  e.g. lib/src/models
class User {
  final String id;
  const User(this.id);
}
