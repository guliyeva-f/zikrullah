import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ─── SABİTLƏR ────────────────────────────────────────────────────────────────
class FontSizeLimits {
  FontSizeLimits._();
  static const double defaultLatin = 18;
  static const double defaultArabic = 24;
  static const double minLatin = 14;
  static const double maxLatin = 30;
  static const double minArabic = 18;
  static const double maxArabic = 40;
  static const double step = 2;
}
// ─── STATE ───────────────────────────────────────────────────────────────────
class FontSizeState {
  final double latin;
  final double arabic;
  const FontSizeState({required this.latin, required this.arabic});
  FontSizeState copyWith({double? latin, double? arabic}) =>
      FontSizeState(latin: latin ?? this.latin, arabic: arabic ?? this.arabic);
}
// ─── NOTIFIER ────────────────────────────────────────────────────────────────
class FontSizeNotifier extends AsyncNotifier<FontSizeState> {
  static const _keyLatin = 'text_font_size_latin';
  static const _keyArabic = 'text_font_size_arabic';
  @override
  Future<FontSizeState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return FontSizeState(
      latin: prefs.getDouble(_keyLatin) ?? FontSizeLimits.defaultLatin,
      arabic: prefs.getDouble(_keyArabic) ?? FontSizeLimits.defaultArabic,
    );
  }
  FontSizeState get _current =>
      state.value ??
      const FontSizeState(
        latin: FontSizeLimits.defaultLatin,
        arabic: FontSizeLimits.defaultArabic,
      );
  Future<void> increaseLatin() => _setLatin(
    (_current.latin + FontSizeLimits.step).clamp(
      FontSizeLimits.minLatin,
      FontSizeLimits.maxLatin,
    ),
  );
  Future<void> decreaseLatin() => _setLatin(
    (_current.latin - FontSizeLimits.step).clamp(
      FontSizeLimits.minLatin,
      FontSizeLimits.maxLatin,
    ),
  );
  Future<void> increaseArabic() => _setArabic(
    (_current.arabic + FontSizeLimits.step).clamp(
      FontSizeLimits.minArabic,
      FontSizeLimits.maxArabic,
    ),
  );
  Future<void> decreaseArabic() => _setArabic(
    (_current.arabic - FontSizeLimits.step).clamp(
      FontSizeLimits.minArabic,
      FontSizeLimits.maxArabic,
    ),
  );
  Future<void> _setLatin(double value) async {
    state = AsyncData(_current.copyWith(latin: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLatin, value);
  }
  Future<void> _setArabic(double value) async {
    state = AsyncData(_current.copyWith(arabic: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyArabic, value);
  }
}
final fontSizeProvider = AsyncNotifierProvider<FontSizeNotifier, FontSizeState>(
  FontSizeNotifier.new,
);
