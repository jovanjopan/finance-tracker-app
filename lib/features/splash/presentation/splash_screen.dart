import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../accounts/domain/account_repository.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import 'placeholder_home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumSplashDuration = Duration(milliseconds: 1500);

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool? _hasAccounts;
  bool _initializationStarted = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: _minimumSplashDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    );

    _entryController.forward();
    _startInitialization();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    if (_initializationStarted) {
      return;
    }
    _initializationStarted = true;

    final accountRepository = ref.read(accountRepositoryProvider);

    final initializationFuture = _resolveHasAccounts(accountRepository);

    await Future.wait<void>([
      Future<void>.delayed(_minimumSplashDuration),
      initializationFuture,
    ]);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _hasAccounts == true
            ? const PlaceholderHomeScreen()
            : const OnboardingScreen(),
      ),
    );
  }

  Future<void> _resolveHasAccounts(AccountRepository accountRepository) async {
    try {
      final accounts = await accountRepository.watchAllAccounts().first;
      _hasAccounts = accounts.isNotEmpty;
      debugPrint('[Splash] account check completed: hasAccounts=$_hasAccounts');
    } catch (error, stackTrace) {
      _hasAccounts = false;
      debugPrint('[Splash] account check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'koinku',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _entryController,
                  builder: (context, child) {
                    final value = _entryController.value;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final phase = index / 3;
                        final opacity = 0.35 +
                            0.65 *
                                ((math.sin((value + phase) * math.pi * 2) + 1) /
                                    2);

                        return Padding(
                          padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 8,
                              height: 8,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}