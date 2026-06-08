class ComputerAction {
  final String id;
  final String sessionId;
  final String? cycleId;
  final String? actionType;
  final String? description;
  final String? status;
  final String? riskDecision;
  final String? error;
  final List<String>? screenshotIds;
  final DateTime? executedAt;
  final Map<String, dynamic>? metadata;

  const ComputerAction({
    required this.id,
    required this.sessionId,
    this.cycleId,
    this.actionType,
    this.description,
    this.status,
    this.riskDecision,
    this.error,
    this.screenshotIds,
    this.executedAt,
    this.metadata,
  });

  factory ComputerAction.fromJson(Map<String, dynamic> json) => ComputerAction(
        id: json['id'] as String,
        sessionId: json['session_id'] as String? ?? '',
        cycleId: json['cycle_id'] as String?,
        actionType: json['action_type'] as String?,
        description: json['description'] as String?,
        status: json['status'] as String?,
        riskDecision: json['risk_decision'] as String?,
        error: json['error'] as String?,
        screenshotIds: (json['screenshot_ids'] as List?)?.cast<String>(),
        executedAt: json['executed_at'] != null
            ? DateTime.tryParse(json['executed_at'] as String)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}
