import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

// IMPORTANT: This import statement is now valid because the file has been generated.
import 'core/services/sync_service.dart';
import 'features/auth/auth_gate.dart';
import 'features/diary/diary_notifier.dart';
import 'features/diary/diary_screen.dart';
import 'features/food/food_notifier.dart';
import 'firebase_options.dart';

// This is the top-level function that will be called by the background service
@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Native WorkManager task starting: $task"); // For debugging

    // You must initialize all services here, as it's a separate isolate.
    final SyncService syncService = SyncService();

    try {
      await syncService.sync();
      print("Background sync successful");
      return Future.value(true);
    } catch (err) {
      print("Background sync failed: $err");
      // Consider logging the error to a remote service
      return Future.value(false);
    }
  });
}

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the auto-generated project-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // *** INITIALIZE WORKMANAGER AND REGISTER THE TASK ***
  await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true
  );

  Workmanager().registerPeriodicTask(
      "1", // A unique ID for the task
      "backgroundSync", // A unique name for the task
      frequency: Duration(minutes: 15), // The minimum frequency for Android
      constraints: Constraints(
        networkType: NetworkType.connected, // Only run when connected to a network
      )
  );

  // Here you would also initialize WorkManager for background sync

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FoodNotifier()),
        ChangeNotifierProvider(create: (_) => DiaryNotifier()),
      ],
      child: MaterialApp(
        title: 'Diet Tracker',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AuthGate(),
      ),
    );
  }
}