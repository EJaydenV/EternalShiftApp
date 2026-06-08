import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/providers.dart';
import '../../core/models/ui_test_run.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

class UiTestsScreen extends ConsumerStatefulWidget {
  const UiTestsScreen({super.key});

  @override
  ConsumerState<UiTestsScreen> createState() => _UiTestsScreenState();
}

class _UiTestsScreenState extends ConsumerState<UiTestsScreen> {
  Set<String> _selected = {};
  bool _running = false;
  UiTestRun? _latestRun;

  @override
  Widget build(BuildContext context) {
    final scenariosAsync = ref.watch(uiTestScenariosProvider);
    final runsAsync = ref.watch(uiTestRunsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('UI Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(uiTestScenariosProvider);
              ref.invalidate(uiTestRunsProvider);
            },
          ),
        ],
      ),
      body: scenariosAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(error: e),
        data: (scenarios) => _buildBody(scenarios, runsAsync),
      ),
    );
  }

  Widget _buildBody(List<UiTestScenario> scenarios, AsyncValue<dynamic> runsAsync) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        SectionCard(
          title: 'SCENARIOS',
          child: Column(
            children: scenarios.map((s) {
              final selected = _selected.contains(s.id);
              return CheckboxListTile(
                dense: true,
                value: selected,
                title: Text(s.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13)),
                subtitle: s.description != null
                    ? Text(s.description!,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11))
                    : null,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(s.id);
                    } else {
                      _selected.remove(s.id);
                    }
                  });
                },
                activeColor: AppTheme.accentBlue,
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _selected = {
                  for (final s in ref.read(uiTestScenariosProvider).value ?? []) s.id
                }),
                child: const Text('Select All'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _running || _selected.isEmpty ? null : _runTests,
                icon: _running
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(_running
                    ? 'Running…'
                    : 'Run ${_selected.length} Test${_selected.length == 1 ? '' : 's'}'),
              ),
            ],
          ),
        ),
        if (_latestRun != null) _buildLatestRun(_latestRun!),
        SectionCard(
          title: 'RECENT RUNS',
          child: runsAsync.when(
            loading: () => const InlineLoader(),
            error: (e, _) => const SizedBox.shrink(),
            data: (runs) {
              final list = runs as List<UiTestRun>;
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.science_rounded,
                  title: 'No test runs yet',
                );
              }
              return Column(
                children: list
                    .take(5)
                    .map((r) => _RunTile(run: r))
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLatestRun(UiTestRun run) {
    return SectionCard(
      title: 'LATEST RUN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(status: run.status ?? 'running'),
              const SizedBox(width: 10),
              Text(
                '${run.passed ?? 0} passed · ${run.failed ?? 0} failed',
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13),
              ),
            ],
          ),
          if (run.results != null) ...[
            const SizedBox(height: 10),
            ...run.results!.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        r.passed
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color:
                            r.passed ? AppTheme.success : AppTheme.danger,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r.scenario,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12)),
                      ),
                      if (r.error != null)
                        Text(r.error!,
                            style: const TextStyle(
                                color: AppTheme.danger, fontSize: 10)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _runTests() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Run UI Tests?',
      message: 'This will trigger server-side UI tests.',
      warningNote: 'This may consume server resources.',
    );
    if (!ok) return;
    setState(() => _running = true);
    try {
      final run =
          await ref.read(apiClientProvider).runUiTests(_selected.toList());
      setState(() => _latestRun = run);
      ref.invalidate(uiTestRunsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}

class _RunTile extends StatelessWidget {
  final UiTestRun run;
  const _RunTile({required this.run});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          StatusBadge(status: run.status ?? 'unknown'),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${run.passed ?? 0} passed · ${run.failed ?? 0} failed',
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 12),
            ),
          ),
          if (run.startedAt != null)
            Text(
              _timeLabel(run.startedAt!),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
