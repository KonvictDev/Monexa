import 'package:billing/screens/Management/ManagementScreen.dart';
import 'package:billing/screens/billing/billing_screen.dart';
import 'package:billing/screens/home/home_screen.dart';
import 'package:billing/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billing/repositories/settings_repository.dart';
// ✅ IMPORT STAFF DASHBOARD
import 'package:billing/screens/staff/staff_dashboard_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // --- CONFIG: Owner Mode ---
  final List<Widget> _ownerPages = [
    const HomeScreen(),
    ManagementHubScreen(),
    const BillingScreen(), // Placeholder, overridden by onTap
    const SettingsScreen(),
  ];
  final List<List<dynamic>> _ownerIcons = const [
    ['assets/icons/home_outline.png', 'assets/icons/home_filled.png'],
    ['assets/icons/manage_outline.png', 'assets/icons/manage_filled.png'],
    ['assets/icons/billing_filled.png', 'assets/icons/billing_filled.png'],
    ['assets/icons/settings_outline.png', 'assets/icons/settings_filled.png'],
  ];
  final List<String> _ownerLabels = const ['Home', 'Manage', 'New Order', 'Settings'];

  // --- CONFIG: Staff Mode ---
  final List<Widget> _staffPages = [
    const StaffDashboardScreen(), // Tab 0
    const BillingScreen(),        // Tab 1 (Placeholder)
  ];
  // Using simplified icons for Staff
  final List<List<dynamic>> _staffIcons = const [
    [Icons.dashboard_outlined, Icons.dashboard_rounded],
    [Icons.add_shopping_cart_rounded, Icons.add_shopping_cart_rounded],
  ];
  final List<String> _staffLabels = const ['Dashboard', 'New Order'];


  void _onItemTapped(int index, bool isStaffMode) {
    HapticFeedback.selectionClick();

    // Logic: If it's the "New Order" button, push the full screen
    // Owner Mode: Index 2 is New Order
    // Staff Mode: Index 1 is New Order
    final bool isNewOrderAction = (!isStaffMode && index == 2) || (isStaffMode && index == 1);

    if (isNewOrderAction) {
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
    // 1. Check Mode
    final isStaffMode = ref.watch(settingsRepositoryProvider).isStaffMode;

    // 2. Select Configuration
    final currentPages = isStaffMode ? _staffPages : _ownerPages;
    final currentIcons = isStaffMode ? _staffIcons : _ownerIcons;
    final currentLabels = isStaffMode ? _staffLabels : _ownerLabels;

    // 3. Safety Check: If switching modes reduces tab count, reset index
    if (_selectedIndex >= currentPages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: currentPages,
      ),
      bottomNavigationBar: _PillBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (idx) => _onItemTapped(idx, isStaffMode),
        icons: currentIcons,
        labels: currentLabels,
      ),
    );
  }
}

// ... [Keep _PillBottomNavBar class exactly as it is] ...
class _PillBottomNavBar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
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
                            if (iconSource is String)
                              Image.asset(
                                iconSource,
                                width: 24,
                                height: 24,
                                color: iconColor,
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
                                padding: const EdgeInsets.only(left: 6),
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