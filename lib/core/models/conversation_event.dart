class ConversationEvent {
  final String id;
  final String sessionId;
  final String? cycleId;
  final String role;
  final String? type;
  final String? title;
  final String content;
  final String? status;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  const ConversationEvent({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.cycleId,
    this.type,
    this.title,
    this.status,
    this.timestamp,
    this.metadata,
  });

  factory ConversationEvent.fromJson(Map<String, dynamic> json) => ConversationEvent(
        id: json['id'] as String? ?? '',
        sessionId: json['session_id'] as String? ?? '',
        cycleId: json['cycle_id'] as String?,
        role: json['role'] as String? ?? 'system',
        type: json['type'] as String?,
        title: json['title'] as String?,
        content: json['content'] as String? ?? '',
        status: json['status'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  static const roleWorker = 'worker';
  static const roleReviewer = 'reviewer';
  static const roleSupervisor = 'supervisor';
  static const roleHuman = 'human';
  static const roleSystem = 'system';
  static const roleApprovalGate = 'approval_gate';
  static const roleValidator = 'validator';
  static const roleBrowserSandbox = 'browser_sandbox';
}
