import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';
import 'notification_service.dart';
import '../../../core/constants/app_colors.dart';
Future<void> requestNotifIfNeeded(BuildContext context, WidgetRef ref) async {
  final service = NotificationService();
  final isFirst = await service.isFirstLaunch();
  if (!isFirst) return;
  final hasPermission = await service.hasNotificationPermission();
  if (hasPermission) {
    await service.markNotifAsked(granted: true);
    await service.refreshTodayNotifications();
    ref.invalidate(settingsProvider);
    ref.invalidate(notifDeclinedProvider);
    return;
  }
  if (!context.mounted) return;
  final shouldRequest = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgBase,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Bildirişlərə icazə',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: const Text(
        'Səhər, günorta və axşam zikr vaxtlarında xatırlatma '
        'göndərmək üçün bildiriş icazəsi lazımdır.\n\n'
        'İstəsən sonradan Parametrlər → Bildirişlər bölməsindən söndürə bilərsən.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(
            'Sonra',
            style: TextStyle(color: AppColors.textHint),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'İcazə ver',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  if (shouldRequest == true) {
    final granted = await service.requestPermission();
    await service.markNotifAsked(granted: granted);
    if (granted) await service.refreshTodayNotifications();
  } else {
    await service.markNotifAsked(granted: false);
  }
  ref.invalidate(settingsProvider);
  ref.invalidate(notifDeclinedProvider);
}
