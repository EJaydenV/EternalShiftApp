import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _nameCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _provider = 'mock';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _objectiveCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_provider != 'mock') {
      final ok = await showConfirmDialog(
        context,
        title: 'Use Real Provider?',
        message: 'You are about to create a session with $_provider.',
        warningNote: 'This may consume Claude/API tokens.',
      );
      if (!ok) return;
    }
    setState(() => _saving = true);
    try {
      final session = await ref.read(apiClientProvider).createSession({
        'name': _nameCtrl.text.trim(),
        'objective': _objectiveCtrl.text.trim(),
        'provider': _provider,
      });
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Create Session')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Or use Smart Session for AI-guided setup',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Session Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _objectiveCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Objective',
                  hintText: 'What should Eternal Shift accomplish?',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _provider,
                dropdownColor: AppTheme.surface,
                decoration: const InputDecoration(labelText: 'Provider'),
                items: ['mock', 'claude_cli', 'anthropic_api']
                    .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p,
                            style: const TextStyle(
                                color: AppTheme.textPrimary))))
                    .toList(),
                onChanged: (v) => setState(() => _provider = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _create,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Create Session'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.pushReplacement('/sessions/smart-create'),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Use Smart Session Wizard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
