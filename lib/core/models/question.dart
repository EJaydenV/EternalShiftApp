class Question {
  final String id;
  final String sessionId;
  final String? cycleId;
  final String questionText;
  final String? context;
  final String? questionType;
  final String status;
  final String? answer;
  final bool? isCritical;
  final DateTime? askedAt;
  final DateTime? answeredAt;

  const Question({
    required this.id,
    required this.sessionId,
    required this.questionText,
    required this.status,
    this.cycleId,
    this.context,
    this.questionType,
    this.answer,
    this.isCritical,
    this.askedAt,
    this.answeredAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        sessionId: json['session_id'] as String? ?? '',
        cycleId: json['cycle_id'] as String?,
        questionText: json['question'] as String? ?? json['question_text'] as String? ?? '',
        context: json['context'] as String?,
        questionType: json['question_type'] as String?,
        status: json['status'] as String? ?? 'pending',
        answer: json['answer'] as String?,
        isCritical: json['is_critical'] as bool?,
        askedAt: json['asked_at'] != null
            ? DateTime.tryParse(json['asked_at'] as String)
            : null,
        answeredAt: json['answered_at'] != null
            ? DateTime.tryParse(json['answered_at'] as String)
            : null,
      );

  bool get isPending => status == 'pending';
  bool get isAnswered => status == 'answered';
  bool get isDismissed => status == 'dismissed';
}
