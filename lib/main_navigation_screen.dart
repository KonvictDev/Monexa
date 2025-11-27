// MainNavigationScreen.dart

import 'package:billing/screens/Management/ManagementScreen.dart';
import 'package:billing/screens/billing/billing_screen.dart';
import 'package:billing/screens/home/home_screen.dart';
import 'package:billing/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billing/repositories/settings_repository.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<String> _tabLabels = const [
    'Home',
    'Manage',
    'New Order',
    'Settings',
  ];

  final List<Widget> _pages = [
    const HomeScreen(),
    ManagementHubScreen(),
    const SettingsScreen(),
  ];

  // 🔥 UPDATED: Changed from List<List<IconData>> to List<List<dynamic>>
  // to support both Strings (Assets) and IconData.
  // Index 0: Inactive, Index 1: Active
  final List<List<dynamic>> _icons = const [
    ['assets/icons/home_outline.png', 'assets/icons/home_filled.png'], // Custom Images
    ['assets/icons/manage_outline.png', 'assets/icons/manage_filled.png'], // Material Icons
    ['assets/icons/billing_filled.png', 'assets/icons/billing_filled.png'], // Material Icons
    ['assets/icons/settings_outline.png', 'assets/icons/settings_filled.png'], // Material Icons
  ];

  final Map<int, int> _tabIndexToPageIndex = const {
    0: 0,
    1: 1,
    3: 2,
  };

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BillingScreen()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int pageIndex = _tabIndexToPageIndex[_selectedIndex]!;

    return Scaffold(
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

class _PillBottomNavBar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  // 🔥 UPDATED: Now accepts dynamic to allow Strings or IconData
  final List<List<dynamic>> icons;
  final List<String> labels;

  const _PillBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.icons,
    required this.labels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.75),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: List.generate(icons.length, (index) {
                  final bool selected = index == selectedIndex;

                  // Extract the correct icon/path based on selection state
                  final dynamic iconSource = selected ? icons[index][1] : icons[index][0];
                  final Color iconColor = selected
                      ? theme.colorScheme.primary
                      : Colors.grey.shade600;

                  Widget itemContent = InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
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
                            // 🔥 LOGIC: Check type to decide render method
                            if (iconSource is String)
                              Image.asset(
                                iconSource,
                                width: 24, // Explicit size to match Icon
                                height: 24,
                                color: iconColor, // Tint the image
                              )
                            else
                              Icon(
                                iconSource as IconData,
                                size: 26,
                                color: iconColor,
                              ),

                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              child: selected
                                  ? Padding(
                                padding: const EdgeInsets.only(left: 6), // Increased slightly for image spacing
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
                  );

                  return Expanded(child: itemContent);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}