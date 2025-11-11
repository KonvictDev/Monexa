import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'auth_wrapper.dart'; // Make sure this path is correct

const Color _primaryColor = Colors.blue;

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
      assetImage: 'assets/images/onboard1.png',
      title: "Generate bills\nand invoices",
      description:
      "in seconds with a simple, intuitive interface built for speed.",
    ),
    _OnboardPageData(
      assetImage: 'assets/images/onboard2.png',
      title: "Real-Time\nStock Tracking",
      description:
      "of your inventory and receive alerts before products run out.",
    ),
    _OnboardPageData(
      assetImage: 'assets/images/onboard3.png',
      title: "Insightful Reports",
      description:
      "of your daily sales and business growth through beautiful analytics dashboards.",
    ),
    _OnboardPageData(
      assetImage: 'assets/images/onboard4.png',
      title: "Stay Secure and Private",
      description:
      "with PIN authentication and secure cloud backup.",
    ),
  ];

  Future<void> _completeOnboarding() async {
    // Assuming 'settings' box is open and Hive is initialized
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
    HapticFeedback.mediumImpact();
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // The _previousPage method is no longer used, but kept for completeness
  void _previousPage() {
    if (_currentPage > 0) {
      HapticFeedback.selectionClick();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
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
    final Color activeDotColor = _primaryColor;
    final Color inactiveDotColor = theme.colorScheme.onSurface.withOpacity(0.3);
    final bool isLastPage = _currentPage == _pages.length - 1;

    // Calculate progress for the progress line (0.25 to 1.0)
    final double progress = (_currentPage + 1) / _pages.length;

    // --- Page Indicator Dots Widget ---
    final Widget pageIndicators = Row(
      mainAxisAlignment: MainAxisAlignment.start, // Align dots to the left
      mainAxisSize: MainAxisSize.min, // Keep row size to minimum required
      children: List.generate(
        _pages.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? activeDotColor
                : inactiveDotColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Skip Button ---
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _completeOnboarding();
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.9)
                      : theme.colorScheme.primary.withOpacity(0.9),
                ),
                child: const Text(
                  "Skip",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // --- PageView with pure fade transition ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double opacity = 1.0;

                      // Smooth fade between pages
                      if (_pageController.position.haveDimensions) {
                        double value =
                            ((_pageController.page ?? _currentPage).toDouble()) -
                                index;
                        opacity =
                            ((1 - value.abs()).clamp(0.0, 1.0)).toDouble();
                      }

                      return Opacity(
                        opacity: Curves.easeOut.transform(opacity),
                        child: child,
                      );
                    },
                    child: _OnboardPage(page: _pages[index]),
                  );
                },
              ),
            ),

            // --- Action Buttons with Page Indicators ---
            Padding(
              // Reduced bottom padding as the indicators are now here
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                height: 60, // Fixed height for alignment
                child: isLastPage
                    ? SizedBox(
                  width: double.infinity, // Ensures full width for 'Start Now'
                  child: FilledButton(
                    onPressed: _completeOnboarding,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Start Now",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Page Indicators (New Position)
                    pageIndicators,

                    // 2. Spacer to push the next button to the end
                    const Spacer(),

                    // 3. Next Button with Progress Fill
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress Indicator (Animated Container for the fill)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1), // Base color
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              width: 60 * progress, // Fills horizontally based on progress
                              height: 60,
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.3), // Fill color
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        // The Next Button Icon (on top)
                        IconButton.filled(
                          onPressed: _nextPage,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          style: IconButton.styleFrom(
                            // Use transparent color so the AnimatedContainer acts as the progress background
                            backgroundColor: Colors.transparent,
                            foregroundColor: _primaryColor, // Icon color remains primary
                            fixedSize: const Size(60, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
  final String assetImage;
  final String title;
  final String description;

  _OnboardPageData({
    required this.assetImage,
    required this.title,
    required this.description,
  });
}

// -------------------------------------------------------------------

class _OnboardPage extends StatelessWidget {
  final _OnboardPageData page;

  const _OnboardPage({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: Container(
            alignment: Alignment.center,
            child: Image.asset(
              page.assetImage,
              // Use a fraction of screen height for image sizing
              height: mediaQuery.size.height * 0.52,
              fit: BoxFit.contain,
            ),
          ),
        ),

        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              // CHANGE 1: Align all children of this column to the start (left)
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: 36, // Large font for title
                  ),
                  // CHANGE 2: Left-align the title text
                  textAlign: TextAlign.start,
                ),

                // Added a spacer for separation
                const SizedBox(height: 6),

                Text(
                  page.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                    fontSize: 18, // Increased font size for description
                  ),
                  // CHANGE 3: Left-align the description text
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}