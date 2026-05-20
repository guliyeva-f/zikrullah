import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/amal.dart';
import '../providers/amal_provider.dart';
import 'amal_form_screen.dart';

class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(amalProvider);

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
          'Əməllərim',
          style: GoogleFonts.nunito(
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
        error: (e, _) => Center(child: Text('Xəta: $e')),
        data: (state) {
          if (state.amals.isEmpty) {
            return Center(
              child: Text(
                'Hələ əməl yoxdur.\nYuxarıdakı + ilə əlavə et.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.textHint,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            );
          }
          return ReorderableListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            buildDefaultDragHandles: false, // özümüz handle əlavə edirik
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final list = [...state.amals];
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              ref.read(amalProvider.notifier).updateSortOrders(list);
            },
            children: [
              for (int i = 0; i < state.amals.length; i++)
                _AmalManageRow(
                  key: ValueKey(state.amals[i].id),
                  amal: state.amals[i],
                  index: i,
                  onEdit: () => _openForm(context, ref, state.amals[i]),
                  onDelete: () => _confirmDelete(context, ref, state.amals[i]),
                ),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Silmək istəyirsiniz?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 17,
          ),
        ),
        content: Text(
          '"${amal.title}" əməlinin bütün tarixçəsi silinəcək.',
          style: GoogleFonts.nunito(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Ləğv et',
              style: GoogleFonts.nunito(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(amalProvider.notifier).deleteAmal(amal.id);
            },
            child: Text(
              'Sil',
              style: GoogleFonts.nunito(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AMAL MANAGE ROW ─────────────────────────────────────────────────────────

class _AmalManageRow extends StatelessWidget {
  final Amal amal;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AmalManageRow({
    super.key,
    required this.amal,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  String get _typeLabel {
    switch (amal.type) {
      case AmalType.checkbox:
        return 'Checkbox';
      case AmalType.counter:
        return 'Sayğac';
      case AmalType.text:
        return 'Mətnli';
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
          // Drag handle — ReorderableDragStartListener ilə işləyir
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Icon(
                Icons.drag_handle,
                color: AppColors.textHint,
                size: 20,
              ),
            ),
          ),
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _typeLabel,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Text(
              amal.title,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Edit
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Delete
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.red.shade300,
            ),
            onPressed: onDelete,
            padding: const EdgeInsets.only(right: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
