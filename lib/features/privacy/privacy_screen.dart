import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Privacy & Data Security',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Callout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigoAccent.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero Tracking & On-Device Control',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Aura AI has zero analytics, zero user accounts, and zero cloud database tracking.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),
            const SizedBox(height: 24),

            // Section 1: Local Storage Architecture
            _buildSectionHeader('1. LOCAL STORAGE ARCHITECTURE'),
            const SizedBox(height: 10),
            _buildCard([
              _buildFeatureTile(
                icon: Icons.storage_rounded,
                iconColor: AppColors.indigoAccent,
                title: 'Local SQLite Database',
                description: 'All conversations, personal memories, custom personas, prompt templates, and local file attachments are saved exclusively in local SQLite database files on your device.',
              ),
              const Divider(color: AppColors.surfaceBorder),
              _buildFeatureTile(
                icon: Icons.no_accounts_rounded,
                iconColor: AppColors.roseAccent,
                title: 'No Cloud Accounts or Telemetry',
                description: 'There are no background analytics, crash report uploaders, or tracking beacons built into Aura AI.',
              ),
            ]).animate().fadeIn(delay: 50.ms, duration: 250.ms),
            const SizedBox(height: 24),

            // Section 2: Cloud AI Data Transmission
            _buildSectionHeader('2. CLOUD AI TRANSMISSION DISCLOSURE'),
            const SizedBox(height: 10),
            _buildCard([
              _buildFeatureTile(
                icon: Icons.cloud_upload_outlined,
                iconColor: AppColors.amberAccent,
                title: 'Data Sent to AI Providers',
                description: 'When you send a chat message, internet access is required to transmit your prompt, document text, active persona system prompt, and active memories to your selected cloud provider.',
              ),
              const Divider(color: AppColors.surfaceBorder),
              _buildFeatureTile(
                icon: Icons.dns_rounded,
                iconColor: AppColors.groqBrand,
                title: 'Groq Cloud Provider Endpoint',
                description: 'Endpoint: api.groq.com/openai/v1/chat/completions\nAuth: Your personal GSK API Key via hardware KeyStore.',
              ),
              const Divider(color: AppColors.surfaceBorder),
              _buildFeatureTile(
                icon: Icons.memory_rounded,
                iconColor: AppColors.nvidiaBrand,
                title: 'NVIDIA NIM Endpoint',
                description: 'Endpoint: integrate.api.nvidia.com/v1/chat/completions\nAuth: Your personal NVAPI Key via hardware KeyStore.',
              ),
            ]).animate().fadeIn(delay: 100.ms, duration: 250.ms),
            const SizedBox(height: 24),

            // Section 3: Hardware Encryption
            _buildSectionHeader('3. API KEY SECURITY'),
            const SizedBox(height: 10),
            _buildCard([
              _buildFeatureTile(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.emeraldAccent,
                title: 'Android KeyStore Hardware Storage',
                description: 'Your API keys are encrypted using Android KeyStore hardware cryptography (RSA/AES-256). Secrets are never logged, hardcoded, or stored unencrypted.',
              ),
            ]).animate().fadeIn(delay: 150.ms, duration: 250.ms),
            const SizedBox(height: 24),

            // Section 4: Permissions Audit
            _buildSectionHeader('4. ANDROID PERMISSIONS AUDIT'),
            const SizedBox(height: 10),
            _buildCard([
              _buildPermissionTile(
                'INTERNET',
                'Required to contact Groq & NVIDIA NIM endpoints',
              ),
              _buildPermissionTile(
                'USE_BIOMETRIC',
                'Required for optional biometric app lock',
              ),
              _buildPermissionTile(
                'USE_FINGERPRINT',
                'Legacy hardware fingerprint authentication',
              ),
            ]).animate().fadeIn(delay: 200.ms, duration: 250.ms),
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

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(String name, String usage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.indigoAccent,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              usage,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
