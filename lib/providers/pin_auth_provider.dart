// lib/providers/pin_auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 1. Define the provider
final pinAuthProvider = ChangeNotifierProvider<PinAuthProvider>((ref) {
  return PinAuthProvider();
});

// 2. Define our app's lock state
enum AppLockState {
  unknown,      // App is launching, we don't know the state yet
  unlocked,     // User is authenticated
  locked,       // User is logged out / app just launched
  noPinSet,     // This is the first launch, user must create a PIN
}

class PinAuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _pinKey = 'app_pin_code'; // The key to store the PIN

  AppLockState _lockState = AppLockState.unknown;
  AppLockState get lockState => _lockState;

  PinAuthProvider() {
    _checkPinStatusOnLaunch();
  }

  /// Called on app start to check if a PIN exists
  Future<void> _checkPinStatusOnLaunch() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      if (pin == null || pin.isEmpty) {
        _lockState = AppLockState.noPinSet;
      } else {
        _lockState = AppLockState.locked;
      }
    } catch (e) {
      // If storage fails, default to no PIN for safety
      debugPrint("Error reading from secure storage: $e");
      _lockState = AppLockState.noPinSet;
    }
    notifyListeners();
  }

  /// Saves the user's first PIN
  Future<void> setPin(String newPin) async {
    if (newPin.length != 4) return; // Enforce 4-digit PIN
    await _storage.write(key: _pinKey, value: newPin);
    _lockState = AppLockState.unlocked; // Immediately unlock after setting
    notifyListeners();
  }

  /// Attempts to unlock the app with a PIN
  Future<bool> checkPin(String pinAttempt) async {
    final storedPin = await _storage.read(key: _pinKey);
    if (storedPin == pinAttempt) {
      _lockState = AppLockState.unlocked;
      notifyListeners();
      return true; // Success
    }
    return false; // Failure
  }

  /// Locks the app (e.g., when it's put in the background)
  void lockApp() {
    // Don't lock the app if a PIN hasn't even been set yet
    if (_lockState != AppLockState.noPinSet) {
      _lockState = AppLockState.locked;
      notifyListeners();
    }
  }

  /// Resets the auth state and deletes the stored PIN.
  /// Used when a user signs out.
  Future<void> resetPinAuth() async {
    try {
      await _storage.delete(key: _pinKey);
      _lockState = AppLockState.noPinSet; // Set state for the next user
    } catch (e) {
      debugPrint("Error deleting PIN from secure storage: $e");
      _lockState = AppLockState.noPinSet; // Default to no PIN
    }
    notifyListeners();
  }
}