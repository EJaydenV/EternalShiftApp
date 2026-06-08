import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class ProofDetailScreen extends ConsumerWidget {
  final String proofId;
  const ProofDetailScreen({super.key, required this.proofId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Proof Detail')),
      body: Center(
        child: Text('Proof $proofId',
            style: const TextStyle(color: AppTheme.textSecondary)),
      ),
    );
  }
}
