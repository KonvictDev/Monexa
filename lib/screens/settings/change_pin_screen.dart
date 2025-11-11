import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pin_auth_provider.dart';
import '../../utils/date_filter.dart';
import '../../widgets/auth/pin_keypad.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  PinStage _currentStage = PinStage.verifyOld;
  String _inputPin = '';
  String _oldPin = '';
  String _newPin = '';
  String _errorMessage = '';

  void _resetInput({String message = ''}) {
    HapticFeedback.lightImpact();
    setState(() {
      _inputPin = '';
      _errorMessage = message;
    });
  }

  void _onKeyPressed(String value) {
    if (value == 'back') {
      _handleBackspace();
      return;
    }
    _handleNumericInput(value);
  }

  void _handleBackspace() {
    setState(() {
      _errorMessage = '';
      if (_inputPin.isNotEmpty) {
        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      }
    });
  }

  void _handleNumericInput(String value) async {
    if (_inputPin.length < 4) {
      setState(() {
        _errorMessage = '';
        _inputPin += value;
      });
    }

    if (_inputPin.length == 4) {
      if (_currentStage == PinStage.verifyOld) {
        _verifyOldPin();
      } else if (_currentStage == PinStage.setNew) {
        _setNewPin();
      } else if (_currentStage == PinStage.confirmNew) {
        _confirmNewPin();
      }
    }
  }

  Future<void> _verifyOldPin() async {
    final authNotifier = ref.read(pinAuthProvider.notifier);
    final success = await authNotifier.checkPin(_inputPin);

    if (success) {
      authNotifier.lockApp();
      setState(() {
        _oldPin = _inputPin;
        _currentStage = PinStage.setNew;
      });
      _resetInput(message: 'Old PIN accepted. Enter new PIN.');
    } else {
      HapticFeedback.heavyImpact();
      _resetInput(message: 'Incorrect old PIN.');
    }
  }

  void _setNewPin() {
    if (_inputPin == _oldPin) {
      HapticFeedback.heavyImpact();
      _resetInput(message: 'New PIN cannot be the same as old PIN.');
      return;
    }
    setState(() {
      _newPin = _inputPin;
      _currentStage = PinStage.confirmNew;
    });
    _resetInput(message: 'Now confirm your new PIN.');
  }

  void _confirmNewPin() async {
    if (_inputPin == _newPin) {
      final authNotifier = ref.read(pinAuthProvider.notifier);
      await authNotifier.setPin(_newPin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Security PIN successfully changed!')),
        );
        Navigator.pop(context);
      }
    } else {
      HapticFeedback.heavyImpact();
      _resetInput();
      setState(() {
        _currentStage = PinStage.setNew;
        _newPin = '';
        _errorMessage = 'PINs do not match. Start over.';
      });
    }
  }

  String _getTitle() {
    switch (_currentStage) {
      case PinStage.verifyOld:
        return 'Verify Old PIN';
      case PinStage.setNew:
        return 'Set New PIN';
      case PinStage.confirmNew:
        return 'Confirm New PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getTitle(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _errorMessage.isNotEmpty ? 1 : 0.6,
                child: Text(
                  _errorMessage.isNotEmpty
                      ? _errorMessage
                      : _currentStage == PinStage.verifyOld
                      ? 'Enter your current PIN to continue.'
                      : _currentStage == PinStage.setNew
                      ? 'Choose a new 4-digit PIN.'
                      : 'Confirm your new PIN.',
                  style: TextStyle(
                    color: _errorMessage.isNotEmpty
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              PinIndicator(
                pinLength: _inputPin.length,
                hasError: _errorMessage.isNotEmpty,
              ),
              const Spacer(),
              NumericKeypad(onKeyPressed: _onKeyPressed),
              const SizedBox(height: 24),
              if (_currentStage != PinStage.verifyOld)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStage = PinStage.verifyOld;
                      _inputPin = '';
                      _newPin = '';
                      _oldPin = '';
                      _errorMessage = '';
                    });
                    HapticFeedback.selectionClick();
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Start Over'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}