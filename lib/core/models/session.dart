class Session {
  final String id;
  final String name;
  final String? objective;
  final String status;
  final String? provider;
  final String? currentTask;
  final String? currentPhase;
  final String? lastReviewerVerdict;
  final String? proofStatus;
  final int? cycleCount;
  final int? totalTokens;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? needsAttention;

  const Session({
    required this.id,
    required this.name,
    required this.status,
    this.objective,
    this.provider,
    this.currentTask,
    this.currentPhase,
    this.lastReviewerVerdict,
    this.proofStatus,
    this.cycleCount,
    this.totalTokens,
    this.createdAt,
    this.updatedAt,
    this.needsAttention,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Unnamed Session',
        status: json['status'] as String? ?? 'unknown',
        objective: json['objective'] as String?,
        provider: json['provider'] as String?,
        currentTask: json['current_task'] as String?,
        currentPhase: json['current_phase'] as String?,
        lastReviewerVerdict: json['last_reviewer_verdict'] as String?,
        proofStatus: json['proof_status'] as String?,
        cycleCount: json['cycle_count'] as int?,
        totalTokens: json['total_tokens'] as int?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
        needsAttention: json['needs_attention'] as bool?,
      );

  bool get isRunning => status == 'running';
  bool get isPaused => status == 'paused';
  bool get isBlocked => status == 'blocked';
  bool get isCompleted => status == 'completed';
  bool get isActive => ['running', 'paused', 'blocked', 'active'].contains(status);
  bool get isDeleted => status == 'deleted';
}
