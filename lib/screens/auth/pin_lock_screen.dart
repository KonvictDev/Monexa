import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/pin_auth_provider.dart';

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
              _PinIndicator(
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
              _NumericKeypad(onKeyPressed: _onKeyPressed),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  // Optionally add forgot PIN flow here
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

// --- PIN DOTS WITH ANIMATION ---
class _PinIndicator extends StatelessWidget {
  final int pinLength;
  final bool hasError;
  const _PinIndicator({required this.pinLength, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final inactive = theme.colorScheme.outlineVariant.withOpacity(0.4);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final filled = index < pinLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: filled ? 20 : 14,
          height: filled ? 20 : 14,
          decoration: BoxDecoration(
            color: filled ? active : inactive,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

// --- MODERN NUMERIC KEYPAD ---
class _NumericKeypad extends StatelessWidget {
  final void Function(String) onKeyPressed;
  const _NumericKeypad({required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttons = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      'empty', '0', 'back',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: buttons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final value = buttons[index];
        if (value == 'empty') {
          return const SizedBox.shrink();
        }

        Widget child;
        if (value == 'back') {
          child = Icon(
            Icons.backspace_outlined,
            color: theme.colorScheme.onSurface,
          );
        } else {
          child = Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          );
        }

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onKeyPressed(value),
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}
