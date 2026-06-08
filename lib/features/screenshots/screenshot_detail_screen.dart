import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class ScreenshotDetailScreen extends ConsumerWidget {
  final String screenshotId;
  const ScreenshotDetailScreen({super.key, required this.screenshotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Screenshot'),
      ),
      body: Center(
        child: Text('Screenshot $screenshotId',
            style: const TextStyle(color: AppTheme.textSecondary)),
      ),
    );
  }
}
