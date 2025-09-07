import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import the AppShell, which is the main screen for authenticated users.
import '../../widgets/app_shell.dart';
// --- UPDATED: Import the new WelcomeScreen ---
import '../welcome/welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to the Firebase authentication state stream.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // --- Best Practice: Handle the connection state ---
        // While waiting for the initial auth state from Firebase, show a loading indicator.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // --- If the user is logged in (snapshot has user data) ---
        if (snapshot.hasData) {
          // The logic for a logged-in user remains the same: show the main app.
          return const AppShell();
        }

        // --- If the user is NOT logged in (snapshot has no data) ---
        // UPDATED: Show the WelcomeScreen as the entry point for new or
        // logged-out users. The WelcomeScreen will then handle navigation
        // to the Login or Sign Up pages.
        return const WelcomeScreen();
      },
    );
  }
}