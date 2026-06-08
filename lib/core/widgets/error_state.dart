import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException
        ? (error as ApiException).userMessage
        : error.toString();

    final isUnauth =
        error is ApiException && (error as ApiException).code == 'UNAUTHORIZED';
    final isUnavailable = error is ApiException &&
        (error as ApiException).code == 'SERVER_UNAVAILABLE';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUnavailable
                  ? Icons.cloud_off_rounded
                  : isUnauth
                      ? Icons.lock_outline_rounded
                      : Icons.error_outline_rounded,
              size: 48,
              color: isUnavailable ? AppTheme.warning : AppTheme.danger,
            ),
            const SizedBox(height: 16),
            Text(
              isUnavailable
                  ? 'Server Unavailable'
                  : isUnauth
                      ? 'Authentication Failed'
                      : 'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
