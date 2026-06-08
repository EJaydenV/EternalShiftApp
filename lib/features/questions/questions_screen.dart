import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/providers.dart';
import '../../core/models/question.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class QuestionsScreen extends ConsumerWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Questions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(questionsProvider),
          ),
        ],
      ),
      body: questionsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            error: e, onRetry: () => ref.invalidate(questionsProvider)),
        data: (questions) {
          if (questions.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'No questions',
              subtitle: 'No sessions are waiting for your input.',
            );
          }
          return RefreshIndicator(
            color: AppTheme.accentBlue,
            backgroundColor: AppTheme.card,
            onRefresh: () async => ref.invalidate(questionsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: questions.length,
              itemBuilder: (_, i) => _QuestionCard(
                question: questions[i],
                onRefresh: () => ref.invalidate(questionsProvider),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuestionCard extends ConsumerStatefulWidget {
  final Question question;
  final VoidCallback onRefresh;

  const _QuestionCard({required this.question, required this.onRefresh});

  @override
  ConsumerState<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends ConsumerState<_QuestionCard> {
  final _answerCtrl = TextEditingController();
  bool _actioning = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  q.isCritical == true
                      ? Icons.warning_rounded
                      : Icons.help_outline_rounded,
                  color: q.isCritical == true
                      ? AppTheme.danger
                      : AppTheme.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q.questionText,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge(status: q.status),
              ],
            ),
            if (q.context != null) ...[
              const SizedBox(height: 8),
              Text(q.context!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
            if (q.askedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Asked ${DateFormat('MMM d, HH:mm').format(q.askedAt!.toLocal())}',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
            if (q.isPending) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _answerCtrl,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 12),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Your answer…',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _actioning ? null : _answer,
                      child: const Text('Answer', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (q.isCritical != true)
                    OutlinedButton(
                      onPressed: _actioning ? null : _dismiss,
                      child:
                          const Text('Dismiss', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
            if (q.isAnswered && q.answer != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.25)),
                ),
                child: Text(
                  'Answer: ${q.answer}',
                  style: const TextStyle(
                      color: AppTheme.success, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _answer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _actioning = true);
    try {
      await ref.read(apiClientProvider).answerQuestion(widget.question.id, text);
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _actioning = true);
    try {
      await ref.read(apiClientProvider).dismissQuestion(widget.question.id);
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }
}
