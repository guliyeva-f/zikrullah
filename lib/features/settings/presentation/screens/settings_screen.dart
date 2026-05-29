import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../amal/data/import_export_service.dart';
import '../../../amal/domain/amal.dart';
import '../../../amal/presentation/providers/amal_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _waitingForSettings = false;

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
    if (state == AppLifecycleState.resumed && _waitingForSettings) {
      _waitingForSettings = false;
      _checkPermissionAfterReturn();
    }
  }

  Future<void> _checkPermissionAfterReturn() async {
    final hasPermission = await NotificationService()
        .hasNotificationPermission();
    if (!mounted) return;
    if (hasPermission) {
      await ref.read(settingsProvider.notifier).setNotificationsEnabled(true);
      ref.invalidate(notifDeclinedProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.textHint,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Bir xəta baş verdi',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(settingsProvider),
                child: Text(
                  'Yenidən cəhd et',
                  style: GoogleFonts.nunito(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        data: (state) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Bildirişlər ────────────────────────────────────────
            _SectionHeader(title: 'Bildirişlər'),
            _ToggleRow(
              title: 'Bildirişlər',
              subtitle: 'Gündəlik xatırlatmaları aç/bağla',
              value: state.notificationsEnabled,
              onChanged: (v) async {
                if (v) {
                  final granted = await NotificationService()
                      .requestPermission();
                  if (!context.mounted) return;

                  if (granted) {
                    await ref
                        .read(settingsProvider.notifier)
                        .setNotificationsEnabled(true);
                    ref.invalidate(notifDeclinedProvider);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Android bir dəfə rədd edilən icazəni yenidən sormur. '
                          '"Ayarlar" düyməsinə bas və bildirişləri əl ilə aç.',
                          style: GoogleFonts.nunito(color: Colors.white),
                        ),
                        backgroundColor: AppColors.accentLight,
                        duration: const Duration(seconds: 6),
                        action: SnackBarAction(
                          label: 'Ayarlar',
                          textColor: Colors.white,
                          onPressed: () async {
                            _waitingForSettings = true;
                            await NotificationService().openSystemSettings();
                          },
                        ),
                      ),
                    );
                  }
                } else {
                  await ref
                      .read(settingsProvider.notifier)
                      .setNotificationsEnabled(false);
                  ref.invalidate(notifDeclinedProvider);
                }
              },
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 24),

            // ── Məlumat ────────────────────────────────────────────
            _SectionHeader(title: 'Məlumat'),
            _ActionRow(
              icon: Icons.upload_outlined,
              title: 'İxrac et (Export)',
              subtitle: 'Əməlləri JSON faylı kimi paylaş',
              onTap: () => _export(context),
            ),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.download_outlined,
              title: 'İdxal et (Import)',
              subtitle: 'JSON fayldan məlumatları bərpa et',
              onTap: () => _import(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────

  Future<void> _export(BuildContext context) async {
    final filePath = await ImportExportService.instance.exportData();
    if (!context.mounted) return;
    if (filePath != null) {
      final name = filePath.split('/').last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name saxlandı',
            style: GoogleFonts.nunito(color: Colors.white),
          ),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İxrac zamanı xəta baş verdi',
            style: GoogleFonts.nunito(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final previewResult = await ImportExportService.instance.previewImport();
    if (!context.mounted) return;

    switch (previewResult) {
      case PreviewCancelled():
        return;

      case PreviewInvalid():
        _showSnack(context, 'Fayl düzgün format deyil', isError: true);
        return;

      case PreviewError():
        _showSnack(context, 'İdxal zamanı xəta baş verdi', isError: true);
        return;

      case PreviewReady(:final preview):
        if (preview.isEmpty) {
          _showSnack(
            context,
            preview.identicalCount > 0
                ? 'Fayl artıq idxal edilib — heç bir yenilik yoxdur'
                : 'Fayllda heç bir əməl tapılmadı',
          );
          return;
        }

        if (preview.conflicts.isNotEmpty) {
          final confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _ConflictDialog(preview: preview),
          );
          if (!context.mounted) return;
          if (confirmed != true) return;
        }

        final result = await ImportExportService.instance.applyImport(preview);
        if (!context.mounted) return;

        final msg = switch (result) {
          ImportResult.success => _successMessage(preview),
          ImportResult.partial => 'Bəzi əməllər idxal edilə bilmədi',
          ImportResult.cancelled => null,
          ImportResult.invalid => 'Fayl düzgün format deyil',
          ImportResult.error => 'İdxal zamanı xəta baş verdi',
        };

        if (msg != null) {
          _showSnack(
            context,
            msg,
            isError:
                result == ImportResult.error || result == ImportResult.invalid,
          );
        }

        if (result == ImportResult.success || result == ImportResult.partial) {
          await ref.read(amalProvider.notifier).refresh();
        }
    }
  }

  String _successMessage(ImportPreview preview) {
    final parts = <String>[];
    if (preview.newAmals.isNotEmpty) {
      parts.add('${preview.newAmals.length} yeni əlavə edildi');
    }
    final updated = preview.conflicts.where((c) => c.useIncoming).length;
    if (updated > 0) parts.add('$updated yeniləndi');
    final skipped = preview.conflicts.where((c) => !c.useIncoming).length;
    if (skipped > 0) parts.add('$skipped mövcud saxlanıldı');
    if (preview.identicalCount > 0) {
      parts.add('${preview.identicalCount} eyni atlandı');
    }
    return parts.isEmpty
        ? 'Məlumatlar idxal edildi ✓'
        : '${parts.join(', ')} ✓';
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade400 : AppColors.accent,
        duration: const Duration(seconds: 4),
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
    if (picked != null) {
      onPicked(picked);
    }
  }
}

// ─── CONFLICT DIALOG ──────────────────────────────────────────────────────────

class _ConflictDialog extends StatefulWidget {
  final ImportPreview preview;
  const _ConflictDialog({required this.preview});

  @override
  State<_ConflictDialog> createState() => _ConflictDialogState();
}

class _ConflictDialogState extends State<_ConflictDialog> {
  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final conflicts = preview.conflicts;

    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'İdxal ziddiyyətləri',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              _summaryText(preview),
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.separator),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Column(
                children: [
                  for (int i = 0; i < conflicts.length; i++) ...[
                    _buildConflictCard(conflicts[i]),
                    if (i < conflicts.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.separator),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.separator),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ləğv et',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Tətbiq et',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _summaryText(ImportPreview p) {
    final parts = <String>[];
    if (p.newAmals.isNotEmpty) parts.add('${p.newAmals.length} yeni');
    if (p.conflicts.isNotEmpty) parts.add('${p.conflicts.length} ziddiyyətli');
    if (p.identicalCount > 0) parts.add('${p.identicalCount} eyni (atlanacaq)');
    return '${parts.join(' · ')} — hər ziddiyyət üçün seçim edin';
  }

  Widget _buildConflictCard(AmalConflict conflict) {
    final typeLabel = switch (conflict.existing.type) {
      AmalType.checkbox => 'Checkboks',
      AmalType.counter => 'Sayğac',
      AmalType.text => 'Mətn',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    conflict.existing.title,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.separator),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SidePanel(
                    label: 'Mövcud',
                    amal: conflict.existing,
                    streak: conflict.existingStreak,
                    completedDays: conflict.existingCompletedDays,
                    isSelected: !conflict.useIncoming,
                    onTap: () => setState(() => conflict.useIncoming = false),
                  ),
                ),
                Container(width: 1, color: AppColors.separator),
                Expanded(
                  child: _SidePanel(
                    label: 'Yeni fayl',
                    amal: conflict.incoming,
                    isSelected: conflict.useIncoming,
                    onTap: () => setState(() => conflict.useIncoming = true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SIDE PANEL ───────────────────────────────────────────────────────────────

class _SidePanel extends StatelessWidget {
  final String label;
  final Amal amal;
  final int? streak;
  final int? completedDays;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidePanel({
    required this.label,
    required this.amal,
    this.streak,
    this.completedDays,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.07)
            : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (streak != null && streak! > 0) ...[
              _statRow('🔥', '$streak gün ardıcıl'),
              const SizedBox(height: 2),
            ],
            if (completedDays != null && completedDays! > 0) ...[
              _statRow('✓', '$completedDays gün tamamlandı'),
              const SizedBox(height: 6),
            ],
            if (amal.type == AmalType.counter && amal.countTarget != null)
              _fieldRow('Hədəf', '${amal.countTarget}'),
            if (amal.intention != null && amal.intention!.isNotEmpty)
              _fieldRow('Niyyət', amal.intention!),
            _fieldRow(
              'Müddət',
              amal.durationDays != null ? '${amal.durationDays} gün' : 'Daimi',
            ),
            if (!amal.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Arxivdə',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _fieldRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(text: '$key: '),
            TextSpan(
              text: value,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
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
            activeTrackColor: AppColors.accentMuted,
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

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
              _fmt(time),
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

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
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
