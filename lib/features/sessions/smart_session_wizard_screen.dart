import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

class SmartSessionWizardScreen extends ConsumerStatefulWidget {
  const SmartSessionWizardScreen({super.key});

  @override
  ConsumerState<SmartSessionWizardScreen> createState() =>
      _SmartSessionWizardScreenState();
}

class _SmartSessionWizardScreenState
    extends ConsumerState<SmartSessionWizardScreen> {
  final _goalCtrl = TextEditingController();
  bool _analyzing = false;
  bool _creating = false;
  Map<String, dynamic>? _analysis;
  String? _errorMsg;

  static const _examples = [
    'Create a website for my business.',
    'Build a SaaS MVP and generate ethical income.',
    'Research a startup idea.',
    'Write a research paper on AI safety.',
    'Improve Eternal Shift.',
  ];

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final goal = _goalCtrl.text.trim();
    if (goal.isEmpty) return;
    setState(() {
      _analyzing = true;
      _analysis = null;
      _errorMsg = null;
    });
    try {
      final result = await ref.read(apiClientProvider).analyzeInput(goal);
      setState(() => _analysis = result);
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      setState(() => _analyzing = false);
    }
  }

  Future<void> _create({bool andRun = false}) async {
    if (_analysis == null) return;
    final provider = _analysis!['recommended_provider'] as String? ?? 'mock';
    if (provider != 'mock') {
      final ok = await showConfirmDialog(
        context,
        title: 'Use Real Provider?',
        message: 'Session will run with provider: $provider',
        warningNote: 'This may consume Claude/API tokens.',
      );
      if (!ok) return;
    }
    setState(() => _creating = true);
    try {
      final body = {
        'goal': _goalCtrl.text.trim(),
        'analysis': _analysis,
      };
      final client = ref.read(apiClientProvider);
      final session =
          andRun ? await client.smartCreateAndRun(body) : await client.smartCreate(body);
      if (mounted) {
        ref.invalidate(sessionsProvider);
        context.go('/sessions/${session.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Smart Session')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGoalSection(),
            if (_errorMsg != null) _buildError(),
            if (_analyzing) _buildAnalyzingState(),
            if (_analysis != null) _buildAnalysis(),
            if (_analysis != null) _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you want Eternal Shift to do?',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Describe your goal. Eternal Shift will analyze it and create a smart session plan.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _goalCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'e.g. Create a website for my business. Generate ethical income. Build an app.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _examples
              .map((e) => GestureDetector(
                    onTap: () => setState(() => _goalCtrl.text = e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Text(e,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _analyzing ? null : _analyze,
          icon: _analyzing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.search_rounded, size: 16),
          label: Text(_analyzing ? 'Analyzing…' : 'Analyze Goal'),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
        ),
        child: Text(_errorMsg!,
            style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppTheme.accentBlue, strokeWidth: 2),
          SizedBox(height: 12),
          Text('Analyzing your goal…',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAnalysis() {
    final a = _analysis!;
    final sessionType = a['session_type'] as String? ?? '—';
    final confidence = a['confidence'] as double? ?? 0;
    final riskLevel = a['risk_level'] as String? ?? '—';
    final provider = a['recommended_provider'] as String? ?? '—';
    final tasks = (a['first_tasks'] as List?)?.cast<String>() ?? [];
    final assumptions = (a['assumptions'] as List?)?.cast<String>() ?? [];
    final warnings = (a['approval_warnings'] as List?)?.cast<String>() ?? [];

    return Column(
      children: [
        const SizedBox(height: 20),
        SectionCard(
          title: 'ANALYSIS',
          child: Column(
            children: [
              _analysisRow('Session Type', sessionType),
              _analysisRow('Confidence',
                  '${(confidence * 100).toStringAsFixed(0)}%'),
              Row(
                children: [
                  const SizedBox(
                    width: 130,
                    child: Text('Risk Level',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  StatusBadge(status: riskLevel),
                ],
              ),
              const SizedBox(height: 5),
              _analysisRow('Recommended Provider', provider),
            ],
          ),
        ),
        if (tasks.isNotEmpty)
          SectionCard(
            title: 'FIRST TASKS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tasks
                  .map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: AppTheme.accentBlue,
                                    fontSize: 12)),
                            Expanded(
                                child: Text(t,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        if (assumptions.isNotEmpty)
          SectionCard(
            title: 'ASSUMPTIONS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: assumptions
                  .map((a) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text('• $a',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
        if (warnings.isNotEmpty)
          SectionCard(
            title: 'APPROVAL WARNINGS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings
                  .map((w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppTheme.warning, size: 12),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(w,
                                    style: const TextStyle(
                                        color: AppTheme.warning,
                                        fontSize: 12))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _analysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _creating ? null : () => _create(),
            child: const Text('Create Session'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _creating ? null : () => _create(andRun: true),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Create and Run One Cycle'),
          ),
        ],
      ),
    );
  }
}
