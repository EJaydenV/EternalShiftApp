import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/models/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  final _noteController = TextEditingController();
  bool _actioning = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _doAction(Future<void> Function() action) async {
    setState(() => _actioning = true);
    try {
      await action();
      ref.invalidate(sessionProvider(widget.sessionId));
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(sessionProvider(widget.sessionId)),
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            error: e,
            onRetry: () =>
                ref.invalidate(sessionProvider(widget.sessionId))),
        data: (s) => _buildDetail(context, s as Session),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Session session) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildHeader(session),
        if (session.isBlocked) _buildBlockedPanel(context),
        _buildInfo(session),
        _buildControls(context, session),
        _buildNavLinks(context, session),
        _buildNoteComposer(context, session),
      ],
    );
  }

  Widget _buildHeader(Session session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.name,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              StatusBadge(status: session.status, fontSize: 12),
            ],
          ),
          if (session.objective != null) ...[
            const SizedBox(height: 8),
            Text(
              session.objective!,
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlockedPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.danger.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.block_rounded, color: AppTheme.danger, size: 16),
                SizedBox(width: 8),
                Text(
                  'Session Blocked — Action Required',
                  style: TextStyle(
                    color: AppTheme.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'This session is waiting for your approval before it can continue.',
              style:
                  TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/approvals'),
                    icon: const Icon(Icons.inbox_rounded, size: 14),
                    label: const Text('Action Inbox',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/proof'),
                    icon: const Icon(Icons.verified_rounded, size: 14),
                    label: const Text('Proof',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondary,
                        side:
                            const BorderSide(color: AppTheme.secondary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(Session session) {
    return _glassSection(
      title: 'DETAILS',
      child: Column(
        children: [
          _infoRow('Provider', session.provider ?? '—'),
          _infoRow('Phase', session.currentPhase ?? '—'),
          _infoRow('Current Task', session.currentTask ?? '—'),
          _infoRow(
              'Reviewer Verdict', session.lastReviewerVerdict ?? '—'),
          _infoRow('Proof Status', session.proofStatus ?? '—'),
          _infoRow('Cycles', '${session.cycleCount ?? 0}'),
          _infoRow('Tokens', _formatTokens(session.totalTokens ?? 0)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.outline, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, Session session) {
    return _glassSection(
      title: 'CONTROLS',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!session.isRunning && !session.isCompleted)
            _controlBtn(
              Icons.play_arrow_rounded,
              'Run Cycle',
              AppTheme.secondary,
              () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Run One Cycle',
                  message: 'This will consume AI tokens.',
                  warningNote: 'This may consume Claude/API tokens.',
                );
                if (ok) {
                  await _doAction(() =>
                      ref.read(apiClientProvider).runCycle(session.id));
                }
              },
            ),
          if (!session.isRunning && !session.isCompleted)
            _controlBtn(
              Icons.fast_forward_rounded,
              'Run Until Approved',
              AppTheme.primary,
              () => _showRunUntilApprovedDialog(context, session),
            ),
          if (session.isRunning)
            _controlBtn(
              Icons.pause_rounded,
              'Pause',
              AppTheme.warning,
              () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Pause Session',
                  message:
                      'Will pause after the current cycle completes.',
                );
                if (ok) {
                  await _doAction(() => ref
                      .read(apiClientProvider)
                      .pauseSession(session.id));
                }
              },
            ),
          if (session.isPaused || session.isBlocked)
            _controlBtn(
              Icons.play_circle_rounded,
              'Resume',
              AppTheme.success,
              () => _doAction(() =>
                  ref.read(apiClientProvider).resumeSession(session.id)),
            ),
          if (session.isActive && !session.isRunning)
            _controlBtn(
              Icons.stop_rounded,
              'Stop',
              AppTheme.danger,
              () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Stop Session',
                  message:
                      'Stop this session? You can reopen it later.',
                  isDangerous: true,
                );
                if (ok) {
                  await _doAction(() =>
                      ref.read(apiClientProvider).stopSession(session.id));
                }
              },
            ),
          if (session.isCompleted || session.status == 'stopped')
            _controlBtn(
              Icons.replay_rounded,
              'Reopen',
              AppTheme.accentViolet,
              () => _doAction(() =>
                  ref.read(apiClientProvider).reopenSession(session.id)),
            ),
          _controlBtn(
            Icons.delete_outline_rounded,
            'Delete',
            AppTheme.danger,
            () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Delete Session',
                message:
                    'Soft-delete this session? It will be hidden but recoverable.',
                isDangerous: true,
              );
              if (ok) {
                await _doAction(() => ref
                    .read(apiClientProvider)
                    .deleteSession(session.id));
                if (mounted) context.go('/sessions');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _actioning ? null : onTap,
      child: Opacity(
        opacity: _actioning ? 0.5 : 1,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLinks(BuildContext context, Session session) {
    return _glassSection(
      title: 'EXPLORE',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _navChip(Icons.chat_bubble_outline_rounded, 'Conversation',
              AppTheme.primary,
              () => context
                  .push('/sessions/${session.id}/conversation')),
          _navChip(Icons.verified_rounded, 'Proof', AppTheme.secondary,
              () => context.push('/sessions/${session.id}/proof')),
          _navChip(Icons.inbox_rounded, 'Action Inbox', AppTheme.warning,
              () => context.go('/approvals')),
          _navChip(Icons.camera_alt_rounded, 'Screenshots',
              AppTheme.outline, () => context.push('/screenshots')),
        ],
      ),
    );
  }

  Widget _navChip(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteComposer(BuildContext context, Session session) {
    return _glassSection(
      title: 'ADD NOTE OR FEEDBACK',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _noteController,
            style: const TextStyle(
                color: AppTheme.onSurface, fontSize: 13),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a note, comment, or feedback…',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final text = _noteController.text.trim();
                    if (text.isEmpty) return;
                    await ref
                        .read(apiClientProvider)
                        .postNote(session.id, text);
                    _noteController.clear();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note added')));
                    }
                  },
                  child: const Text('Add Note',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _showFeedbackDialog(context, session),
                  child: const Text('Send Feedback',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showRunUntilApprovedDialog(
      BuildContext context, Session session) async {
    int maxCycles = AppConfig.maxCyclesDefault;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.outlineVariant)),
          title: const Text('Run Until Approved',
              style: TextStyle(
                  color: AppTheme.onSurface, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set the maximum number of cycles to run before stopping.',
                style: TextStyle(
                    color: AppTheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Max Cycles:',
                      style: TextStyle(
                          color: AppTheme.onSurface, fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: maxCycles.toDouble(),
                      min: 1,
                      max: AppConfig.maxCyclesMax.toDouble(),
                      divisions: AppConfig.maxCyclesMax - 1,
                      label: '$maxCycles',
                      onChanged: (v) =>
                          setSt(() => maxCycles = v.round()),
                    ),
                  ),
                  Text('$maxCycles',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              _warningBox(
                  'This may consume Claude/API tokens. Infinite runs are not allowed.'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Run ($maxCycles cycles)'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await _doAction(() =>
          ref.read(apiClientProvider).runUntilApproved(
                session.id,
                maxCycles: maxCycles,
              ));
    }
  }

  Future<void> _showFeedbackDialog(
      BuildContext context, Session session) async {
    String targetRole = 'worker';
    final textCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.outlineVariant)),
          title: const Text('Send Feedback',
              style: TextStyle(
                  color: AppTheme.onSurface, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: targetRole,
                dropdownColor: AppTheme.surfaceContainerHigh,
                decoration:
                    const InputDecoration(labelText: 'Send To'),
                items: ['worker', 'reviewer', 'supervisor', 'system']
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r,
                            style: const TextStyle(
                                color: AppTheme.onSurface))))
                    .toList(),
                onChanged: (v) => setSt(() => targetRole = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: textCtrl,
                style: const TextStyle(
                    color: AppTheme.onSurface, fontSize: 13),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Your feedback…',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final text = textCtrl.text.trim();
                if (text.isEmpty) return;
                await ref.read(apiClientProvider).postFeedback(
                  session.id,
                  {
                    'content': text,
                    'target_role': targetRole,
                    'type': 'feedback',
                  },
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.outline,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _warningBox(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.warning, fontSize: 12)),
    );
  }

  String _formatTokens(int t) {
    if (t >= 1000000) return '${(t / 1000000).toStringAsFixed(1)}M';
    if (t >= 1000) return '${(t / 1000).toStringAsFixed(1)}K';
    return '$t';
  }
}
