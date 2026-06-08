import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/models/screenshot.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';

class ScreenshotsScreen extends ConsumerWidget {
  const ScreenshotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(screenshotsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Screenshots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(screenshotsProvider),
          ),
        ],
      ),
      body: screenshotsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            error: e, onRetry: () => ref.invalidate(screenshotsProvider)),
        data: (screenshots) {
          final list = screenshots as List<AppScreenshot>;
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.camera_alt_rounded,
              title: 'No screenshots',
              subtitle: 'Screenshots will appear here after cycles run.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => _ScreenshotTile(screenshot: list[i]),
          );
        },
      ),
    );
  }
}

class _ScreenshotTile extends StatelessWidget {
  final AppScreenshot screenshot;
  const _ScreenshotTile({required this.screenshot});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/screenshots/${screenshot.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(9)),
                child: screenshot.thumbnailUrl != null
                    ? Image.network(
                        screenshot.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (screenshot.scenario != null)
                    Text(
                      screenshot.scenario!,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (screenshot.capturedAt != null)
                    Text(
                      _timeLabel(screenshot.capturedAt!),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.surface,
      child: const Center(
        child: Icon(Icons.image_rounded,
            color: AppTheme.textMuted, size: 32),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
