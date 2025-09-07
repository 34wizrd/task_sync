import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:task_sync/features/auth/sign_up/signup_screen.dart';

import '../auth/login/login_screen.dart';
import '../onboarding/onboarding_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- COLOR PALETTE from the design ---
    const primaryGreen = Color(0xFF30D575);
    const darkBg = Color(0xFF1A1A1A);
    const secondaryDark = Color(0xFF2C2C2E);
    const illustrationBg = Color(0xFF4A9D9E);
    const lightText = Color(0xFFBDBDBD);

    // Get screen dimensions for responsive layout
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: darkBg,
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Top Section with Illustration ---
            Container(
              height: screenHeight * 0.5, // Adjust proportion as needed
              color: illustrationBg,
              child: Center(
                child: Image.asset(
                  'assets/welcome_illustration.png', // Replace with your asset path
                  fit: BoxFit.contain,
                  // Placeholder for when the image is not found
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.food_bank_outlined,
                      size: 150,
                      color: Colors.white54,
                    );
                  },
                ),
              ),
            ),

            // --- Bottom Section with Content ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Spacer(flex: 2),
                    // --- Headline Text ---
                    const Text(
                      'Track Your Nutrition,\nAchieve Your Goals',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Description Text ---
                    Text(
                      'Log your meals, monitor your macros, and stay on top of your health journey with our easy-to-use app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: lightText,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(flex: 3),

                    // --- Action Buttons ---
                    _buildButton(
                      text: 'Sign Up',
                      isPrimary: true,
                      backgroundColor: primaryGreen,
                      textColor: darkBg,
                      onPressed: () {
                        // TODO: Navigate to Sign Up screen
                        // --- Navigate to the LoginScreen ---
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const OnboardingFlowWrapper(), // CORRECT: This builds the provider first.
                          ),
                        );
                        print('Sign Up button tapped');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      text: 'Log In',
                      isPrimary: false,
                      backgroundColor: secondaryDark,
                      textColor: Colors.white,
                      onPressed: () {
                        // TODO: Navigate to Log In screen
                        // --- Navigate to the LoginScreen ---
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                        print('Log In button tapped');
                      },
                    ),
                    const Spacer(flex: 2),

                    // --- Legal Text ---
                    _buildLegalText(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A helper method to build styled buttons consistently.
  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0, // Flat design
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// A helper method to build the legal text with clickable links.
  Widget _buildLegalText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(color: Colors.grey, fontSize: 12),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Handle Terms of Service link tap
                  print('Terms of Service tapped');
                },
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Handle Privacy Policy link tap
                  print('Privacy Policy tapped');
                },
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}