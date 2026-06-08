class ProviderStatus {
  final String name;
  final bool available;
  final String? mode;
  final String? model;
  final String? error;
  final bool? isSelected;
  final int? timeoutSeconds;

  const ProviderStatus({
    required this.name,
    required this.available,
    this.mode,
    this.model,
    this.error,
    this.isSelected,
    this.timeoutSeconds,
  });

  factory ProviderStatus.fromJson(Map<String, dynamic> json) => ProviderStatus(
        name: json['name'] as String? ?? json['provider'] as String? ?? 'unknown',
        available: json['available'] as bool? ?? false,
        mode: json['mode'] as String?,
        model: json['model'] as String?,
        error: json['error'] as String?,
        isSelected: json['is_selected'] as bool?,
        timeoutSeconds: json['timeout_seconds'] as int?,
      );

  static const modeMock = 'mock';
  static const modeClaudeCli = 'claude_cli';
  static const modeAnthropicApi = 'anthropic_api';

  String get displayName {
    switch (name) {
      case 'claude_cli':
        return 'Claude CLI';
      case 'anthropic_api':
        return 'Anthropic API';
      case 'mock':
        return 'Mock Provider';
      default:
        return name;
    }
  }
}
