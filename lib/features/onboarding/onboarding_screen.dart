//==============================================================================
//--- 2. MAIN SCREEN WRAPPER (Entry Point) ---
// Sets up the Provider and the main StatefulWidget.
//==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'onboarding_notifier.dart';

class OnboardingFlowWrapper extends StatelessWidget {
  const OnboardingFlowWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingNotifier(),
      // The provider is now an ancestor of OnboardingScreen, so the error is solved.
      child: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  void _previousPage() => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  final List<String> _titles = ['Create Account', 'Your Profile', 'Your Goals'];

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF30D575);
    const darkBg = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg, elevation: 0, centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: _currentPage == 0 ? () => Navigator.of(context).pop() : _previousPage,
        ),
        title: Text(_titles[_currentPage], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _StepProgressIndicator(totalSteps: 3, currentStep: _currentPage + 1, activeColor: primaryGreen),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _CreateAccountStep(onNext: _nextPage),
                  _ProfileStep(onContinue: _nextPage),
                  _GoalsStep(onAccept: () => print("Onboarding Complete!")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//==============================================================================
//--- 3. STEP WIDGETS ---
// Each of these represents one screen in the PageView.
//==============================================================================

// --- Step 1: Create Account ---
class _CreateAccountStep extends StatelessWidget {
  final VoidCallback onNext;
  const _CreateAccountStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // This screen has no titles, just form fields
          const SizedBox(height: 40),
          _buildTextField(label: 'Email', hint: 'Enter your email'),
          const SizedBox(height: 20),
          _buildTextField(label: 'Password', hint: 'Enter your password', isPassword: true),
          const SizedBox(height: 20),
          _buildTextField(label: 'Confirm Password', hint: 'Confirm your password', isPassword: true),
          const SizedBox(height: 80),
          _MainButton(text: 'Next', onTap: onNext),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: isPassword ? const Icon(Icons.visibility_off, color: Colors.grey) : null,
          ),
        ),
      ],
    );
  }
}

// --- Step 2: Your Profile ---
class _ProfileStep extends StatelessWidget {
  final VoidCallback onContinue;
  const _ProfileStep({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to react to changes in the notifier
    return Consumer<OnboardingNotifier>(
      builder: (context, notifier, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const _SectionHeader(
                title: 'Your Details',
                subtitle: 'This helps us create a personalized plan for you.',
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  _buildMeasurementField(
                    label: 'Height',
                    unit: 'cm',
                    initialValue: notifier.height.toStringAsFixed(0),
                    onChanged: (val) => notifier.updateHeight(double.tryParse(val) ?? notifier.height),
                  ),
                  const SizedBox(width: 16),
                  _buildMeasurementField(
                    label: 'Weight',
                    unit: 'kg',
                    initialValue: notifier.weight.toStringAsFixed(0),
                    onChanged: (val) => notifier.updateWeight(double.tryParse(val) ?? notifier.weight),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _BMICard(bmi: notifier.bmi),
              const SizedBox(height: 40),
              _MainButton(text: 'Continue', onTap: onContinue),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeasurementField({
    required String label,
    required String unit,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixText: unit,
              suffixStyle: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Step 3: Your Goals ---
class _GoalsStep extends StatelessWidget {
  final VoidCallback onAccept;
  const _GoalsStep({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    // This widget also consumes the notifier to get the calculated goals
    final notifier = context.watch<OnboardingNotifier>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const _SectionHeader(
            title: 'Your Daily Goals',
            subtitle: 'Based on your profile, here are our suggestions.',
          ),
          const SizedBox(height: 32),
          _buildCaloriesCard(notifier.suggestedCalories),
          const SizedBox(height: 24),
          _buildMacrosCard(notifier.proteinGrams, notifier.carbsGrams, notifier.fatGrams),
          const SizedBox(height: 40),
          _SecondaryButton(text: 'Customize', onTap: () {}),
          const SizedBox(height: 16),
          _MainButton(text: 'Accept & Continue', onTap: onAccept),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard(int calories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department, color: Color(0xFF30D575)),
                  SizedBox(width: 8),
                  Text('Calories', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              Text('$calories', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 1.0,
              minHeight: 8,
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF30D575)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosCard(int protein, int carbs, int fat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Macronutrients', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _MacroRow(label: 'Protein', value: '${protein}g', progress: 0.6, color: Colors.blue),
          const SizedBox(height: 16),
          _MacroRow(label: 'Carbs', value: '${carbs}g', progress: 0.8, color: Colors.orange),
          const SizedBox(height: 16),
          _MacroRow(label: 'Fat', value: '${fat}g', progress: 0.5, color: Colors.purple),
        ],
      ),
    );
  }
}

//==============================================================================
//--- 4. REUSABLE WIDGETS ---
// Common components used across multiple steps.
//==============================================================================

class _StepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final Color activeColor;
  final Color inactiveColor;

  const _StepProgressIndicator({
    required this.totalSteps,
    required this.currentStep,
    required this.activeColor,
    this.inactiveColor = const Color(0xFF2C2C2E),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(
              color: index < currentStep ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
      ],
    );
  }
}

class _BMICard extends StatelessWidget {
  final double bmi;
  const _BMICard({required this.bmi});

  String _getBmiCategory(double bmiValue) {
    if (bmiValue < 18.5) return 'underweight';
    if (bmiValue < 25) return 'normal';
    if (bmiValue < 30) return 'overweight';
    return 'obese';
  }

  @override
  Widget build(BuildContext context) {
    final category = _getBmiCategory(bmi);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Your Body Mass Index (BMI)', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 16),
          Text(
            bmi.toStringAsFixed(1),
            style: const TextStyle(color: Color(0xFF30D575), fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _BMIGauge(bmi: bmi),
          const SizedBox(height: 16),
          Text(
            'Your BMI is in the $category range. We will tailor your plan to help you reach a healthy weight.',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BMIGauge extends StatelessWidget {
  final double bmi;
  const _BMIGauge({required this.bmi});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the position of the indicator needle
            final double totalWidth = constraints.maxWidth;
            final double position = ((bmi - 15).clamp(0, 25) / 25) * totalWidth;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
                      stops: [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: position - 2, // Center the triangle
                  child: const RotatedBox(
                    quarterTurns: 2,
                    child: Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Underweight', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text('Normal', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text('Overweight', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text('Obese', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MainButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _MainButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF30D575),
          foregroundColor: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SecondaryButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF30D575)),
          foregroundColor: const Color(0xFF30D575),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}