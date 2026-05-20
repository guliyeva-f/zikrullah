import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(child: Text('Xəta: $e')),
        data: (state) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Master toggle ──────────────────────────────────
            _SectionHeader(title: 'Bildirişlər'),
            _ToggleRow(
              title: 'Bildirişlər',
              subtitle: 'Gündəlik xatırlatmaları aç/bağla',
              value: state.notificationsEnabled,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setNotificationsEnabled(v),
            ),
            const SizedBox(height: 16),

            // ── Vaxtlar ────────────────────────────────────────
            AnimatedOpacity(
              opacity: state.notificationsEnabled ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: AbsorbPointer(
                absorbing: !state.notificationsEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Xatırlatma vaxtları'),
                    _TimeRow(
                      title: 'Səhər',
                      time: state.morningTime,
                      onTap: () => _pickTime(
                        context,
                        ref,
                        current: state.morningTime,
                        onPicked: (t) => ref
                            .read(settingsProvider.notifier)
                            .setMorningTime(t),
                      ),
                    ),
                    _TimeRow(
                      title: 'Günorta',
                      time: state.noonTime,
                      onTap: () => _pickTime(
                        context,
                        ref,
                        current: state.noonTime,
                        onPicked: (t) =>
                            ref.read(settingsProvider.notifier).setNoonTime(t),
                      ),
                    ),
                    _TimeRow(
                      title: 'Axşam',
                      time: state.eveningTime,
                      onTap: () => _pickTime(
                        context,
                        ref,
                        current: state.eveningTime,
                        onPicked: (t) => ref
                            .read(settingsProvider.notifier)
                            .setEveningTime(t),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Gecə 23:00 — sabit, yalnız toggle ─────
                    _SectionHeader(title: 'Gecə xəbərdarlığı'),
                    _ToggleRow(
                      title: 'Gecə 23:00',
                      subtitle: 'Günün bitmə vaxtı xatırlatması (sabit)',
                      value: state.nightNotifEnabled,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setNightEnabled(v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required TimeOfDay current,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColors.bgCard,
            dialHandColor: AppColors.accent,
            hourMinuteColor: AppColors.bgElevated,
            hourMinuteTextColor: AppColors.textPrimary,
            dayPeriodTextColor: AppColors.textSecondary,
            entryModeIconColor: AppColors.accent,
          ),
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            surface: AppColors.bgCard,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }
}

// ─── HELPER WIDGETS ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String title;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeRow({
    required this.title,
    required this.time,
    required this.onTap,
  });

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              _formatTime(time),
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
