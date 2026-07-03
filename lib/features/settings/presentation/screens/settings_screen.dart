import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../amal/data/import_export_service.dart';
import '../../../amal/domain/amal.dart';
import '../../../amal/presentation/providers/amal_provider.dart';
import '../providers/settings_provider.dart';
import 'about_screen.dart';
import '../../../../core/notifications/notification_permission_helper.dart';
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
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Parametrlər',
          style: TextStyle(
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
              const Text(
                'Bir şey səhv getdi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(settingsProvider),
                child: const Text(
                  'Yenidən cəhd et',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        data: (state) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  // ── Bildirişlər ──────────────────────────────────────
                  const _SectionLabel(label: 'Bildirişlər'),
                  _ToggleRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Gündəlik bildirişlər',
                    subtitle: 'Zikr vaxtlarını xatırlat',
                    value: state.notificationsEnabled,
                    onChanged: (v) => _handleNotifToggle(v, context),
                  ),
                  const SizedBox(height: 20),
                  AnimatedOpacity(
                    opacity: state.notificationsEnabled ? 1.0 : 0.38,
                    duration: const Duration(milliseconds: 220),
                    child: AbsorbPointer(
                      absorbing: !state.notificationsEnabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'Vaxtlar'),
                          _GroupCard(
                            children: [
                              _TimeRow(
                                emoji: '☀️',
                                label: 'Səhər',
                                time: state.morningTime,
                                onTap: () => _pickTime(
                                  context,
                                  current: state.morningTime,
                                  onPicked: (t) => ref
                                      .read(settingsProvider.notifier)
                                      .setMorningTime(t),
                                ),
                              ),
                              const _Separator(),
                              _TimeRow(
                                emoji: '⛅',
                                label: 'Günorta',
                                time: state.noonTime,
                                onTap: () => _pickTime(
                                  context,
                                  current: state.noonTime,
                                  onPicked: (t) => ref
                                      .read(settingsProvider.notifier)
                                      .setNoonTime(t),
                                ),
                              ),
                              const _Separator(),
                              _TimeRow(
                                emoji: '🌆',
                                label: 'Axşam',
                                time: state.eveningTime,
                                onTap: () => _pickTime(
                                  context,
                                  current: state.eveningTime,
                                  onPicked: (t) => ref
                                      .read(settingsProvider.notifier)
                                      .setEveningTime(t),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const _SectionLabel(label: 'Gecə bildirişi'),
                          _ToggleRow(
                            icon: Icons.bedtime_outlined,
                            title: 'Gecə xatırlatması',
                            subtitle: 'Hər gecə saat 23:00-da',
                            value: state.nightNotifEnabled,
                            onChanged: (v) => ref
                                .read(settingsProvider.notifier)
                                .setNightEnabled(v),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  // ── Yedəklə / Bərpa ─────────────────────────────────
                  const _SectionLabel(label: 'Yedəklə / Bərpa'),
                  _GroupCard(
                    children: [
                      _ActionRow(
                        icon: Icons.upload_outlined,
                        label: 'Məlumatları ixrac et',
                        subtitle: 'Əməlləri fayl kimi paylaş və yedəklə',
                        onTap: () => _export(context),
                      ),
                      const _Separator(),
                      _ActionRow(
                        icon: Icons.download_outlined,
                        label: 'Məlumatları idxal et',
                        subtitle: 'Əvvəlki yedəkdən bərpa et',
                        onTap: () => _import(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Haqqında — ekranın altına sabit ────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: _GroupCard(
                  children: [
                    _ActionRow(
                      icon: Icons.info_outline,
                      label: 'Haqqında',
                      subtitle: 'Tətbiq, funksionallıq və məxfilik',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
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
  // ─── NOTIFICATION TOGGLE ─────────────────────────────────────────────────
  Future<void> _handleNotifToggle(bool v, BuildContext context) async {
    if (v) {
      final granted = await NotificationService().requestPermission();
      if (!context.mounted) return;
      if (granted) {
        await ref.read(settingsProvider.notifier).setNotificationsEnabled(true);
        ref.invalidate(notifDeclinedProvider);
      } else {
        _showSnack(
          context,
          'İcazə rədd edildi. Telefon parametrlərindən aç.',
          isError: true,
          actionLabel: 'Aç',
          onAction: () async {
            _waitingForSettings = true;
            await NotificationService().openSystemSettings();
          },
        );
      }
    } else {
      await ref.read(settingsProvider.notifier).setNotificationsEnabled(false);
      ref.invalidate(notifDeclinedProvider);
    }
  }
  // ─── EXPORT ──────────────────────────────────────────────────────────────
  Future<void> _export(BuildContext context) async {
    final result = await ImportExportService.instance.exportData();
    if (!context.mounted) return;
    if (result == null) {
      _showSnack(context, 'İxrac zamanı xəta baş verdi', isError: true);
      return;
    }
    final fileName = result.path.split('/').last;
    final msg = result.saved
        ? 'İxrac edildi: $fileName ✓'
        : 'Paylaşıldı, lakin qovluğa saxlanılmadı ($fileName)';
    _showSnack(context, msg);
  }
  // ─── IMPORT ──────────────────────────────────────────────────────────────
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
          if (preview.identicalCount > 0) {
            _showSnack(context, 'Fayl artıq idxal edilib, yenilik yoxdur');
          } else {
            _showSnack(context, 'Faylda heç bir əməl tapılmadı');
          }
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
        final isError =
            result == ImportResult.error || result == ImportResult.invalid;
        final msg = switch (result) {
          ImportResult.success => _successMessage(preview),
          ImportResult.partial => 'Bəzi əməllər idxal edilə bilmədi',
          ImportResult.cancelled => null,
          ImportResult.invalid => 'Fayl düzgün format deyil',
          ImportResult.error => 'İdxal zamanı xəta baş verdi',
        };
        if (msg != null) _showSnack(context, msg, isError: isError);
        if (result == ImportResult.success || result == ImportResult.partial) {
          await ref.read(amalProvider.notifier).refresh();
          if (!context.mounted) return;
          await requestNotifIfNeeded(context, ref);
        }
    }
  }
  // ─── SUCCESS MESSAGE ─────────────────────────────────────────────────────
  String _successMessage(ImportPreview preview) {
    final parts = <String>[];
    if (preview.newAmals.isNotEmpty) {
      parts.add('${preview.newAmals.length} yeni əməl əlavə edildi');
    }
    final updated = preview.conflicts.where((c) => c.useIncoming).length;
    if (updated > 0) parts.add('$updated yeniləndi');
    final skipped = preview.conflicts.where((c) => !c.useIncoming).length;
    if (skipped > 0) parts.add('$skipped dəyişdirilmədi');
    if (preview.identicalCount > 0) {
      parts.add('${preview.identicalCount} eyni (artıq var) atlandı');
    }
    return parts.isEmpty
        ? 'Məlumatlar idxal edildi ✓'
        : '${parts.join(' · ')} ✓';
  }
  // ─── SNACKBAR ────────────────────────────────────────────────────────────
  void _showSnack(
    BuildContext context,
    String msg, {
    bool isError = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFC0594A) : AppColors.accent,
        duration: Duration(seconds: actionLabel != null ? 7 : 4),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
  // ─── TIME PICKER ─────────────────────────────────────────────────────────
  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay current,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: const TimePickerThemeData(
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
// ─── CONFLICT DIALOG ─────────────────────────────────────────────────────────
class _ConflictDialog extends StatefulWidget {
  final ImportPreview preview;
  const _ConflictDialog({required this.preview});
  @override
  State<_ConflictDialog> createState() => _ConflictDialogState();
}
class _ConflictDialogState extends State<_ConflictDialog> {
  @override
  Widget build(BuildContext context) {
    final conflicts = widget.preview.conflicts;
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Üst-üstə düşən əməllər',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              _summaryLine(widget.preview),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.separator),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
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
                    child: const Text(
                      'Ləğv et',
                      style: TextStyle(
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
                    child: const Text(
                      'Tətbiq et',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
  String _summaryLine(ImportPreview p) {
    final parts = <String>[];
    if (p.newAmals.isNotEmpty) parts.add('${p.newAmals.length} yeni');
    if (p.conflicts.isNotEmpty) parts.add('${p.conflicts.length} üst-üstə');
    if (p.identicalCount > 0) parts.add('${p.identicalCount} eyni (atlanacaq)');
    return '${parts.join(' · ')} — hansını saxlamaq istədiyini seç';
  }
  Widget _buildConflictCard(AmalConflict conflict) {
    final typeLabel = switch (conflict.existing.type) {
      AmalType.checkbox => '✓ Gündəlik',
      AmalType.counter => '📿 Zikr',
      AmalType.text => '📖 Qiraət',
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 12,
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
                    label: 'Cihazda olan',
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
                    label: 'Yeni fayldakı',
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
// ─── SIDE PANEL ──────────────────────────────────────────────────────────────
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
        duration: const Duration(milliseconds: 160),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
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
              const SizedBox(height: 4),
            ],
            if (amal.type == AmalType.counter && amal.countTarget != null)
              _fieldRow('Hədəf', '${amal.countTarget}'),
            if (amal.intention != null && amal.intention!.isNotEmpty)
              _fieldRow('Niyyət', amal.intention!),
            _fieldRow(
              'Müddət',
              amal.durationDays != null
                  ? '${amal.durationDays} gün'
                  : '∞ Həmişəlik',
            ),
            if (!amal.isActive)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '· arxivdə',
                  style: TextStyle(
                    fontSize: 12,
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
  Widget _statRow(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 1),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
  Widget _fieldRow(String key, String value) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$key: ',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
// ─── SHARED WIDGETS ──────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 0.9,
      ),
    ),
  );
}
class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: children),
  );
}
class _Separator extends StatelessWidget {
  const _Separator();
  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: AppColors.separator,
  );
}
class _TimeRow extends StatelessWidget {
  final String emoji;
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeRow({
    required this.emoji,
    required this.label,
    required this.time,
    required this.onTap,
  });
  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            _fmt(time),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
        ],
      ),
    ),
  );
}
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
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
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
        ],
      ),
    ),
  );
}
