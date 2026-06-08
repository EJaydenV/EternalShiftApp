class UiTestScenario {
  final String id;
  final String name;
  final String? description;

  const UiTestScenario({
    required this.id,
    required this.name,
    this.description,
  });

  factory UiTestScenario.fromJson(Map<String, dynamic> json) => UiTestScenario(
        id: json['id'] as String? ?? json['name'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
      );
}

class UiTestRun {
  final String id;
  final List<String>? scenarios;
  final String? status;
  final int? passed;
  final int? failed;
  final int? total;
  final String? error;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<UiTestResult>? results;

  const UiTestRun({
    required this.id,
    this.scenarios,
    this.status,
    this.passed,
    this.failed,
    this.total,
    this.error,
    this.startedAt,
    this.completedAt,
    this.results,
  });

  factory UiTestRun.fromJson(Map<String, dynamic> json) => UiTestRun(
        id: json['id'] as String,
        scenarios: (json['scenarios'] as List?)?.cast<String>(),
        status: json['status'] as String?,
        passed: json['passed'] as int?,
        failed: json['failed'] as int?,
        total: json['total'] as int?,
        error: json['error'] as String?,
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
        results: (json['results'] as List?)
            ?.map((e) => UiTestResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class UiTestResult {
  final String scenario;
  final bool passed;
  final String? error;

  const UiTestResult({
    required this.scenario,
    required this.passed,
    this.error,
  });

  factory UiTestResult.fromJson(Map<String, dynamic> json) => UiTestResult(
        scenario: json['scenario'] as String? ?? '',
        passed: json['passed'] as bool? ?? false,
        error: json['error'] as String?,
      );
}
