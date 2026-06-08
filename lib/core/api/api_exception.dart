class ApiException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  factory ApiException.fromMap(Map<String, dynamic> error, {int? statusCode}) {
    return ApiException(
      code: error['code'] as String? ?? 'UNKNOWN_ERROR',
      message: error['message'] as String? ?? 'An unknown error occurred.',
      details: error['details'] as Map<String, dynamic>?,
      statusCode: statusCode,
    );
  }

  factory ApiException.unauthorized() => const ApiException(
        code: 'UNAUTHORIZED',
        message: 'Invalid or missing API token. Please check your settings.',
        statusCode: 401,
      );

  factory ApiException.serverUnavailable(String url) => ApiException(
        code: 'SERVER_UNAVAILABLE',
        message: 'Cannot reach the Eternal Shift server at $url.',
      );

  factory ApiException.unknown(Object e) => ApiException(
        code: 'CLIENT_ERROR',
        message: e.toString(),
      );

  String get userMessage {
    switch (code) {
      case 'UNAUTHORIZED':
        return 'Authentication failed. Check your API token in Settings.';
      case 'SERVER_UNAVAILABLE':
        return message;
      case 'SESSION_BLOCKED':
        return 'Session is blocked and waiting for your input.';
      case 'PROVIDER_UNAVAILABLE':
        return 'The selected AI provider is unavailable. Check provider settings.';
      case 'TOKEN_BUDGET_EXCEEDED':
        return 'Token budget exceeded. Review token usage in the Tokens screen.';
      case 'RISK_POLICY_BLOCKED':
        return 'Action blocked by safety policy. Review in Approvals.';
      case 'INTERNAL_ERROR':
        return 'Server error. Try again or check the server logs.';
      default:
        return message;
    }
  }

  @override
  String toString() => 'ApiException($code): $message';
}
