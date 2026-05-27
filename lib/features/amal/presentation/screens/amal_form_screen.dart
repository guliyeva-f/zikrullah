import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/amal.dart';
import '../providers/amal_provider.dart';

class AmalFormScreen extends ConsumerStatefulWidget {
  final Amal? amal;
  const AmalFormScreen({super.key, this.amal});

  @override
  ConsumerState<AmalFormScreen> createState() => _AmalFormScreenState();
}

class _AmalFormScreenState extends ConsumerState<AmalFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _countCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _intentionCtrl;
  late final TextEditingController _customDurCtrl;

  late AmalType _type;
  int? _durationPreset;
  bool _submitted = false;

  bool get _isEditing => widget.amal != null;

  static const _presets = [
    (null, 'Daimi'),
    (7, '7 gün'),
    (21, '21 gün'),
    (40, '40 gün'),
    (-1, 'Özün'),
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.amal;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _countCtrl = TextEditingController(text: '${a?.countTarget ?? 1}');
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
    super.dispose();
  }

  // ─── VALİDASİYA ───────────────────────────────────────────────────────────

  String? get _titleError {
    if (!_submitted) return null;
    return _titleCtrl.text.trim().isEmpty ? 'Ad boş ola bilməz' : null;
  }

  String? get _countError {
    if (!_submitted || _type != AmalType.counter) return null;
    final v = int.tryParse(_countCtrl.text.trim());
    return (v == null || v < 1) ? 'Minimum 1 olmalıdır' : null;
  }

  String? get _customDurError {
    if (!_submitted || _durationPreset != -1) return null;
    final v = int.tryParse(_customDurCtrl.text.trim());
    return (v == null || v < 1) ? 'Minimum 1 gün daxil et' : null;
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
      final sortOrder = DateTime.now().millisecondsSinceEpoch ~/ 1000;

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
          _isEditing ? 'Düzəlt' : 'Yeni əməl',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _save,
              child: Text(
                'Saxla',
                style: GoogleFonts.nunito(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Ad'),
            const SizedBox(height: 6),
            _titleField(),
            const SizedBox(height: 20),

            _label('Növ'),
            const SizedBox(height: 8),
            _typeSelector(),
            const SizedBox(height: 20),

            if (_type == AmalType.counter) ...[
              _label('Hədəf say'),
              const SizedBox(height: 6),
              _countField(),
              const SizedBox(height: 20),
            ],

            if (_type == AmalType.text) ...[
              _label('Mətn'),
              const SizedBox(height: 6),
              _contentField(),
              const SizedBox(height: 20),
            ],

            _label('Müddət'),
            const SizedBox(height: 8),
            _durationSelector(),
            if (_durationPreset == -1) ...[
              const SizedBox(height: 10),
              _customDurationField(),
            ],
            const SizedBox(height: 20),

            _label('Niyyət (istəyə görə)'),
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
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );

  InputDecoration _dec({String? hint, String? error}) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.nunito(color: AppColors.textHint, fontSize: 14),
    errorText: error,
    errorStyle: GoogleFonts.nunito(fontSize: 12),
    filled: true,
    fillColor: AppColors.bgCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    onChanged: (_) {
      if (_submitted) setState(() {});
    },
    style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textPrimary),
    decoration: _dec(hint: 'Məsələn: Sübh namazı', error: _titleError),
  );

  Widget _typeSelector() {
    const types = [
      (AmalType.checkbox, 'Checkbox'),
      (AmalType.counter, 'Sayğac'),
      (AmalType.text, 'Mətnli'),
    ];
    return Row(
      children: [
        for (int i = 0; i < types.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = types[i].$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _type == types[i].$1
                      ? AppColors.accent
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _type == types[i].$1
                        ? AppColors.accent
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  types[i].$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _type == types[i].$1
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
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
    width: 130,
    child: TextField(
      controller: _countCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) {
        if (_submitted) setState(() {});
      },
      style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textPrimary),
      decoration: _dec(hint: '1', error: _countError),
    ),
  );

  Widget _contentField() => TextField(
    controller: _contentCtrl,
    maxLines: null,
    minLines: 8,
    style: GoogleFonts.scheherazadeNew(
      fontSize: 17,
      height: 1.9,
      color: AppColors.textPrimary,
    ),
    decoration: _dec(
      hint: 'Dua, zikr və ya oxunuş mətnini bura yaz...',
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              p.$2,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _customDurationField() => SizedBox(
    width: 150,
    child: TextField(
      controller: _customDurCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) {
        if (_submitted) setState(() {});
      },
      style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textPrimary),
      decoration: _dec(hint: 'Neçə gün?', error: _customDurError),
    ),
  );

  Widget _intentionField() => TextField(
    controller: _intentionCtrl,
    maxLines: 3,
    minLines: 2,
    style: GoogleFonts.nunito(
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    decoration: _dec(
      hint: 'Niyə bunu etmək istəyirsən?',
    ).copyWith(contentPadding: const EdgeInsets.all(14)),
  );
}
