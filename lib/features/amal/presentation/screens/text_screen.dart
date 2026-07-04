import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/font_size_provider.dart';
import '../../domain/amal.dart';
import '../../domain/amal_record.dart';
import '../providers/amal_provider.dart';
import 'amal_form_screen.dart';
import '../../../../core/utils/text_direction.dart';
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
  bool _autoCompleted = false;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    final newProgress = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    if (_scrollProgress != newProgress) {
      setState(() => _scrollProgress = newProgress);
    }
    final isCompleted =
        ref.read(amalProvider).value?.records[widget.amal.id]?.isCompleted ??
        widget.record?.isCompleted ??
        false;
    if (newProgress >= 1 && !isCompleted && !_autoCompleted) {
      _autoCompleted = true;
      _markCompleted();
    }
  }
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  Future<void> _markCompleted() async {
    await ref.read(amalProvider.notifier).completeCheckbox(widget.amal.id);
  }
  Future<void> _completeAndClose() async {
    await _markCompleted();
    if (mounted) {
      Navigator.pop(context);
    }
  }
  List<TextSpan> _buildMixedSpans(
    String text,
    double latinSize,
    double arabicSize,
  ) {
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
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              fontSize: latinSize,
              height: 2.0,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            fontFamily: 'Scheherazade New',
            fontWeight: FontWeight.w400,
            fontSize: arabicSize,
            height: 2.5,
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
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            fontSize: latinSize,
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
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                fontSize: latinSize,
                height: 2.0,
                color: AppColors.textPrimary,
              ),
            ),
          ]
        : spans;
  }
  List<Widget> _buildParagraphs(
    String text,
    double latinSize,
    double arabicSize,
  ) {
    final paragraphs = text.split('\n');
    final widgets = <Widget>[];
    for (var i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i];
      if (para.trim().isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }
      widgets.add(
        SelectableText.rich(
          TextSpan(children: _buildMixedSpans(para, latinSize, arabicSize)),
          textAlign: TextAlign.justify,
          textDirection: detectTextDirection(para),
        ),
      );
      if (i < paragraphs.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }
  // ─── Font ölçüsü paneli ("Aa") ───────────────────────────────────────────
  void _showFontSizeSheet(String content) {
    final showArabic = hasArabicScript(content);
    final showLatin = hasLatinScript(content);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(
        builder: (context, sheetRef, _) {
          final sizes = sheetRef.watch(fontSizeProvider);
          final latin = sizes.value?.latin ?? FontSizeLimits.defaultLatin;
          final arabic = sizes.value?.arabic ?? FontSizeLimits.defaultArabic;
          final notifier = sheetRef.read(fontSizeProvider.notifier);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Mətn ölçüsü',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dəyişiklik dərhal tətbiq olunur və bütün mətnlərə aiddir',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                  if (showLatin) ...[
                    const SizedBox(height: 20),
                    _FontSizeRow(
                      label: 'Azərbaycanca',
                      valuePx: latin,
                      onDecrease: latin <= FontSizeLimits.minLatin
                          ? null
                          : notifier.decreaseLatin,
                      onIncrease: latin >= FontSizeLimits.maxLatin
                          ? null
                          : notifier.increaseLatin,
                    ),
                  ],
                  if (showArabic) ...[
                    const SizedBox(height: 16),
                    _FontSizeRow(
                      label: 'Ərəbcə',
                      valuePx: arabic,
                      onDecrease: arabic <= FontSizeLimits.minArabic
                          ? null
                          : notifier.decreaseArabic,
                      onIncrease: arabic >= FontSizeLimits.maxArabic
                          ? null
                          : notifier.increaseArabic,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
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
    final fontSizes = ref.watch(fontSizeProvider);
    final latinSize = fontSizes.value?.latin ?? FontSizeLimits.defaultLatin;
    final arabicSize = fontSizes.value?.arabic ?? FontSizeLimits.defaultArabic;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _buildAppBar(isCompleted, hasContent),
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
                    const Divider(color: AppColors.separator, thickness: 1),
                    const SizedBox(height: 20),
                  ],
                  // ── Əsas mətn və ya boş hal ───────────────────────────────
                  if (hasContent)
                    ..._buildParagraphs(
                      widget.amal.content!,
                      latinSize,
                      arabicSize,
                    )
                  else
                    _EmptyContent(amal: widget.amal),
                  const SizedBox(height: 64),
                  // ── Tamamla düyməsi ───────────────────────────────────────
                  if (hasContent)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isCompleted ? null : _completeAndClose,
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
                          style: const TextStyle(
                            fontSize: 16,
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
  PreferredSizeWidget _buildAppBar(bool isCompleted, bool hasContent) {
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (isCompleted)
            const Text(
              'oxundu ✓',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        if (hasContent)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showFontSizeSheet(widget.amal.content!),
              tooltip: 'Mətn ölçüsü',
              icon: const Text(
                'Aa',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
// ─── Font ölçüsü sətri — A- / dəyər / A+ ─────────────────────────────────────
class _FontSizeRow extends StatelessWidget {
  final String label;
  final double valuePx;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  const _FontSizeRow({
    required this.label,
    required this.valuePx,
    required this.onDecrease,
    required this.onIncrease,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _StepButton(icon: Icons.remove, onTap: onDecrease),
        SizedBox(
          width: 44,
          child: Text(
            '${valuePx.toInt()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _StepButton(icon: Icons.add, onTap: onIncrease),
      ],
    );
  }
}
class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.bgElevated : AppColors.bgCard,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
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
            style: const TextStyle(
              fontSize: 14,
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
          const Text('📄', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 16),
          const Text(
            'Bu əməl üçün hələ mətn əlavə edilməyib',
            style: TextStyle(
              fontSize: 16,
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
            label: const Text(
              'Mətni əlavə et',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
