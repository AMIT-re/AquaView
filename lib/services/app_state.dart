import 'package:flutter/material.dart';

enum UserRole { citizen, farmer, industry }

class AppState extends ChangeNotifier {
  UserRole? _selectedRole;
  bool _isOnboardingComplete = false;

  UserRole? get selectedRole => _selectedRole;
  bool get isOnboardingComplete => _isOnboardingComplete;

  void selectRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  void completeOnboarding() {
    _isOnboardingComplete = true;
    notifyListeners();
  }

  void reset() {
    _selectedRole = null;
    _isOnboardingComplete = false;
    notifyListeners();
  }
}

