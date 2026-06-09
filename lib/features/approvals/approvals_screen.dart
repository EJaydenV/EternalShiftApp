import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/providers.dart';
import '../../core/models/approval.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(approvalsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Action Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(approvalsProvider),
          ),
        ],
      ),
      body: approvalsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            error: e, onRetry: () => ref.invalidate(approvalsProvider)),
        data: (approvals) {
          final pending = approvals.where((a) => a.isPending).toList();
          final resolved = approvals
              .where((a) => !a.isPending)
              .toList()
            ..sort((a, b) => (b.resolvedAt ?? DateTime(0))
                .compareTo(a.resolvedAt ?? DateTime(0)));

          if (approvals.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'All clear',
              subtitle: 'No pending approvals.',
            );
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: AppTheme.surfaceContainerHigh,
            onRefresh: () async => ref.invalidate(approvalsProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (pending.isNotEmpty) ...[
                  _sectionHeader('PENDING (${pending.length})'),
                  ...pending.map((a) => _ApprovalCard(
                        approval: a,
                        onRefresh: () => ref.invalidate(approvalsProvider),
                      )),
                ],
                if (resolved.isNotEmpty) ...[
                  _sectionHeader('RESOLVED'),
                  ...resolved.take(10).map((a) => _ApprovalCard(
                        approval: a,
                        onRefresh: () => ref.invalidate(approvalsProvider),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.outline,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ApprovalCard extends ConsumerStatefulWidget {
  final Approval approval;
  final VoidCallback onRefresh;

  const _ApprovalCard({required this.approval, required this.onRefresh});

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  final _commentCtrl = TextEditingController();
  bool _actioning = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Approve This Action?',
      message: 'Approving does NOT instantly execute the action.\n\n'
          'It marks the approval so the next safe server-side cycle can continue.',
      warningNote:
          'Approving does not instantly execute dangerous actions. The server handles execution.',
      confirmLabel: 'Approve',
    );
    if (!ok) return;
    setState(() => _actioning = true);
    try {
      await ref.read(apiClientProvider).approveApproval(
            widget.approval.id,
            comment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Future<void> _reject() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reject This Action?',
      message:
          'The session will be informed and will not proceed with this action.',
      isDangerous: true,
      confirmLabel: 'Reject',
    );
    if (!ok) return;
    setState(() => _actioning = true);
    try {
      await ref.read(apiClientProvider).rejectApproval(
            widget.approval.id,
            comment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.approval;
    final isPending = a.isPending;
    final accentColor = isPending ? AppTheme.warning : AppTheme.outline;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
          top: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
          right: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
          bottom: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.security_rounded,
                    color: accentColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.requestedAction,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (a.reason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        a.reason!,
                        style: const TextStyle(
                            color: AppTheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: a.status),
            ],
          ),
          if (a.riskCategory != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warning, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'Risk: ${a.riskCategory}',
                    style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          if (a.requestedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Requested ${DateFormat('MMM d, HH:mm').format(a.requestedAt!.toLocal())}',
              style: const TextStyle(color: AppTheme.outline, fontSize: 11),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 14),
            _approvalWarning(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentCtrl,
              style:
                  const TextStyle(color: AppTheme.onSurface, fontSize: 13),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Comment (optional)…',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _actioning ? null : _approve,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Approve',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _actioning ? null : _reject,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Deny',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _actioning
                      ? null
                      : () async {
                          await ref
                              .read(apiClientProvider)
                              .dismissApproval(a.id);
                          widget.onRefresh();
                        },
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12)),
                  child: const Text('Skip', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _approvalWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppTheme.warning, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Approving does not instantly execute the action — it lets the next safe server-side cycle continue.',
              style: TextStyle(color: AppTheme.warning, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
