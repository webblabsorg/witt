import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:witt_ui/witt_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      icon: Icons.auto_awesome_rounded,
      iconColor: WittColors.primary,
      title: 'AI-Powered Test Prep',
      subtitle:
          'Adaptive questions, instant explanations, and a personal AI tutor — all in one app.',
    ),
    _Slide(
      icon: Icons.public_rounded,
      iconColor: WittColors.accent,
      title: '100+ Exams Worldwide',
      subtitle:
          'SAT, GRE, WAEC, JAMB, IELTS and more — covering students across every region.',
    ),
    _Slide(
      icon: Icons.wifi_off_rounded,
      iconColor: WittColors.success,
      title: 'Learn Anywhere, Even Offline',
      subtitle:
          'Download content packs and study without internet — perfect for low-connectivity areas.',
    ),
    _Slide(
      icon: Icons.lock_open_rounded,
      iconColor: WittColors.secondary,
      title: 'Free to Start',
      subtitle:
          'Get started for free with no credit card required. Upgrade when you\'re ready.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_currentPage < _slides.length - 1) {
        _controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startAutoAdvance();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button
            Positioned(
              top: WittSpacing.lg,
              right: WittSpacing.lg,
              child: TextButton(
                onPressed: () => context.go('/onboarding/language'),
                child: Text(
                  'Skip',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isDark
                        ? WittColors.textSecondaryDark
                        : WittColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Page content
            PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return _SlideView(slide: _slides[index]);
              },
            ),

            // Bottom controls
            Positioned(
              left: 0,
              right: 0,
              bottom: WittSpacing.xxxl,
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _slides.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: WittColors.primary,
                      dotColor: isDark
                          ? WittColors.outlineDark
                          : WittColors.outlineVariant,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.xxl),
                  if (_currentPage == _slides.length - 1)
                    Padding(
                      padding: WittSpacing.pagePadding,
                      child: WittButton(
                        label: 'Get Started',
                        onPressed: () => context.go('/onboarding/language'),
                        isFullWidth: true,
                        size: WittButtonSize.lg,
                        gradient: WittColors.primaryGradient,
                      ),
                    )
                  else
                    Padding(
                      padding: WittSpacing.pagePadding,
                      child: WittButton(
                        label: 'Next',
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        isFullWidth: true,
                        size: WittButtonSize.lg,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.xxxl,
        WittSpacing.massive,
        WittSpacing.xxxl,
        160,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.iconColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 60, color: slide.iconColor),
          ),
          const SizedBox(height: WittSpacing.xxxl),
          Text(
            slide.title,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WittSpacing.lg),
          Text(
            slide.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? WittColors.textSecondaryDark
                  : WittColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
