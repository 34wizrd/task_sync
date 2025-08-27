import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../diary/diary_screen.dart';
import 'login_screen.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has no data, it means we are still waiting
        if (!snapshot.hasData) {
          return LoginScreen();
        }

        // If we have data, the user is logged in, show the main app
        return DailyScreen();
      },
    );
  }
}