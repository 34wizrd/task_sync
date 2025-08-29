import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import 'signup_notifier.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFFD6A02);
    const brandDark = Color(0xFFE95A00);

    return ChangeNotifierProvider(
      create: (_) => SignUpNotifier(AuthService()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF3E9), Color(0xFFFFF9F5)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Consumer<SignUpNotifier>(
                    builder: (context, vm, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Color(0xFFFFF0E6)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.local_fire_department, size: 32, color: brand),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "CalTrack",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Start tracking calories, meals, and macros.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.65)),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFFFE1CC)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'you@example.com',
                                      prefixIcon: const Icon(Icons.email_outlined),
                                      filled: true,
                                      fillColor: const Color(0xFFFFF9F5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Email is required';
                                      final r = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$');
                                      if (!r.hasMatch(v.trim())) return 'Enter a valid email';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Password
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: vm.obscure,
                                    autofillHints: const [AutofillHints.newPassword],
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: '••••••••',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        onPressed: vm.toggleObscure,
                                        icon: Icon(vm.obscure ? Icons.visibility_off : Icons.visibility),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFFFF9F5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Password is required';
                                      if (v.length < 6) return 'Use at least 6 characters';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Confirm password
                                  TextFormField(
                                    controller: _confirmController,
                                    obscureText: vm.obscure,
                                    autofillHints: const [AutofillHints.newPassword],
                                    decoration: InputDecoration(
                                      labelText: 'Confirm password',
                                      hintText: '••••••••',
                                      prefixIcon: const Icon(Icons.lock_person_outlined),
                                      suffixIcon: IconButton(
                                        onPressed: vm.toggleObscure,
                                        icon: Icon(vm.obscure ? Icons.visibility_off : Icons.visibility),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFFFF9F5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Please confirm your password';
                                      if (v != _passwordController.text) return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 6),

                                  // Terms
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: vm.acceptedTerms,
                                        onChanged: vm.isLoading ? null : (val) => vm.setAcceptedTerms(val ?? false),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        activeColor: brand,
                                      ),
                                      Flexible(
                                        child: Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            const Text('I agree to the '),
                                            GestureDetector(
                                              onTap: () {
                                                // TODO: open terms
                                              },
                                              child: const Text(
                                                'Terms & Privacy',
                                                style: TextStyle(
                                                  decoration: TextDecoration.underline,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Error banner
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: vm.error == null
                                        ? const SizedBox.shrink()
                                        : Padding(
                                      key: const ValueKey('err'),
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              vm.error!,
                                              style: const TextStyle(color: Colors.red, height: 1.2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Create account
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: brand,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      onPressed: vm.isLoading
                                          ? null
                                          : () async {
                                        final valid = _formKey.currentState?.validate() == true;
                                        if (!valid) return;

                                        if (!vm.acceptedTerms) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please accept the Terms & Privacy')),
                                          );
                                          return;
                                        }

                                        await vm.signUp(
                                          email: _emailController.text.trim(),
                                          password: _passwordController.text,
                                        );

                                        if (vm.error == null && mounted) {
                                          Navigator.maybePop(context);
                                        }
                                      },
                                      child: vm.isLoading
                                          ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                          : const Text('Create account'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Already have account
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account?",
                                        style: TextStyle(color: Colors.black.withOpacity(0.7)),
                                      ),
                                      TextButton(
                                        onPressed: vm.isLoading ? null : () => Navigator.maybePop(context),
                                        child: const Text('Log in'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
