import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

// ── Splash Screen ───────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _pulse;
  late final AnimationController _particles;

  // Staggered animations
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _pillsFade;
  late final Animation<Offset> _pillsSlide;
  late final Animation<double> _ctaFade;
  late final Animation<Offset> _ctaSlide;
  late final Animation<double> _glowPulse;

  static const _totalMs = 4500;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Logo: 0–600ms
    _logoFade = _curved(0.0, 0.13, Curves.easeOut);
    _logoSlide = _slide(0.0, 0.13, begin: const Offset(0, 0.3));

    // Tagline: 400–900ms
    _taglineFade = _curved(0.09, 0.22, Curves.easeOut);
    _taglineSlide = _slide(0.09, 0.22, begin: const Offset(0, 0.4));

    // Pills: 700–1200ms
    _pillsFade = _curved(0.16, 0.30, Curves.easeOut);
    _pillsSlide = _slide(0.16, 0.30, begin: const Offset(0, 0.3));

    // CTA: 1000–1500ms
    _ctaFade = _curved(0.22, 0.38, Curves.easeOut);
    _ctaSlide = _slide(0.22, 0.38, begin: const Offset(0, 0.4));

    // Glow pulse
    _glowPulse = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _master.forward();
  }

  Animation<double> _curved(double start, double end, Curve curve) =>
      CurvedAnimation(
        parent: _master,
        curve: Interval(start, end, curve: curve),
      );

  Animation<Offset> _slide(double start, double end, {required Offset begin}) =>
      Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(
          parent: _master,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _master.dispose();
    _pulse.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated particle field
          AnimatedBuilder(
            animation: _particles,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(_particles.value),
            ),
          ),

          // Radial glow behind logo
          AnimatedBuilder(
            animation: _glowPulse,
            builder: (_, __) => Center(
              child: Container(
                width: size.width * 1.1,
                height: size.width * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(_glowPulse.value * 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 52),
                      child: Image.asset(
                        'assets/images/logo-white.png',
                        width: size.width * 0.62,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tagline
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        children: [
                          Text(
                            'Study Smarter. Score Higher.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'AI-powered exam prep for students worldwide.\nFree to start. No credit card needed.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              height: 1.6,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Feature pills
                FadeTransition(
                  opacity: _pillsFade,
                  child: SlideTransition(
                    position: _pillsSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _FeaturePill(
                            icon: Icons.auto_awesome_rounded,
                            label: 'AI Tutor',
                          ),
                          _FeaturePill(
                            icon: Icons.public_rounded,
                            label: '100+ Exams',
                          ),
                          _FeaturePill(
                            icon: Icons.wifi_off_rounded,
                            label: 'Works Offline',
                          ),
                          _FeaturePill(
                            icon: Icons.translate_rounded,
                            label: '50+ Languages',
                          ),
                          _FeaturePill(
                            icon: Icons.emoji_events_rounded,
                            label: 'Gamified XP',
                          ),
                          _FeaturePill(
                            icon: Icons.lock_open_rounded,
                            label: 'Free Forever',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // CTA
                FadeTransition(
                  opacity: _ctaFade,
                  child: SlideTransition(
                    position: _ctaSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _GlowButton(
                        label: 'Get Started — It\'s Free',
                        onTap: () => context.go('/onboarding/carousel'),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glow CTA Button ─────────────────────────────────────────────────────────

class _GlowButton extends StatefulWidget {
  const _GlowButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Get Started — It\'s Free',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Feature Pill ─────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(100),
        color: Colors.white.withOpacity(0.07),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Particle Painter ──────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.progress);
  final double progress;

  static final _rng = math.Random(42);
  static final _particles = List.generate(40, (i) => _Particle(_rng));

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress + p.offset) % 1.0;
      final x = p.x * size.width;
      final y = size.height - (t * (size.height + 40)) + 20;
      final opacity = math.sin(t * math.pi) * p.alpha;
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  _Particle(math.Random rng)
    : x = rng.nextDouble(),
      offset = rng.nextDouble(),
      radius = rng.nextDouble() * 1.8 + 0.4,
      alpha = rng.nextDouble() * 0.18 + 0.04;

  final double x;
  final double offset;
  final double radius;
  final double alpha;
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
