import 'package:billing/screens/Management/ManagementScreen.dart';
import 'package:billing/screens/billing/billing_screen.dart';
import 'package:billing/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // 💡 REQUIRED FOR ImageFilter.blur
import 'screens/settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<String> _tabLabels = const [
    'Home',
    'Manage',
    'New Order',
    'Settings',
  ];

  final List<Widget> _pages = const [
    HomeScreen(),
    ManagementScreen(),
    SettingsScreen(),
  ];

  final List<List<IconData>> _icons = const [
    [Icons.home_outlined, Icons.home_rounded],
    [Icons.inventory_2_outlined, Icons.inventory_2_rounded],
    [Icons.point_of_sale_outlined, Icons.point_of_sale_rounded],
    [Icons.person_outline_rounded, Icons.person_rounded],
  ];

  // Maps the 4 navigation bar indices (0, 1, 2, 3) to the 3 page indices (0, 1, 2)
  final Map<int, int> _tabIndexToPageIndex = const {
    0: 0, // Home -> HomeScreen
    1: 1, // Manage -> ManagementScreen
    3: 2, // Settings -> SettingsScreen (Index 2 in _pages)
  };

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();

    // Index 2 is the 'New Order' button, which pushes a new route
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BillingScreen()),
      );
    } else {
      // Update the selected tab index for view switching
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which page to show in the IndexedStack
    final int pageIndex = _tabIndexToPageIndex[_selectedIndex]!;

    return Scaffold(
      // MUST be true for the body content to show behind the floating nav bar
      extendBody: true,
      body: IndexedStack(
        index: pageIndex,
        children: _pages,
      ),
      bottomNavigationBar: _PillBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        icons: _icons,
        labels: _tabLabels,
      ),
    );
  }
}

// ===================================================
// UPDATED: _PillBottomNavBar with BackdropFilter
// ===================================================

class _PillBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<List<IconData>> icons;
  final List<String> labels;

  const _PillBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.icons,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        // Wide Pill: Reduced horizontal margin
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),

        // ➡️ START: Frosted Glass Effect Implementation
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            // Apply the blur effect
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              // Provides the color tint and dimensions
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                // Use a lower opacity for the color tint now that the blur is active
                color: theme.colorScheme.surface.withOpacity(0.75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              // ➡️ END: Frosted Glass Effect Implementation

              child: Row(
                children: List.generate(icons.length, (index) {
                  final bool selected = index == selectedIndex;

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onItemTapped(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        // Changed curve for a smoother visual feel (as discussed)
                        curve: Curves.easeOutCubic,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                selected ? icons[index][1] : icons[index][0],
                                size: 26,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade600,
                              ),
                              // AnimatedSize handles the text expansion
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                child: selected
                                    ? Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Text(
                                    labels[index],
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}