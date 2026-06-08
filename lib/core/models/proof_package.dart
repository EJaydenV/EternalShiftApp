class ProofPackage {
  final String id;
  final String sessionId;
  final String? cycleId;
  final String? task;
  final String? acceptanceCriteria;
  final String? status;
  final String? reviewerVerdict;
  final List<String>? testsRun;
  final List<String>? filesChanged;
  final String? gitCheckpoint;
  final List<String>? screenshotIds;
  final int? exitCode;
  final bool? uiTestsPassed;
  final DateTime? createdAt;

  const ProofPackage({
    required this.id,
    required this.sessionId,
    this.cycleId,
    this.task,
    this.acceptanceCriteria,
    this.status,
    this.reviewerVerdict,
    this.testsRun,
    this.filesChanged,
    this.gitCheckpoint,
    this.screenshotIds,
    this.exitCode,
    this.uiTestsPassed,
    this.createdAt,
  });

  factory ProofPackage.fromJson(Map<String, dynamic> json) => ProofPackage(
        id: json['id'] as String,
        sessionId: json['session_id'] as String? ?? '',
        cycleId: json['cycle_id'] as String?,
        task: json['task'] as String?,
        acceptanceCriteria: json['acceptance_criteria'] as String?,
        status: json['status'] as String?,
        reviewerVerdict: json['reviewer_verdict'] as String?,
        testsRun: (json['tests_run'] as List?)?.cast<String>(),
        filesChanged: (json['files_changed'] as List?)?.cast<String>(),
        gitCheckpoint: json['git_checkpoint'] as String?,
        screenshotIds: (json['screenshot_ids'] as List?)?.cast<String>(),
        exitCode: json['exit_code'] as int?,
        uiTestsPassed: json['ui_tests_passed'] as bool?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  bool get isPassed => status == 'passed' || reviewerVerdict == 'approved';
  bool get isFailed => status == 'failed' || reviewerVerdict == 'rejected';
}
