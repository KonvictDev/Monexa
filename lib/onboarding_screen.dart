import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'auth_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardPageData> _pages = [
    _OnboardPageData(
      icon: Icons.point_of_sale_rounded,
      title: "Smarter Billing",
      description:
      "Generate bills and invoices in seconds with a simple, intuitive interface built for speed.",
      color: Colors.blueAccent,
    ),
    _OnboardPageData(
      icon: Icons.inventory_2_rounded,
      title: "Real-Time Stock Tracking",
      description:
      "Stay on top of your inventory and receive alerts before products run out.",
      color: Colors.teal,
    ),
    _OnboardPageData(
      icon: Icons.bar_chart_rounded,
      title: "Insightful Reports",
      description:
      "Visualize your daily sales and business growth through beautiful analytics dashboards.",
      color: Colors.deepPurple,
    ),
    _OnboardPageData(
      icon: Icons.lock_outline_rounded,
      title: "Secure and Private",
      description:
      "Your business data stays protected with PIN authentication and secure cloud backup.",
      color: Colors.orangeAccent,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final settingsBox = Hive.box('settings');
    await settingsBox.put('onboarding_completed', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- Skip button ---
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text("Skip"),
              ),
            ),

            // --- Page content ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardPage(page: page);
                },
              ),
            ),

            // --- Page indicator ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Next / Get Started button ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? "Get Started"
                        : "Next",
                    style: const TextStyle(fontSize: 18,color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------

class _OnboardPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _OnboardPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

// -------------------------------------------------------------------

class _OnboardPage extends StatelessWidget {
  final _OnboardPageData page;

  const _OnboardPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 90,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
