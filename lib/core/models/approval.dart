class Approval {
  final String id;
  final String sessionId;
  final String? cycleId;
  final String requestedAction;
  final String? reason;
  final String? riskCategory;
  final String? requestedBy;
  final String status;
  final String? comment;
  final DateTime? requestedAt;
  final DateTime? resolvedAt;

  const Approval({
    required this.id,
    required this.sessionId,
    required this.requestedAction,
    required this.status,
    this.cycleId,
    this.reason,
    this.riskCategory,
    this.requestedBy,
    this.comment,
    this.requestedAt,
    this.resolvedAt,
  });

  factory Approval.fromJson(Map<String, dynamic> json) => Approval(
        id: json['id'] as String,
        sessionId: json['session_id'] as String? ?? '',
        cycleId: json['cycle_id'] as String?,
        requestedAction: json['requested_action'] as String? ?? 'Unknown action',
        reason: json['reason'] as String?,
        riskCategory: json['risk_category'] as String?,
        requestedBy: json['requested_by'] as String?,
        status: json['status'] as String? ?? 'pending',
        comment: json['comment'] as String?,
        requestedAt: json['requested_at'] != null
            ? DateTime.tryParse(json['requested_at'] as String)
            : null,
        resolvedAt: json['resolved_at'] != null
            ? DateTime.tryParse(json['resolved_at'] as String)
            : null,
      );

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
