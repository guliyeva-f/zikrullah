import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'home_screen.dart';

class OnboardingWrapper extends ConsumerStatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());
  }

  Future<void> _checkOnboarding() async {
    final service = NotificationService();
    final isFirst = await service.isFirstLaunch();
    if (!isFirst || !mounted) return;

    final granted = await service.requestPermission();

    await service.markNotifAsked(granted: granted);

    if (granted) {
      await service.reschedule();
    }

    // Badge provider-i yenilə
    ref.invalidate(notifDeclinedProvider);
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
