import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/providers.dart';
import '../../core/models/conversation_event.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const ConversationScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _ctrl = TextEditingController();
  String _messageType = 'note';
  String _targetRole = 'worker';
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(apiClientProvider).postMessage(widget.sessionId, {
        'content': text,
        'type': _messageType,
        'target_role': _targetRole,
      });
      _ctrl.clear();
      ref.invalidate(sessionConversationProvider(widget.sessionId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final convAsync =
        ref.watch(sessionConversationProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(sessionConversationProvider(widget.sessionId)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: convAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(
                    sessionConversationProvider(widget.sessionId)),
              ),
              data: (events) {
                final list = events as List<ConversationEvent>;
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No conversation yet',
                    subtitle: 'Run a cycle to start the conversation.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _EventCard(event: list[i]),
                );
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _messageType,
                  dropdownColor: AppTheme.card,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: ['note', 'comment', 'feedback', 'answer', 'important_note']
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setState(() => _messageType = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _targetRole,
                  dropdownColor: AppTheme.card,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: ['worker', 'reviewer', 'supervisor', 'system']
                      .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setState(() => _targetRole = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ctrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Add note or feedback…',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final ConversationEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final (roleColor, roleIcon) = _roleStyle(event.role);
    final isHuman = event.role == ConversationEvent.roleHuman;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isHuman) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(roleIcon, color: roleColor, size: 14),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isHuman
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: isHuman
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      _roleLabel(event.role),
                      style: TextStyle(
                          color: roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                    if (event.cycleId != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Cycle ${event.cycleId}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10),
                      ),
                    ],
                    if (event.timestamp != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('HH:mm').format(event.timestamp!.toLocal()),
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10),
                      ),
                    ],
                    if (event.status != null) ...[
                      const SizedBox(width: 6),
                      StatusBadge(status: event.status!, fontSize: 9),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isHuman
                        ? AppTheme.accentBlue.withOpacity(0.15)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isHuman
                            ? AppTheme.accentBlue.withOpacity(0.3)
                            : AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.title != null) ...[
                        Text(
                          event.title!,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        event.content,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isHuman) const SizedBox(width: 38),
        ],
      ),
    );
  }

  static (Color, IconData) _roleStyle(String role) {
    switch (role) {
      case ConversationEvent.roleWorker:
        return (AppTheme.accentBlue, Icons.engineering_rounded);
      case ConversationEvent.roleReviewer:
        return (AppTheme.accentViolet, Icons.rate_review_rounded);
      case ConversationEvent.roleSupervisor:
        return (AppTheme.accentCyan, Icons.supervisor_account_rounded);
      case ConversationEvent.roleHuman:
        return (AppTheme.success, Icons.person_rounded);
      case ConversationEvent.roleApprovalGate:
        return (AppTheme.danger, Icons.security_rounded);
      case ConversationEvent.roleValidator:
        return (AppTheme.warning, Icons.verified_rounded);
      case ConversationEvent.roleBrowserSandbox:
        return (AppTheme.textMuted, Icons.open_in_browser_rounded);
      default:
        return (AppTheme.textMuted, Icons.info_rounded);
    }
  }

  static String _roleLabel(String role) {
    switch (role) {
      case ConversationEvent.roleWorker:
        return 'Worker';
      case ConversationEvent.roleReviewer:
        return 'Reviewer';
      case ConversationEvent.roleSupervisor:
        return 'Supervisor';
      case ConversationEvent.roleHuman:
        return 'You';
      case ConversationEvent.roleApprovalGate:
        return 'Approval Gate';
      case ConversationEvent.roleValidator:
        return 'Validator';
      case ConversationEvent.roleBrowserSandbox:
        return 'Browser Sandbox';
      default:
        return role;
    }
  }
}
