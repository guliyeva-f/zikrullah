import 'package:flutter/material.dart';
final RegExp _rtlCharPattern = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
);
final RegExp _ltrCharPattern = RegExp(r'[A-Za-zƏəĞğİıÖöŞşÜüÇç]');
TextDirection detectTextDirection(String text) {
  final hasArabic = _rtlCharPattern.hasMatch(text);
  final hasLatin = _ltrCharPattern.hasMatch(text);
  if (hasArabic && !hasLatin) {
    return TextDirection.rtl;
  }
  return TextDirection.ltr;
}
bool hasArabicScript(String text) => _rtlCharPattern.hasMatch(text);
bool hasLatinScript(String text) => _ltrCharPattern.hasMatch(text);
