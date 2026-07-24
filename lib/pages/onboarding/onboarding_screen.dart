import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../wrapper.dart';

const Color _primary = Color(0xFF1565C0);
const Color _navy = Color(0xFF1E3A5F);
const Color _accent = Color(0xFF2E86AB);
const Color _background = Color(0xFFF8FAFC);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      tag: 'Welcome',
      title: 'Start your internship journey with SkillMatch',
      description:
          'Get a simple overview of how the app works before you sign in and build your profile.',
      accentColor: _primary,
      illustrationAsset: 'assets/images/onboarding/welcome.png',
      points: [
        'Discover internship opportunities faster',
        'See what SkillMatch can do for you',
        'Move through the app with confidence',
      ],
    ),
    _OnboardingPageData(
      tag: 'Upload CV',
      title: 'Drop your CV and let the app read it',
      description:
          'Upload a PDF or DOCX resume and we will extract the important details for matching and profile setup.',
      accentColor: _accent,
      illustrationAsset: 'assets/images/onboarding/upload_cv.png',
      points: [
        'Keep your CV ready in PDF or DOCX format',
        'Let the app analyze your experience instantly',
        'Use the extracted data to complete your profile',
      ],
    ),
    _OnboardingPageData(
      tag: 'Match and Grow',
      title: 'Find internships that fit your skills',
      description:
          'SkillMatch helps you explore opportunities, compare your strengths, and learn what to improve next.',
      accentColor: _primary,
      illustrationAsset: 'assets/images/onboarding/match_and_grow.png',
      points: [
        'See role suggestions based on your profile',
        'Track applications in one place',
        'Spot the skills you should improve next',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_skillmatch_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
    );
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_skillmatch_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
    );
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_navy, _primary, _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: _GlowOrb(
                  color: _accent.withOpacity(0.25),
                  glowColor: _accent.withOpacity(0.65),
                ),
              ),
              Positioned(
                bottom: 110,
                left: -70,
                child: _GlowOrb(
                  color: Colors.white.withOpacity(0.08),
                  glowColor: Colors.white.withOpacity(0.18),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${_pages.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final item = _pages[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: _OnboardingCard(
                            data: item,
                            pageIndex: index + 1,
                            totalPages: _pages.length,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: Column(
                      children: [
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: _pages.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: Colors.white,
                            dotColor: Colors.white.withOpacity(0.28),
                            dotHeight: 10,
                            dotWidth: 10,
                            expansionFactor: 2.6,
                            spacing: 8,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: GestureDetector(
                            onTap: _nextPage,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primary, _accent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primary.withOpacity(0.45),
                                    blurRadius: 28,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final _OnboardingPageData data;
  final int pageIndex;
  final int totalPages;

  const _OnboardingCard({
    required this.data,
    required this.pageIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withOpacity(0.18),
        border: Border.all(
          color: Colors.white.withOpacity(0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.16),
                    Colors.white.withOpacity(0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _PillLabel(text: data.tag),
                    const SizedBox(height: 14),
                    Text(
                      data.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        height: 1.06,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _OnboardingIllustration(
                      assetPath: data.illustrationAsset,
                      accentColor: data.accentColor,
                      pageIndex: pageIndex,
                      totalPages: totalPages,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...data.points.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FeatureRow(
                        accentColor: data.accentColor,
                        text: point,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  final String assetPath;
  final Color accentColor;
  final int pageIndex;
  final int totalPages;

  const _OnboardingIllustration({
    required this.assetPath,
    required this.accentColor,
    required this.pageIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withOpacity(0.14),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final bool compact = constraints.maxHeight < 210;
                    final double iconSize = compact ? 56 : 66;
                    final double topGap = compact ? 10 : 14;
                    final double smallGap = compact ? 4 : 6;
                    final double horizontalPadding = compact ? 14 : 20;
                    final double verticalPadding = compact ? 12 : 20;
                    final double titleFont = compact ? 12.5 : 14;
                    final double subtitleFont = compact ? 11.5 : 13;

                    return Container(
                      color: Colors.white.withOpacity(0.94),
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                pageIndex == 1
                                    ? Icons.explore_rounded
                                    : pageIndex == 2
                                        ? Icons.upload_file_rounded
                                        : Icons.trending_up_rounded,
                                size: iconSize,
                                color: _primary,
                              ),
                              SizedBox(height: topGap),
                              Text(
                                'Add your onboarding image here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: titleFont,
                                ),
                              ),
                              SizedBox(height: smallGap),
                              Text(
                                'Use $assetPath for this page.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _navy.withOpacity(0.62),
                                  fontSize: subtitleFont,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '0$pageIndex / 0$totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _FeatureRow extends StatelessWidget {
  final Color accentColor;
  final String text;

  const _FeatureRow({required this.accentColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PillLabel extends StatelessWidget {
  final String text;

  const _PillLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final Color glowColor;

  const _GlowOrb({
    required this.color,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 45,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final String tag;
  final String title;
  final String description;
  final Color accentColor;
  final String illustrationAsset;
  final List<String> points;

  const _OnboardingPageData({
    required this.tag,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.illustrationAsset,
    required this.points,
  });
}