import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'core/network/connectivity_notifier.dart';
import 'core/network/sync_notifier.dart';
import 'core/services/sync_service.dart';
// Import the services and notifiers needed for the app
import 'features/auth/auth_gate.dart';
import 'features/diary/dashboard_notifier.dart';
import 'features/diary/dashboard_service.dart';
import 'features/food/food_notifier.dart';
import 'features/food/food_service.dart';
import 'firebase_options.dart';

/// A top-level function that acts as the entry point for the background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Re-initialize services in the new isolate.
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    print("Native WorkManager task starting: $task");
    final syncService = SyncService();

    try {
      await syncService.sync();
      print("Background sync successful");
      return Future.value(true);
    } catch (err) {
      print("Background sync failed: $err");
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  // Ensure Flutter is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for the main app.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize and register the background sync task.
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerPeriodicTask(
    'backgroundSyncTask', // A unique name for the task
    'backgroundSync',     // The task name passed to the dispatcher
    frequency: const Duration(minutes: 15), // Minimum frequency
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- DEPENDENCY INJECTION SETUP ---
    // Instantiate all services at the top level so they are singletons.
    final syncService = SyncService();
    final foodService = FoodService();
    final dashboardService = DashboardService(); // Following the same repository pattern

    return MultiProvider(
      providers: [
        // --- Foundational Notifiers (App-wide) ---
        ChangeNotifierProvider(create: (_) => ConnectivityNotifier()..init()),
        ChangeNotifierProvider(
          create: (_) => SyncNotifier()..setHandler(syncService.sync),
        ),

        // --- Feature Notifiers with Dependencies Injected ---
        ChangeNotifierProvider(
          create: (context) => FoodNotifier(
            foodService: foodService,
            // Use context.read to get an already-provided notifier.
            syncNotifier: context.read<SyncNotifier>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardNotifier(
            dashboardService: dashboardService,
            // Also depends on SyncNotifier to update pending counts.
            syncNotifier: context.read<SyncNotifier>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Diet Tracker',
        theme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
        ),
        // The AuthGate is wrapped with a _SyncTrigger to handle syncing on reconnect.
        home: const _SyncTrigger(
          child: AuthGate(),
        ),
      ),
    );
  }
}

class _SyncTrigger extends StatefulWidget {
  final Widget child;
  const _SyncTrigger({required this.child});

  @override
  State<_SyncTrigger> createState() => _SyncTriggerState();
}

class _SyncTriggerState extends State<_SyncTrigger> {
  bool wasOffline = true; // Start as true to trigger initial sync
  bool _initialCheckPerformed = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityNotifier>().isOnline;
    if (!_initialCheckPerformed) {
      wasOffline = !isOnline;
      _initialCheckPerformed = true;
    }

    if (wasOffline && isOnline) {
      print("Connection restored or app started online. Triggering sync...");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<SyncNotifier>().sync();
      });
    }

    wasOffline = !isOnline;
    return widget.child;
  }
}