import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main_navigation_screen.dart';
import '../../providers/pin_auth_provider.dart';
import '../../widgets/auth/pin_keypad.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

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
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  void _handleNumericInput(String value) {
    setState(() {
      _errorMessage = '';
      if (_isConfirming) {
        if (_confirmPin.length < 4) {
          _confirmPin += value;
        }
      } else {
        if (_pin.length < 4) {
          _pin += value;
        }
      }
    });

    if (!_isConfirming && _pin.length == 4) {
      setState(() => _isConfirming = true);
    }

    if (_isConfirming && _confirmPin.length == 4) {
      _savePin();
    }
  }

  Future<void> _savePin() async {
    if (_pin != _confirmPin) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      return;
    }

    await ref.read(pinAuthProvider.notifier).setPin(_pin);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPinLength = _isConfirming ? _confirmPin.length : _pin.length;

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
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isConfirming ? 'Confirm Your PIN' : 'Create a 4-Digit PIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 16),
              PinIndicator(pinLength: currentPinLength, hasError: _errorMessage.isNotEmpty),
              const SizedBox(height: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _errorMessage.isNotEmpty ? 1 : 0,
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              NumericKeypad(onKeyPressed: _onKeyPressed),
              const SizedBox(height: 24),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isConfirming ? 1 : 0,
                child: TextButton.icon(
                  onPressed: _isConfirming
                      ? () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isConfirming = false;
                      _confirmPin = '';
                      _pin = '';
                      _errorMessage = '';
                    });
                  }
                      : null,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Start Over'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}