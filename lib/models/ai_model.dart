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
      id: 'openai/gpt-oss-120b',
      name: 'Groq — GPT OSS 120B',
      provider: AIProvider.groq,
      description: 'Ultra-fast LPU inference with 120B open architecture model on Groq Cloud',
      badgeLabel: 'Ultra-Fast',
      badgeColor: AppColors.groqBrand,
      isPopular: true,
    ),
    AIModel(
      id: 'nvidia/nemotron-3-ultra-550b-a55b',
      name: 'NVIDIA — Nemotron 3 Ultra 550B',
      provider: AIProvider.nvidia,
      description: 'Massive 550B parameter deep reasoning model hosted on NVIDIA NIM cloud infrastructure',
      badgeLabel: 'Deep Reasoning',
      badgeColor: AppColors.nvidiaBrand,
      isPopular: true,
    ),
  ];

  static AIModel get defaultModel => availableModels.first;
}
