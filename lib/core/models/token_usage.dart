class TokenUsage {
  final int? inputTokens;
  final int? outputTokens;
  final int? cacheReadTokens;
  final int? cacheWriteTokens;
  final int? totalTokens;
  final double? estimatedCostUsd;
  final String? provider;
  final String? model;
  final bool? isEstimated;

  const TokenUsage({
    this.inputTokens,
    this.outputTokens,
    this.cacheReadTokens,
    this.cacheWriteTokens,
    this.totalTokens,
    this.estimatedCostUsd,
    this.provider,
    this.model,
    this.isEstimated,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) => TokenUsage(
        inputTokens: json['input_tokens'] as int?,
        outputTokens: json['output_tokens'] as int?,
        cacheReadTokens: json['cache_read_tokens'] as int?,
        cacheWriteTokens: json['cache_write_tokens'] as int?,
        totalTokens: json['total_tokens'] as int?,
        estimatedCostUsd: (json['estimated_cost_usd'] as num?)?.toDouble(),
        provider: json['provider'] as String?,
        model: json['model'] as String?,
        isEstimated: json['is_estimated'] as bool?,
      );

  int get total => totalTokens ?? ((inputTokens ?? 0) + (outputTokens ?? 0));
  double get cacheHitRate {
    final total = (cacheReadTokens ?? 0) + (inputTokens ?? 0);
    if (total == 0) return 0;
    return (cacheReadTokens ?? 0) / total;
  }
}

class TokenSummary {
  final TokenUsage? today;
  final TokenUsage? total;
  final Map<String, TokenUsage>? bySession;
  final Map<String, TokenUsage>? byProvider;
  final double? efficiencySavings;

  const TokenSummary({
    this.today,
    this.total,
    this.bySession,
    this.byProvider,
    this.efficiencySavings,
  });

  factory TokenSummary.fromJson(Map<String, dynamic> json) => TokenSummary(
        today: json['today'] != null
            ? TokenUsage.fromJson(json['today'] as Map<String, dynamic>)
            : null,
        total: json['total'] != null
            ? TokenUsage.fromJson(json['total'] as Map<String, dynamic>)
            : null,
        efficiencySavings: (json['efficiency_savings'] as num?)?.toDouble(),
      );
}
