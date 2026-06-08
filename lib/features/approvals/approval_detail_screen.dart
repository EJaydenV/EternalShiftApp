import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class ApprovalDetailScreen extends ConsumerWidget {
  final String approvalId;
  const ApprovalDetailScreen({super.key, required this.approvalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Approval Detail')),
      body: Center(
        child: Text(
          'Approval $approvalId',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
