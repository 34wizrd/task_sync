import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import the AppShell, which is the main screen for authenticated users.
import '../../widgets/app_shell.dart';
// Import the LoginScreen for users who are not logged in.
import 'login/login_screen.dart';

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
          // CORRECT: Show the AppShell.
          // The AppShell provides the full UI with the BottomNavigationBar,
          // and it displays the DashboardScreen as the first tab by default.
          return const AppShell();
        }

        // --- If the user is NOT logged in (snapshot has no data) ---
        return const LoginScreen();
      },
    );
  }
}