import 'dart:async';
import 'dart:math';
import 'package:billing/screens/auth/pin_lock_screen.dart';
import 'package:flutter/material.dart';

import '../../auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _titleTextStyle = TextStyle(
    fontSize: 58,
    fontWeight: FontWeight.bold,
    color: Colors.blueAccent,
    letterSpacing: 1.2,
  );

  final String fullText = "Monexa";
  late AnimationController _revealController;
  late AnimationController _taglineController;
  late Timer _cursorTimer;
  bool showCursor = true;
  double textHeight = 0.0;

  late final BillingIconsBackgroundPainter _backgroundPainter;

  @override
  void initState() {
    super.initState();

    _measureTextHeight();
    _backgroundPainter = BillingIconsBackgroundPainter();

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _startCursorBlink();

    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _taglineController.forward();

        // 🕒 Wait for tagline to fade in + show briefly before navigation
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 800),
                pageBuilder: (_, __, ___) => const AuthWrapper(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
          }
        });

      }
    });
  }


  void _measureTextHeight() {
    final painter = TextPainter(
      text: const TextSpan(
        text: 'M',
        style: _titleTextStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textHeight = painter.height;
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => showCursor = !showCursor);
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _taglineController.dispose();
    _cursorTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
    isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.blueAccent;
    final cursorColor = isDark ? Colors.white : Colors.blueAccent;
    final taglineColor = isDark ? Colors.grey[300]! : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _backgroundPainter,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, _) {
                    final t = Curves.easeInOutCubic.transform(
                      _revealController.value,
                    );

                    final visibleCount =
                    (fullText.length * t).clamp(0, fullText.length.toDouble());
                    final partial = fullText.substring(0, visibleCount.floor());
                    final nextLetterIndex = visibleCount.floor();
                    final nextLetterOpacity =
                    (visibleCount - nextLetterIndex).toDouble();

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          partial,
                          style: _titleTextStyle.copyWith(color: textColor),
                        ),
                        if (nextLetterIndex < fullText.length)
                          Opacity(
                            opacity: nextLetterOpacity,
                            child: Text(
                              fullText[nextLetterIndex],
                              style: _titleTextStyle.copyWith(color: textColor),
                            ),
                          ),
                        AnimatedOpacity(
                          opacity: showCursor ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 3,
                              height: textHeight * 0.70,
                              margin: const EdgeInsets.only(left: 4, top: 18),
                              decoration: BoxDecoration(
                                color: cursorColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _taglineController,
                    curve: Curves.easeIn,
                  ),
                  child: Text(
                    'Smart Billing for Small Business',
                    style: TextStyle(
                      fontSize: 12,
                      color: taglineColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🌟 Denser random background with higher icon opacity
class BillingIconsBackgroundPainter extends CustomPainter {
  final List<_IconInfo> _icons = [];
  final int iconCount = 900; // dense but well-spaced background
  final double minDistance = 30; // minimum spacing between icons

  BillingIconsBackgroundPainter() {
    final random = Random();

    final icons = [
      Icons.receipt_long_outlined,
      Icons.currency_rupee,
      Icons.credit_card_outlined,
      Icons.bar_chart_outlined,
      Icons.account_balance_outlined,
      Icons.insert_chart_outlined,
      Icons.description_outlined,
      Icons.payments_outlined,
      Icons.shopping_bag_outlined,
      Icons.business_outlined,
      Icons.storefront_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.inventory_2_outlined,
      Icons.request_quote_outlined,
      Icons.wallet_outlined,
      Icons.receipt_outlined,
      Icons.calculate_outlined,
      Icons.analytics_outlined,
      Icons.shopping_cart_outlined,
      Icons.inventory_outlined,
    ];

    const double areaSize = 1400;
    int safety = 0;

    while (_icons.length < iconCount && safety < iconCount * 15) {
      safety++;

      final newX = random.nextDouble() * areaSize;
      final newY = random.nextDouble() * areaSize;

      bool tooClose = false;
      for (final icon in _icons) {
        final dx = newX - icon.x;
        final dy = newY - icon.y;
        final distance = sqrt(dx * dx + dy * dy);
        if (distance < minDistance) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        _icons.add(
          _IconInfo(
            icon: icons[random.nextInt(icons.length)],
            x: newX,
            y: newY,
            rotation: (random.nextDouble() - 0.5) * 0.6,
            opacity: 0.10 + (random.nextDouble() * 0.15), // 0.10–0.25 opacity
            size: 14 + random.nextDouble() * 18,
          ),
        );
      }
    }

    debugPrint('Generated ${_icons.length} icons for background.');
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final icon in _icons) {
      if (icon.x > size.width + 100 || icon.y > size.height + 100) continue;

      canvas.save();
      canvas.translate(icon.x, icon.y);
      canvas.rotate(icon.rotation);

      final textPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(icon.icon.codePoint),
          style: TextStyle(
            fontFamily: icon.icon.fontFamily,
            package: icon.icon.fontPackage,
            fontSize: icon.size,
            color: Colors.grey.withOpacity(icon.opacity),
          ),
        )
        ..layout();

      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _IconInfo {
  final IconData icon;
  final double x, y, rotation, opacity, size;
  _IconInfo({
    required this.icon,
    required this.x,
    required this.y,
    required this.rotation,
    required this.opacity,
    required this.size,
  });
}
