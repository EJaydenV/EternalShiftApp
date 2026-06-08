class AppScreenshot {
  final String id;
  final String sessionId;
  final String? cycleId;
  final String? scenario;
  final String? url;
  final String? thumbnailUrl;
  final String? description;
  final DateTime? capturedAt;

  const AppScreenshot({
    required this.id,
    required this.sessionId,
    this.cycleId,
    this.scenario,
    this.url,
    this.thumbnailUrl,
    this.description,
    this.capturedAt,
  });

  factory AppScreenshot.fromJson(Map<String, dynamic> json) => AppScreenshot(
        id: json['id'] as String,
        sessionId: json['session_id'] as String? ?? '',
        cycleId: json['cycle_id'] as String?,
        scenario: json['scenario'] as String?,
        url: json['url'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        description: json['description'] as String?,
        capturedAt: json['captured_at'] != null
            ? DateTime.tryParse(json['captured_at'] as String)
            : null,
      );
}
