import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/amal.dart';
import '../../domain/amal_record.dart';
import '../providers/amal_provider.dart';
import 'amal_form_screen.dart';

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

  List<TextSpan> _buildMixedSpans(String text) {
    final arabicRegex = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]+',
    );
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in arabicRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: GoogleFonts.nunito(
              fontSize: 16,
              height: 2.0,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: GoogleFonts.scheherazadeNew(
            fontSize: 22,
            height: 2.0,
            color: AppColors.textPrimary,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: GoogleFonts.nunito(
            fontSize: 16,
            height: 2.0,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    return spans.isEmpty
        ? [
            TextSpan(
              text: text,
              style: GoogleFonts.nunito(
                fontSize: 16,
                height: 2.0,
                color: AppColors.textPrimary,
              ),
            ),
          ]
        : spans;
  }

  @override
  Widget build(BuildContext context) {
    final liveRecord = ref.watch(amalProvider).value?.records[widget.amal.id];
    final isCompleted =
        liveRecord?.isCompleted ?? widget.record?.isCompleted ?? false;

    final hasContent =
        widget.amal.content != null && widget.amal.content!.trim().isNotEmpty;
    final hasIntention =
        widget.amal.intention != null &&
        widget.amal.intention!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _buildAppBar(isCompleted),
      body: Column(
        children: [
          // ── İncə progress xətti ──────────────────────────────────────────
          LinearProgressIndicator(
            value: _scrollProgress,
            backgroundColor: AppColors.bgElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 1.5,
          ),

          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Niyyət bloku (varsa, məhdud yüksəklikdə) ─────────────
                  if (hasIntention) ...[
                    _IntentionBox(intention: widget.amal.intention!),
                    const SizedBox(height: 20),
                    Divider(color: AppColors.separator, thickness: 1),
                    const SizedBox(height: 20),
                  ],

                  // ── Əsas mətn və ya boş hal ───────────────────────────────
                  if (hasContent)
                    SelectableText.rich(
                      TextSpan(
                        children: _buildMixedSpans(widget.amal.content!),
                      ),
                      textAlign: TextAlign.justify,
                    )
                  else
                    _EmptyContent(amal: widget.amal),

                  const SizedBox(height: 48),

                  // ── Tamamla düyməsi ───────────────────────────────────────
                  if (hasContent)
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
                          isCompleted ? 'Oxundu ✓' : 'Bitirdim',
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
              'oxundu ✓',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Niyyət bloku — məhdud hündürlük, görünməz scroll ────────────────────────

class _IntentionBox extends StatelessWidget {
  final String intention;
  const _IntentionBox({required this.intention});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 80),
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          child: Text(
            intention,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textHint,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Boş məzmun halı ──────────────────────────────────────────────────────────

class _EmptyContent extends StatelessWidget {
  final Amal amal;
  const _EmptyContent({required this.amal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text('📄', style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 16),
          Text(
            'Bu əməlin oxunacaq mətni hələ yazılmayıb',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AmalFormScreen(amal: amal, focusContent: true),
                ),
              );
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(
              'Məzmun əlavə et',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accentMuted),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
