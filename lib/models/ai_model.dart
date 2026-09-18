import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum AIProvider { groq, nvidia }

class AIModel {
  final String id;
  final String name;
  final AIProvider provider;
  final String description;
  final String badgeLabel;
  final Color badgeColor;
  final bool isPopular;
  final bool supportsVision;

  const AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.badgeLabel,
    required this.badgeColor,
    this.isPopular = false,
    this.supportsVision = false,
  });

  String get providerDisplayName =>
      provider == AIProvider.groq ? 'Groq' : 'NVIDIA';

  static const List<AIModel> availableModels = [
    AIModel(
      id: 'groq-llama-3.3-70b',
      name: 'Groq — Llama 3.3 70B',
      provider: AIProvider.groq,
      description:
          'Ultra-fast LPU inference with state-of-the-art general intelligence',
      badgeLabel: 'Ultra-Fast',
      badgeColor: AppColors.groqBrand,
      isPopular: true,
    ),
    AIModel(
      id: 'nvidia-llama-3.1-405b',
      name: 'NVIDIA — Llama 3.1 405B',
      provider: AIProvider.nvidia,
      description: 'Massive parameter open weights model hosted on NVIDIA NIM cloud infrastructure',
      badgeLabel: 'Deep Reasoning',
      badgeColor: AppColors.nvidiaBrand,
      isPopular: true,
    ),
    AIModel(
      id: 'groq-llama-3.2-11b-vision',
      name: 'Groq — Llama 3.2 11B Vision',
      provider: AIProvider.groq,
      description:
          'Multimodal vision model for analyzing images, mockups, and charts',
      badgeLabel: 'Vision Capable',
      badgeColor: AppColors.groqBrand,
      supportsVision: true,
    ),
    AIModel(
      id: 'nvidia-llama-3.2-11b-vision',
      name: 'NVIDIA — Llama 3.2 11B Vision',
      provider: AIProvider.nvidia,
      description:
          'High performance multimodal model hosted on NVIDIA NIM cloud',
      badgeLabel: 'Vision Capable',
      badgeColor: AppColors.nvidiaBrand,
      supportsVision: true,
    ),
    AIModel(
      id: 'groq-mixtral-8x7b',
      name: 'Groq — Mixtral 8x7B',
      provider: AIProvider.groq,
      description: 'High performance Mixture-of-Experts model for coding and multilingual tasks',
      badgeLabel: 'MoE Architecture',
      badgeColor: AppColors.groqBrand,
    ),
    AIModel(
      id: 'nvidia-nemotron-70b',
      name: 'NVIDIA — Nemotron 70B',
      provider: AIProvider.nvidia,
      description: 'Custom fine-tuned Llama model optimized for high accuracy & helpfulness',
      badgeLabel: 'High Accuracy',
      badgeColor: AppColors.nvidiaBrand,
    ),
  ];

  static AIModel get defaultModel => availableModels.first;
}
