import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _groqKeyController;
  late TextEditingController _nvidiaKeyController;
  bool _obscureGroq = true;
  bool _obscureNvidia = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _groqKeyController = TextEditingController(text: settings.groqApiKey);
    _nvidiaKeyController = TextEditingController(text: settings.nvidiaApiKey);
  }

  @override
  void dispose() {
    _groqKeyController.dispose();
    _nvidiaKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSaveGroqKey() async {
    final key = _groqKeyController.text.trim();
    if (key.isEmpty) {
      await ref.read(settingsProvider.notifier).removeGroqApiKey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Groq API Key removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final isValid = await ref
        .read(settingsProvider.notifier)
        .saveAndValidateGroqApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isValid
                ? 'Groq API Key validated and saved securely!'
                : 'Invalid Groq API Key. Please verify your key on groq.com',
          ),
          backgroundColor: isValid
              ? AppColors.emeraldAccent
              : AppColors.roseAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _validateAndSaveNvidiaKey() async {
    final key = _nvidiaKeyController.text.trim();
    if (key.isEmpty) {
      await ref.read(settingsProvider.notifier).removeNvidiaApiKey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NVIDIA API Key removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final isValid = await ref
        .read(settingsProvider.notifier)
        .saveAndValidateNvidiaApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isValid ? 'NVIDIA API Key validated and saved securely!' : 'Invalid NVIDIA API Key. Please verify your key on nvidia.com',
          ),
          backgroundColor: isValid
              ? AppColors.emeraldAccent
              : AppColors.roseAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Notice Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.indigoAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.indigoAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.indigoAccent,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Privacy & Hardware Security',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'API keys are stored encrypted on-device. Messages sent to Groq or NVIDIA NIM leave the device to be processed by your chosen provider.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),
            const SizedBox(height: 20),

            // Section Header
            _buildSectionHeader('AI PROVIDER CONFIGURATION'),
            const SizedBox(height: 12),

            // Groq Settings Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.groqBrand.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.groqBrand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Groq Cloud Provider',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Ultra-fast LPU inference endpoints',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: settings.isGroqKeyValid
                              ? AppColors.emeraldAccent.withValues(alpha: 0.15)
                              : AppColors.roseAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          settings.isGroqKeyValid ? 'Verified' : 'Key Required',
                          style: TextStyle(
                            color: settings.isGroqKeyValid
                                ? AppColors.emeraldAccent
                                : AppColors.roseAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // API Key Input
                  const Text(
                    'API Key (Groq Cloud)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _groqKeyController,
                    obscureText: _obscureGroq,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'gsk_...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureGroq
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          setState(() => _obscureGroq = !_obscureGroq);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.indigoAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: settings.isValidatingGroqKey
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            settings.isValidatingGroqKey
                                ? 'Validating...'
                                : 'Validate & Save Key',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: settings.isValidatingGroqKey
                              ? null
                              : _validateAndSaveGroqKey,
                        ),
                      ),
                      if (_groqKeyController.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.roseAccent,
                            size: 20,
                          ),
                          tooltip: 'Remove Key',
                          onPressed: () async {
                            _groqKeyController.clear();
                            await ref
                                .read(settingsProvider.notifier)
                                .removeGroqApiKey();
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Default Model Selector
                  const Text(
                    'Default Model',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: settings.groqDefaultModel,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'openai/gpt-oss-120b',
                            child: Text('GPT OSS 120B (Groq Cloud)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .setGroqDefaultModel(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 16),

            // NVIDIA Settings Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.nvidiaBrand.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.memory_rounded,
                          color: AppColors.nvidiaBrand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NVIDIA NIM Provider',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'High-throughput cloud GPU infrastructure',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: settings.isNvidiaKeyValid
                              ? AppColors.emeraldAccent.withValues(alpha: 0.15)
                              : AppColors.roseAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          settings.isNvidiaKeyValid
                              ? 'Verified'
                              : 'Key Required',
                          style: TextStyle(
                            color: settings.isNvidiaKeyValid
                                ? AppColors.emeraldAccent
                                : AppColors.roseAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // API Key Input
                  const Text(
                    'API Key (NVIDIA NIM)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nvidiaKeyController,
                    obscureText: _obscureNvidia,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'nvapi-...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNvidia
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          setState(() => _obscureNvidia = !_obscureNvidia);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.nvidiaBrand,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: settings.isValidatingNvidiaKey
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            settings.isValidatingNvidiaKey
                                ? 'Validating...'
                                : 'Validate & Save Key',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: settings.isValidatingNvidiaKey
                              ? null
                              : _validateAndSaveNvidiaKey,
                        ),
                      ),
                      if (_nvidiaKeyController.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.roseAccent,
                            size: 20,
                          ),
                          tooltip: 'Remove Key',
                          onPressed: () async {
                            _nvidiaKeyController.clear();
                            await ref
                                .read(settingsProvider.notifier)
                                .removeNvidiaApiKey();
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Default Model Selector
                  const Text(
                    'Default Model',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: settings.nvidiaDefaultModel,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'nvidia/nemotron-3-ultra-550b-a55b',
                            child: Text('Nemotron 3 Ultra 550B (NVIDIA NIM)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .setNvidiaDefaultModel(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            const SizedBox(height: 28),

            // Personalization & Prompts Section
            _buildSectionHeader('PERSONALIZATION & PROMPTS'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.psychology_outlined,
                      color: AppColors.indigoAccent,
                    ),
                    title: const Text(
                      'Personal Memory',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    subtitle: const Text(
                      'View, edit, and toggle saved memory facts',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => context.push('/memory'),
                  ),
                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.person_pin_rounded,
                      color: AppColors.violetAccent,
                    ),
                    title: const Text(
                      'Custom AI Personas',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    subtitle: const Text(
                      'Create and select AI system instructions',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => context.push('/personas'),
                  ),
                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.bookmark_outline_rounded,
                      color: AppColors.cyanAccent,
                    ),
                    title: const Text(
                      'Prompt Library',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    subtitle: const Text(
                      'Save and organize reusable prompt templates',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => context.push('/prompts'),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
            const SizedBox(height: 28),

            // App Security & Privacy Section
            _buildSectionHeader('SECURITY & PRIVACY TRANSPARENCY'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.fingerprint_rounded,
                      color: AppColors.emeraldAccent,
                    ),
                    title: const Text(
                      'Biometric App Lock',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    subtitle: const Text(
                      'Require fingerprint or face ID to unlock app',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: ref.watch(isBiometricLockEnabledProvider),
                      activeTrackColor: AppColors.emeraldAccent,
                      onChanged: (val) async {
                        if (val) {
                          final bioService = ref.read(biometricServiceProvider);
                          final supported = await bioService
                              .isDeviceSupported();
                          if (!supported) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Biometric hardware authentication is not supported or enrolled on this device.',
                                  ),
                                  backgroundColor: AppColors.roseAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }
                          final authSuccess = await bioService.authenticate(
                            reason: 'Authenticate to enable biometric app lock',
                          );
                          if (authSuccess) {
                            await ref
                                .read(isBiometricLockEnabledProvider.notifier)
                                .setEnabled(true);
                          }
                        } else {
                          await ref
                              .read(isBiometricLockEnabledProvider.notifier)
                              .setEnabled(false);
                          ref
                              .read(isAppUnlockedProvider.notifier)
                              .setUnlocked(true);
                        }
                      },
                    ),
                  ),
                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.indigoAccent,
                    ),
                    title: const Text(
                      'Privacy & Security Review',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    subtitle: const Text(
                      'Full disclosure on on-device data vs provider transmission',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => context.push('/privacy'),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 180.ms, duration: 300.ms),
            const SizedBox(height: 28),

            // Theme Settings
            _buildSectionHeader('APPEARANCE & THEME'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: AppColors.indigoAccent,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme Mode',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          Text(
                            'Dark Charcoal (Default)',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: settings.themeMode,
                    dropdownColor: AppColors.surfaceLight,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'dark', child: Text('Dark Mode')),
                      DropdownMenuItem(
                        value: 'light',
                        child: Text('Light Mode'),
                      ),
                      DropdownMenuItem(
                        value: 'system',
                        child: Text('System Default'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).setThemeMode(val);
                      }
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 28),

            // About Section
            _buildSectionHeader('ABOUT AURA AI'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.indigoAccent.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aura AI Assistant',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Phase 4 — Groq & NVIDIA NIM Multi-Provider AI System',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceBorder),
                  const SizedBox(height: 12),
                  _buildSpecRow('Providers', 'Groq LPU + NVIDIA NIM Cloud'),
                  const SizedBox(height: 8),
                  _buildSpecRow(
                    'Key Encryption',
                    'Hardware KeyStore / KeyChain',
                  ),
                  const SizedBox(height: 8),
                  _buildSpecRow('Database Engine', 'SQLite + Drift'),
                  const SizedBox(height: 8),
                  _buildSpecRow('Framework', 'Flutter 3.47 + Riverpod 3.4'),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
