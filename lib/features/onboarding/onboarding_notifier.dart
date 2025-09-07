import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // For BMI calculation

//==============================================================================
//--- 1. STATE MANAGEMENT (Notifier) ---
// This class holds all the data collected during the onboarding process.
//==============================================================================
class OnboardingNotifier extends ChangeNotifier {
  // --- Step 1: Account ---
  String email = '';
  String password = '';

  // --- Step 2: Profile ---
  double height = 178; // Default value
  double weight = 82;  // Default value
  double get bmi => (weight > 0 && height > 0) ? (weight / pow(height / 100, 2)) : 0;

  // --- Step 3: Goals (Dummy Calculations) ---
  int get suggestedCalories => (10 * weight + 6.25 * height - 200).round();
  int get proteinGrams => (suggestedCalories * 0.3 / 4).round();
  int get carbsGrams => (suggestedCalories * 0.4 / 4).round();
  int get fatGrams => (suggestedCalories * 0.3 / 9).round();

  // --- General Methods ---
  void updateHeight(double newHeight) {
    height = newHeight;
    notifyListeners();
  }

  void updateWeight(double newWeight) {
    weight = newWeight;
    notifyListeners();
  }
}