import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/amal.dart';
import '../../domain/amal_record.dart';
import '../providers/amal_provider.dart';

class TextScreen extends ConsumerStatefulWidget {
  final Amal amal;
  final AmalRecord? record;

  const TextScreen({super.key, required this.amal, required this.record});

  @override
  ConsumerState<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends ConsumerState<TextScreen> {
  final _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    setState(() {
      _scrollProgress = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _complete() async {
    await ref.read(amalProvider.notifier).completeCheckbox(widget.amal.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final liveRecord = ref.watch(amalProvider).value?.records[widget.amal.id];
    final isCompleted =
        liveRecord?.isCompleted ?? widget.record?.isCompleted ?? false;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _buildAppBar(isCompleted),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _scrollProgress,
            backgroundColor: AppColors.bgElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 3,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.amal.content ?? '',
                    style: GoogleFonts.scheherazadeNew(
                      fontSize: 17,
                      height: 2.0,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isCompleted ? null : _complete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor: AppColors.bgElevated,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isCompleted ? 'Tamamlandı ✓' : 'Tamamladım',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isCompleted) {
    return AppBar(
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
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.amal.title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (isCompleted)
            Text(
              'Tamamlandı ✓',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
