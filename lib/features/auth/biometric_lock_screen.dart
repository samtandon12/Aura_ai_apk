import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricLockScreen({super.key, required this.child});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAuthenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final isEnabled = ref.read(isBiometricLockEnabledProvider);
      if (isEnabled) {
        ref.read(isAppUnlockedProvider.notifier).setUnlocked(false);
      }
    } else if (state == AppLifecycleState.resumed) {
      final isEnabled = ref.read(isBiometricLockEnabledProvider);
      final isUnlocked = ref.read(isAppUnlockedProvider);
      if (isEnabled && !isUnlocked) {
        _checkAndAuthenticate();
      }
    }
  }

  Future<void> _checkAndAuthenticate() async {
    final isEnabled = ref.read(isBiometricLockEnabledProvider);
    if (!isEnabled) return;

    final biometricService = ref.read(biometricServiceProvider);
    final authenticated = await biometricService.authenticate();
    if (authenticated) {
      ref.read(isAppUnlockedProvider.notifier).setUnlocked(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(isBiometricLockEnabledProvider);
    final isUnlocked = ref.watch(isAppUnlockedProvider);

    if (!isEnabled || isUnlocked) {
      return widget.child;
    }

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigoAccent.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOut),
                const SizedBox(height: 24),
                const Text(
                  'Aura AI Locked',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Biometric security enabled. Please authenticate to access your chats, memories, and settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigoAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(220, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.fingerprint_rounded, size: 22),
                  label: const Text(
                    'Unlock Aura AI',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _checkAndAuthenticate,
                ).animate().fadeIn(delay: 150.ms, duration: 250.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
