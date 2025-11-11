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

// Removed ShowcaseKeys class and provider

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // Removed ShowcaseKeys fields

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

  final List<List<IconData>> _icons = const [
    [Icons.home_outlined, Icons.home_rounded],
    [Icons.inventory_2_outlined, Icons.inventory_2_rounded],
    [Icons.point_of_sale_outlined, Icons.point_of_sale_rounded],
    [Icons.person_outline_rounded, Icons.person_rounded],
  ];

  final Map<int, int> _tabIndexToPageIndex = const {
    0: 0,
    1: 1,
    3: 2,
  };

  @override
  void initState() {
    super.initState();
    // Removed showcase initialization and start logic
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

  // Removed _checkAndStartShowcase and _onShowcaseFinish methods

  @override
  Widget build(BuildContext context) {
    // Removed ShowCaseWidget wrapper
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
        // Removed keys parameter
      ),
    );
  }
}

class _PillBottomNavBar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<List<IconData>> icons;
  final List<String> labels;
  // Removed keys field

  const _PillBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.icons,
    required this.labels,
    // Removed keys requirement
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Removed isShowcaseActive check

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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

                  // Removed key determination logic

                  Widget itemContent = InkWell(
                    borderRadius: BorderRadius.circular(10),
                    // Removed showcase conditional tap logic
                    onTap: () => onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
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
                  );

                  // Removed Showcase widget wrapper
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