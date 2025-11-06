/** lib/widgets/pin_input_widgets.dart */
import 'package:flutter/material.dart';

/**
 * A visual indicator widget for the 4-digit PIN input field.
 */
class PinIndicator extends StatelessWidget {
  /** The current length of the PIN entered (0 to 4). */
  final int pinLength;

  /** Whether an error state should be displayed (e.g., wrong PIN). */
  final bool hasError;

  /**
   * Creates a PinIndicator widget.
   * @param pinLength The current length of the PIN.
   * @param hasError Flag indicating if an error is present.
   */
  const PinIndicator({super.key, required this.pinLength, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    /** Get the error color from the current theme. */
    final errorColor = Theme.of(context).colorScheme.error;
    /** Get the primary color from the current theme. */
    final primaryColor = Theme.of(context).colorScheme.primary;

    /** Arrange the four PIN dots horizontally. */
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      /** Generate exactly 4 dots (Containers). */
      children: List.generate(4, (index) {
        return Container(
          /** Apply horizontal spacing between the dots. */
          margin: const EdgeInsets.symmetric(horizontal: 12),
          /** Define the width of the dot. */
          width: 20,
          /** Define the height of the dot. */
          height: 20,
          decoration: BoxDecoration(
            /** Ensure the dot is circular. */
            shape: BoxShape.circle,
            /** Set the color based on error state or input progress. */
            color: hasError
            /** If there is an error, use the error color. */
                ? errorColor
            /** Otherwise, fill the dot if its index is less than the PIN length, or use light grey if not. */
                : (index < pinLength ? primaryColor : Colors.grey.shade300),
          ),
        );
      }),
    );
  }
}

/**
 * A custom numeric keypad widget for PIN entry.
 */
class NumericKeypad extends StatelessWidget {
  /** Callback function invoked when a key (0-9, or 'back') is pressed. */
  final void Function(String) onKeyPressed;

  /**
   * Creates a NumericKeypad widget.
   *
   * @param onKeyPressed The callback to handle key presses.
   */
  const NumericKeypad({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    /** Display the keys in a 3x4 grid layout. */
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        /** Three columns for the grid. */
        crossAxisCount: 3,
        /** Aspect ratio slightly wider than tall for keys. */
        childAspectRatio: 1.5,
      ),
      /** Total of 12 keys (1-9, empty, 0, back). */
      itemCount: 12,
      /** Shrink the GridView height to fit content in a column/safe area. */
      shrinkWrap: true,
      /** Prevent internal scrolling since it's inside a scrollable view. */
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        String value;
        Widget display = const SizedBox();

        /** Check for the special keys in the last row. */
        if (index == 9) {
          /** Index 9 is the empty slot (top-left of the last row). */
          value = 'empty';
          display = const SizedBox();
        } else if (index == 10) {
          /** Index 10 is the '0' key. */
          value = '0';
          display = const Text('0', style: TextStyle(fontSize: 24));
        } else if (index == 11) {
          /** Index 11 is the 'backspace' key. */
          value = 'back';
          display = const Icon(Icons.backspace_outlined);
        } else {
          /** Indices 0-8 are for numbers 1-9. */
          value = (index + 1).toString();
          display = Text(value, style: const TextStyle(fontSize: 24));
        }

        /** Returns an InkWell wrapper for each key to handle taps. */
        return InkWell(
          /** Disable tap functionality if the key is the 'empty' slot. */
          onTap: value == 'empty' ? null : () => onKeyPressed(value),
          /** Apply a circular border radius for the ripple effect. */
          borderRadius: BorderRadius.circular(100),
          /** Center the key content (number or icon). */
          child: Center(child: display),
        );
      },
    );
  }
}