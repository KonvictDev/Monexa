import 'package:flutter/material.dart';

class PinIndicator extends StatelessWidget {
  final int pinLength;
  final bool hasError;

  const PinIndicator({super.key, required this.pinLength, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor =
    hasError ? theme.colorScheme.error : theme.colorScheme.primary;
    final inactiveColor =
    theme.colorScheme.outlineVariant.withOpacity(0.4);

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
            color: filled ? activeColor : inactiveColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class NumericKeypad extends StatelessWidget {
  final void Function(String) onKeyPressed;

  const NumericKeypad({super.key, required this.onKeyPressed});

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
        if (value == 'empty') return const SizedBox.shrink();

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