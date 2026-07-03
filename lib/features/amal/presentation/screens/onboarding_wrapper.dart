import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import '../providers/amal_provider.dart';
class OnboardingWrapper extends ConsumerStatefulWidget {
  const OnboardingWrapper({super.key});
  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}
class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(amalProvider);
    }
  }
  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
