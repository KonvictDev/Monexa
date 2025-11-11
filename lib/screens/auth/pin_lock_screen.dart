import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pin_auth_provider.dart';
import '../../widgets/auth/pin_keypad.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _pin = '';
  String? _errorMessage;

  void _onKeyPressed(String value) {
    if (value == 'back') {
      _handleBackspace();
      return;
    }
    _handleNumericInput(value);
  }

  void _handleBackspace() {
    setState(() {
      _errorMessage = null;
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _handleNumericInput(String value) {
    setState(() {
      _errorMessage = null;
      if (_pin.length < 4) {
        _pin += value;
      }
    });
    if (_pin.length == 4) _checkPin();
  }

  Future<void> _checkPin() async {
    final authNotifier = ref.read(pinAuthProvider.notifier);
    final success = await authNotifier.checkPin(_pin);

    if (!success) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Incorrect PIN. Try again.';
        _pin = '';
      });
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
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Enter Your PIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 16),
              PinIndicator(
                pinLength: _pin.length,
                hasError: _errorMessage != null,
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _errorMessage != null ? 1 : 0,
                child: Text(
                  _errorMessage ?? '',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              NumericKeypad(onKeyPressed: _onKeyPressed),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {

                },
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: const Text('Forgot PIN?'),
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