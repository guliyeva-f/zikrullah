import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/amal.dart';
import '../providers/amal_provider.dart';
import 'amal_form_screen.dart';
import 'amal_detail_screen.dart';
import '../../data/amal_repository.dart';

final _archivedAmalsProvider =
    FutureProvider.autoDispose<List<({Amal amal, int completedDays})>>((
      ref,
    ) async {
      return AmalRepository().getArchivedAmalsWithStats();
    });

class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(amalProvider);
    final asyncArchived = ref.watch(_archivedAmalsProvider);

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
        title: const Text(
          'Əməllərim',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent, size: 26),
            onPressed: () => _openForm(context, ref, null),
          ),
        ],
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
                'Bir xəta baş verdi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(amalProvider),
                child: const Text(
                  'Yenidən cəhd et',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        data: (state) {
          final archivedList = asyncArchived.value ?? [];

          if (state.amals.isEmpty && archivedList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌙', style: TextStyle(fontSize: 44)),
                  SizedBox(height: 16),
                  Text(
                    'Hələ heç nə yoxdur',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Yuxarıdakı + ilə ilk niyyətini yarat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (state.amals.isNotEmpty)
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  buildDefaultDragHandles: false,
                  onReorderItem: (oldIndex, newIndex) {
                    final list = [...state.amals];
                    final item = list.removeAt(oldIndex);
                    list.insert(newIndex, item);
                    ref.read(amalProvider.notifier).updateSortOrders(list);
                  },
                  children: [
                    for (int i = 0; i < state.amals.length; i++)
                      _AmalManageCard(
                        key: ValueKey(state.amals[i].id),
                        amal: state.amals[i],
                        index: i,
                        onInfo: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AmalDetailScreen(amal: state.amals[i]),
                          ),
                        ),
                        onEdit: () => _openForm(context, ref, state.amals[i]),
                        onDelete: () =>
                            _confirmDelete(context, ref, state.amals[i]),
                      ),
                  ],
                ),

              if (archivedList.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Text(
                      'Bitmiş əhdlər',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Divider(color: AppColors.separator, height: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final entry in archivedList)
                  _ArchivedAmalCard(
                    key: ValueKey('archived_${entry.amal.id}'),
                    amal: entry.amal,
                    completedDays: entry.completedDays,
                    onInfo: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AmalDetailScreen(amal: entry.amal),
                      ),
                    ),
                    onRestart: () async {
                      await ref
                          .read(amalProvider.notifier)
                          .reactivateAmal(entry.amal.id);
                      ref.invalidate(_archivedAmalsProvider);
                    },
                    onDelete: () => _confirmDelete(context, ref, entry.amal),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, Amal? amal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AmalFormScreen(amal: amal)),
    ).then((_) => ref.read(amalProvider.notifier).refresh());
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Amal amal) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Silinsin?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 17,
          ),
        ),
        content: Text(
          '"${amal.title}" əməlinə aid bütün tarixçə silinəcək.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Ləğv et',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(amalProvider.notifier).deleteAmal(amal.id);
              ref.invalidate(_archivedAmalsProvider);
            },
            child: const Text(
              'Sil',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CARD ─────────────────────────────────────────────────────────────────────

class _AmalManageCard extends StatelessWidget {
  final Amal amal;
  final int index;
  final VoidCallback onInfo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AmalManageCard({
    super.key,
    required this.amal,
    required this.index,
    required this.onInfo,
    required this.onEdit,
    required this.onDelete,
  });

  String get _typeIcon {
    switch (amal.type) {
      case AmalType.checkbox:
        return '✓';
      case AmalType.counter:
        return '📿';
      case AmalType.text:
        return '📖';
    }
  }

  String get _typeLabel {
    switch (amal.type) {
      case AmalType.checkbox:
        return 'Sadə';
      case AmalType.counter:
        return 'Zikr';
      case AmalType.text:
        return 'Qiraət';
    }
  }

  Color get _badgeColor {
    switch (amal.type) {
      case AmalType.checkbox:
        return const Color(0xFF5A8A5E);
      case AmalType.counter:
        return AppColors.accent;
      case AmalType.text:
        return const Color(0xFF6B7FA3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Icon(
                Icons.drag_handle,
                color: AppColors.textHint,
                size: 18,
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: _badgeColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _typeIcon,
                          style: TextStyle(fontSize: 10, color: _badgeColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amal.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),

          // ── Action zone ───────────────────────────────────────────────────
          Container(
            height: 52,
            width: 1,
            color: AppColors.separator,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          _ActionButton(
            icon: Icons.info_outline,
            color: AppColors.textSecondary,
            onTap: onInfo,
          ),
          Container(height: 28, width: 1, color: AppColors.separator),
          _ActionButton(
            icon: Icons.edit_outlined,
            color: AppColors.textSecondary,
            onTap: onEdit,
          ),
          Container(height: 28, width: 1, color: AppColors.separator),
          _ActionButton(
            icon: Icons.delete_outline,
            color: AppColors.error,
            onTap: onDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 40,
        height: 52,
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

// ─── ARXİVLƏNMİŞ KART ─────────────────────────────────────────────────────────

class _ArchivedAmalCard extends StatelessWidget {
  final Amal amal;
  final int completedDays;
  final VoidCallback onInfo;
  final VoidCallback onRestart;
  final VoidCallback onDelete;

  const _ArchivedAmalCard({
    super.key,
    required this.amal,
    required this.completedDays,
    required this.onInfo,
    required this.onRestart,
    required this.onDelete,
  });

  bool get _fullyCompleted => completedDays >= (amal.durationDays ?? 0);

  String get _typeIcon {
    switch (amal.type) {
      case AmalType.checkbox:
        return '✓';
      case AmalType.counter:
        return '📿';
      case AmalType.text:
        return '📖';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(_typeIcon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        _fullyCompleted ? '✅ Tamamlandı' : '⏳ Yarımçıq qaldı',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _fullyCompleted
                              ? const Color(0xFF5A8A5E)
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amal.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completedDays/${amal.durationDays ?? completedDays} gün',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 52,
            width: 1,
            color: AppColors.separator,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          _ActionButton(
            icon: Icons.info_outline,
            color: AppColors.textSecondary,
            onTap: onInfo,
          ),
          Container(height: 28, width: 1, color: AppColors.separator),
          _ActionButton(
            icon: Icons.refresh,
            color: AppColors.accent,
            onTap: onRestart,
          ),
          Container(height: 28, width: 1, color: AppColors.separator),
          _ActionButton(
            icon: Icons.delete_outline,
            color: AppColors.error,
            onTap: onDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
