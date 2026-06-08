import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static (Color, Color) _colorFor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return (AppTheme.accentCyan, AppTheme.accentCyan.withOpacity(0.15));
      case 'active':
        return (AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.15));
      case 'paused':
        return (AppTheme.warning, AppTheme.warning.withOpacity(0.15));
      case 'blocked':
        return (AppTheme.danger, AppTheme.danger.withOpacity(0.15));
      case 'completed':
      case 'approved':
      case 'passed':
        return (AppTheme.success, AppTheme.success.withOpacity(0.15));
      case 'stopped':
      case 'failed':
      case 'rejected':
        return (AppTheme.danger, AppTheme.danger.withOpacity(0.15));
      case 'pending':
        return (AppTheme.warning, AppTheme.warning.withOpacity(0.15));
      case 'deleted':
        return (AppTheme.textMuted, AppTheme.textMuted.withOpacity(0.15));
      case 'mock':
        return (AppTheme.accentViolet, AppTheme.accentViolet.withOpacity(0.15));
      default:
        return (AppTheme.textSecondary, AppTheme.textSecondary.withOpacity(0.12));
    }
  }
}
