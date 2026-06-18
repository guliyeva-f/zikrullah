import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/amal_repository.dart';
import '../../domain/amal.dart';
import '../providers/amal_provider.dart';

class AmalFormScreen extends ConsumerStatefulWidget {
  final Amal? amal;
  final bool focusContent;
  const AmalFormScreen({super.key, this.amal, this.focusContent = false});

  @override
  ConsumerState<AmalFormScreen> createState() => _AmalFormScreenState();
}

class _AmalFormScreenState extends ConsumerState<AmalFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _countCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _intentionCtrl;
  late final TextEditingController _customDurCtrl;
  final FocusNode _contentFocus = FocusNode();

  late AmalType _type;
  int? _durationPreset;
  bool _submitted = false;

  bool get _isEditing => widget.amal != null;

  static const _presets = [
    (null, 'Həmişəlik'),
    (7, '7 gün'),
    (21, '21 gün'),
    (40, '40 gün'),
    (-1, 'Fərdi'),
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.amal;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    if (widget.focusContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _contentFocus.requestFocus();
      });
    }
    _countCtrl = TextEditingController(
      text: a?.countTarget != null ? '${a!.countTarget}' : '',
    );
    _contentCtrl = TextEditingController(text: a?.content ?? '');
    _intentionCtrl = TextEditingController(text: a?.intention ?? '');
    _type = a?.type ?? AmalType.checkbox;

    final dur = a?.durationDays;
    if (dur == null) {
      _durationPreset = null;
      _customDurCtrl = TextEditingController();
    } else if ([7, 21, 40].contains(dur)) {
      _durationPreset = dur;
      _customDurCtrl = TextEditingController();
    } else {
      _durationPreset = -1;
      _customDurCtrl = TextEditingController(text: dur.toString());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _countCtrl.dispose();
    _contentCtrl.dispose();
    _intentionCtrl.dispose();
    _customDurCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  // ─── VALİDASİYA ───────────────────────────────────────────────────────────

  String? get _titleError {
    if (!_submitted) return null;
    return _titleCtrl.text.trim().isEmpty ? 'Ad yazılmalıdır' : null;
  }

  String? get _countError {
    if (!_submitted || _type != AmalType.counter) return null;
    final v = int.tryParse(_countCtrl.text.trim());
    if (v == null) return 'Say daxil et';
    if (v < 1) return 'Ən azı 1 dəfə daxil et';
    return null;
  }

  String? get _customDurError {
    if (!_submitted || _durationPreset != -1) return null;
    final v = int.tryParse(_customDurCtrl.text.trim());
    return (v == null || v < 1) ? 'Ən azı 1 gün daxil et' : null;
  }

  int? get _resolvedDuration {
    if (_durationPreset == null) return null;
    if (_durationPreset == -1) return int.tryParse(_customDurCtrl.text.trim());
    return _durationPreset;
  }

  bool get _isValid {
    if (_titleCtrl.text.trim().isEmpty) {
      return false;
    }
    if (_type == AmalType.counter &&
        (int.tryParse(_countCtrl.text.trim()) ?? 0) < 1) {
      return false;
    }
    if (_durationPreset == -1 &&
        (int.tryParse(_customDurCtrl.text.trim()) ?? 0) < 1) {
      return false;
    }
    return true;
  }

  // ─── SAXLA ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_isValid) return;

    final title = _titleCtrl.text.trim();
    final intention = _intentionCtrl.text.trim().isEmpty
        ? null
        : _intentionCtrl.text.trim();
    final countTarget = _type == AmalType.counter
        ? (int.tryParse(_countCtrl.text.trim()) ?? 1)
        : null;
    final content = _type == AmalType.text ? _contentCtrl.text.trim() : null;

    if (_isEditing) {
      await ref
          .read(amalProvider.notifier)
          .updateAmal(
            widget.amal!.copyWith(
              title: title,
              type: _type,
              countTarget: countTarget,
              content: content,
              intention: intention,
              durationDays: _resolvedDuration,
            ),
          );
    } else {
      final sortOrder = await AmalRepository().getNextSortOrder();
      await ref
          .read(amalProvider.notifier)
          .addAmal(
            Amal(
              id: 0,
              title: title,
              type: _type,
              countTarget: countTarget,
              content: content,
              sortOrder: sortOrder,
              isActive: true,
              createdAt: DateFormat(
                "yyyy-MM-dd'T'HH:mm:ss",
              ).format(DateTime.now()),
              intention: intention,
              durationDays: _resolvedDuration,
            ),
          );
    }

    if (mounted) Navigator.pop(context);
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          _isEditing ? 'Düzəliş et' : 'Yeni əməl',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isEditing ? 'Yenilə' : 'Hazır',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Əməlin adı'),
            const SizedBox(height: 6),
            _titleField(),
            const SizedBox(height: 24),

            _label('Necə icra edilir?'),
            const SizedBox(height: 10),
            _typeSelector(),
            const SizedBox(height: 24),

            if (_type == AmalType.counter) ...[
              _label('Neçə dəfə?'),
              const SizedBox(height: 6),
              _countField(),
              const SizedBox(height: 24),
            ],

            if (_type == AmalType.text) ...[
              _label('Dua / ziyarətnamə mətni'),
              const SizedBox(height: 6),
              _contentField(),
              const SizedBox(height: 24),
            ],

            _label('Neçə günlük söz verirsən?'),
            const SizedBox(height: 10),
            _durationSelector(),
            if (_durationPreset == -1) ...[
              const SizedBox(height: 10),
              _customDurationField(),
            ],
            const SizedBox(height: 24),

            _label('Niyyətin (nə üçün başlayırsan?)'),
            const SizedBox(height: 6),
            _intentionField(),
          ],
        ),
      ),
    );
  }

  // ─── FORM WİDGETS ─────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );

  InputDecoration _dec({String? hint, String? error}) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.nunito(color: AppColors.textHint, fontSize: 14),
    errorText: error,
    errorStyle: GoogleFonts.nunito(fontSize: 12),
    filled: true,
    fillColor: AppColors.bgCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade300),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
    ),
  );

  Widget _titleField() => TextField(
    controller: _titleCtrl,
    maxLength: 60,
    maxLengthEnforcement: MaxLengthEnforcement.enforced,
    textCapitalization: TextCapitalization.sentences,
    onChanged: (_) {
      if (_submitted) setState(() {});
    },
    style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textPrimary),
    decoration:
        _dec(
          hint: 'Aşura ziyarətnaməsi, Nüdbə duası, 100 salavat..',
          error: _titleError,
        ).copyWith(
          counterText: '',
          counter: ValueListenableBuilder(
            valueListenable: _titleCtrl,
            builder: (_, value, _) {
              final len = value.text.length;
              if (len <= 50) return const SizedBox.shrink();
              return Text(
                '$len/60',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: len >= 60 ? Colors.red.shade400 : AppColors.textHint,
                ),
              );
            },
          ),
        ),
  );

  Widget _typeSelector() {
    final types = [
      (AmalType.checkbox, '✓', 'Sadə'),
      (AmalType.counter, '📿', 'Zikr'),
      (AmalType.text, '📖', 'Qiraət'),
    ];

    return Row(
      children: [
        for (int i = 0; i < types.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = types[i].$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: _type == types[i].$1
                      ? AppColors.accent.withValues(alpha: 0.10)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _type == types[i].$1
                        ? AppColors.accent
                        : AppColors.border,
                    width: _type == types[i].$1 ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      types[i].$2,
                      style: TextStyle(
                        fontSize: 20,
                        color: _type == types[i].$1
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      types[i].$3,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _type == types[i].$1
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (i < types.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _countField() => SizedBox(
    width: double.infinity,
    child: TextField(
      controller: _countCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) {
        if (_submitted) setState(() {});
      },
      style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textPrimary),
      decoration: _dec(hint: 'say yaz.. məs: 100, 500', error: _countError),
    ),
  );

  Widget _contentField() => TextField(
    controller: _contentCtrl,
    focusNode: _contentFocus,
    maxLines: null,
    minLines: 8,
    style: GoogleFonts.scheherazadeNew(
      textStyle: GoogleFonts.nunito(
        fontSize: 16,
        height: 1.9,
        color: AppColors.textPrimary,
      ),
    ),
    decoration: _dec(
      hint: 'Dua, ziyarətnamə, zikr və ya oxunacaq mətni bura yaz..',
    ).copyWith(contentPadding: const EdgeInsets.all(14)),
  );

  Widget _durationSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presets.map((p) {
        final selected = _durationPreset == p.$1;
        return GestureDetector(
          onTap: () => setState(() => _durationPreset = p.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.10)
                  : AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              p.$2,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _customDurationField() => SizedBox(
    width: double.infinity,
    child: TextField(
      controller: _customDurCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) {
        if (_submitted) setState(() {});
      },
      style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textPrimary),
      decoration: _dec(hint: 'özün yaz... məs: 10', error: _customDurError),
    ),
  );

  Widget _intentionField() => TextField(
    controller: _intentionCtrl,
    maxLines: 3,
    minLines: 2,
    textCapitalization: TextCapitalization.sentences,
    style: GoogleFonts.nunito(
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    decoration: _dec(
      hint: 'Qəlbindəkini yaz — Allah üçün, özün üçün... 🤍',
    ).copyWith(contentPadding: const EdgeInsets.all(14)),
  );
}
