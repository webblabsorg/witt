import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

/// Boot/loading splash — black background, white witt logo, centered.
/// Auto-advances to the onboarding carousel after 2.5 s.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      context.go('/onboarding/carousel');
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Image.asset(
              'assets/images/logo-white.png',
              width: MediaQuery.of(context).size.width * 0.65,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// Onboarding carousel — shown after the boot splash.
class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() =>
      _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      icon: Icons.auto_awesome_rounded,
      iconColor: WittColors.accent,
      title: 'AI-Powered Test Prep',
      subtitle:
          'Adaptive questions, instant explanations, and a personal AI tutor — all in one app.',
    ),
    _Slide(
      icon: Icons.public_rounded,
      iconColor: WittColors.success,
      title: '100+ Exams Worldwide',
      subtitle:
          'SAT, GRE, WAEC, JAMB, IELTS and more — covering students across every region.',
    ),
    _Slide(
      icon: Icons.wifi_off_rounded,
      iconColor: WittColors.secondary,
      title: 'Learn Anywhere, Even Offline',
      subtitle:
          'Download content packs and study without internet — perfect for low-connectivity areas.',
    ),
    _Slide(
      icon: Icons.lock_open_rounded,
      iconColor: WittColors.primary,
      title: 'Free to Start',
      subtitle:
          'Get started for free with no credit card required. Upgrade when you\'re ready.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
                    color: WittColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Page content
            PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _slides.length,
              itemBuilder: (_, index) => _SlideView(slide: _slides[index]),
            ),

            // Bottom controls
            Positioned(
              left: 0,
              right: 0,
              bottom: WittSpacing.xxxl,
              child: Column(
                children: [
                  _DotIndicator(count: _slides.length, current: _currentPage),
                  const SizedBox(height: WittSpacing.xxl),
                  Padding(
                    padding: WittSpacing.pagePadding,
                    child: _currentPage == _slides.length - 1
                        ? WittButton(
                            label: 'Get Started',
                            onPressed: () => context.go('/onboarding/language'),
                            isFullWidth: true,
                            size: WittButtonSize.lg,
                          )
                        : WittButton(
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

// ── Helpers ────────────────────────────────────────────────────────────────

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
              color: slide.iconColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 60, color: slide.iconColor),
          ),
          const SizedBox(height: WittSpacing.xxxl),
          Text(
            slide.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: WittColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WittSpacing.lg),
          Text(
            slide.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: WittColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? WittColors.primary : WittColors.outline,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
