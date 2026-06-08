class Cycle {
  final String id;
  final String sessionId;
  final int cycleNumber;
  final String? status;
  final String? phase;
  final String? workerOutput;
  final String? reviewerVerdict;
  final String? supervisorNote;
  final String? proofStatus;
  final int? tokensUsed;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const Cycle({
    required this.id,
    required this.sessionId,
    required this.cycleNumber,
    this.status,
    this.phase,
    this.workerOutput,
    this.reviewerVerdict,
    this.supervisorNote,
    this.proofStatus,
    this.tokensUsed,
    this.startedAt,
    this.completedAt,
  });

  factory Cycle.fromJson(Map<String, dynamic> json) => Cycle(
        id: json['id'] as String,
        sessionId: json['session_id'] as String? ?? '',
        cycleNumber: json['cycle_number'] as int? ?? 0,
        status: json['status'] as String?,
        phase: json['phase'] as String?,
        workerOutput: json['worker_output'] as String?,
        reviewerVerdict: json['reviewer_verdict'] as String?,
        supervisorNote: json['supervisor_note'] as String?,
        proofStatus: json['proof_status'] as String?,
        tokensUsed: json['tokens_used'] as int?,
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
      );

  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }
}
