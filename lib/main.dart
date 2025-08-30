import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'core/network/connectivity_notifier.dart';
import 'core/network/sync_notifier.dart';
import 'core/services/sync_service.dart';
// Import the services and notifiers needed for the app
import 'features/auth/auth_gate.dart';
import 'features/diary/diary_notifier.dart';
import 'features/diary/diary_service.dart';
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
    final diaryService = DiaryService(); // Following the same repository pattern

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
          create: (context) => DiaryNotifier(
            diaryService: diaryService,
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

/// A helper widget that listens for connectivity changes and triggers a sync.
/// This decouples the sync logic from the UI screens.
class _SyncTrigger extends StatefulWidget {
  final Widget child;
  const _SyncTrigger({required this.child});

  @override
  State<_SyncTrigger> createState() => _SyncTriggerState();
}

// In main.dart

class _SyncTriggerState extends State<_SyncTrigger> {
  // Store the previous connection state to detect when we come back online.
  bool wasOffline = false;

  // ADDED: A flag to ensure the initial check only runs once.
  bool _initialCheckPerformed = false;

  @override
  Widget build(BuildContext context) {
    // Watch the ConnectivityNotifier for changes.
    final connectivity = context.watch<ConnectivityNotifier>();
    final isOnline = connectivity.isOnline;

    // --- NEW LOGIC: ONE-TIME STARTUP SYNC ---
    // After the first build, if we are online, perform an initial sync.
    if (!_initialCheckPerformed && isOnline) {
      _initialCheckPerformed = true; // Mark as performed
      print("App started online. Triggering initial sync check.");
      // Use a post-frame callback to safely call the notifier after the build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<SyncNotifier>().sync();
        }
      });
    }
    // --- END NEW LOGIC ---

    // --- EXISTING LOGIC: RECONNECTION SYNC ---
    // If the device was offline and is now online, trigger a sync.
    if (wasOffline && isOnline) {
      print("Connection restored. Triggering automatic sync...");
      // A post-frame callback is safer here too.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<SyncNotifier>().sync();
        }
      });
    }

    // Update the previous state for the next build cycle.
    wasOffline = !isOnline;

    return widget.child;
  }
}