import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationMessages {
  NotificationMessages._();

  // ─── ÜMUMİ MOTİVASİYA ──────────────────────────────────────────────────────
  static const List<String> general = [
    'Zikrlərin sənin intizarındadır 🤲',
    'Bu günkü əməllərini unutma',
    'Qəlbini bir anlıq Allaha tərəf çevir',
    'Kiçik bir zikr, böyük bir savab',
    'Günün hələ bitməyib — bir addım at',
    'Bir zikr, bir nəfəs, bir an Onunla',
    'Bu gün də əhdinə sadiq qal',
    'Zikr qəlbə rahatlıqdır — unutma',
    'Sənin yerinə heç kim zikr edə bilməz',
    'Bir az vaxt ayır, qəlbin rahatlasın',
    'Gününə bərəkət gətir — davam et',
    'Bu an, Onu xatırlamaq üçün gözəl bir andır',
    'Əhdini xatırla, addımını at',
  ];

  // ─── AYƏ / HƏDİS / KƏLAM ────────────────────────────────────────────────────
  static const List<String> wisdom = [
    'اَلَا بِذِكْرِ اللّٰهِ تَطْمَئِنُّ الْقُلُوبُ — Ər-Rəd, 28',
    '"Məni zikr edin, Mən də sizi zikr edim" — Bəqərə, 152',
    '"Allahı çox zikr edən kişi və qadınlara Allah böyük mükafat hazırlamışdır" — Əhzab, 35',
    'Peyğəmbərimiz (s.a.s): "Dilin daim zikrlə tər olsun"',
    '"Ən xeyirli zikr gizli edilənidir" — rəvayət',
    '"Qəlblərin həyatı zikrdədir" — rəvayət',
  ];

  // ─── GECƏ ÜÇÜN TƏCİLİ TON ────────────────────────────────────────────────────
  static const List<String> nightUrgent = [
    'Gecə olmadan tamamla 🌙',
    'Son fürsət — əməllərin hələ gözləyir',
    'Gün bağlanmadan bir addım at',
    'Yatmadan əvvəl qəlbini rahatlat',
  ];

  // ─── SAY ƏSASLI ŞABLONLAR ────────────────────────────────────────────────────
  static List<String> countTemplates(int n) => [
    '$n əməlin hələ sənin intizarındadır',
    'Bu gün üçün $n əməl qalıb — vaxtın var',
    '$n əməl gözləyir, gəl tamamla',
    'Hələ $n addım qalıb əhdinə',
  ];

  // ─── AD ƏSASLI ŞABLONLAR (yalnız 1 əməl qalanda) ────────────────────────────
  static List<String> titleTemplates(String title) => [
    '"$title" sənin intizarındadır',
    '"$title" əməlinə davam et',
    '"$title"nı unutma',
    'Gəl, "$title" ilə günü gözəlləşdir',
  ];

  // ─── SEÇİM MƏNTİQİ ───────────────────────────────────────────────────────────
  static Future<String> compose({
    required String slotKey,
    required List<String> incompleteTitles,
  }) async {
    final count = incompleteTitles.length;
    final pool = <String>[...general, ...wisdom];

    if (count == 1) {
      pool.addAll(titleTemplates(incompleteTitles.first));
    } else if (count > 1) {
      pool.addAll(countTemplates(count));
    }

    if (slotKey == 'night') pool.addAll(nightUrgent);

    return _pickAvoidingRepeat(pool, slotKey);
  }

  static Future<String> _pickAvoidingRepeat(
    List<String> pool,
    String slotKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notif_last_msg_$slotKey';
    final last = prefs.getString(key);

    final candidates = pool.length > 1
        ? pool.where((m) => m != last).toList()
        : pool;

    final chosen = candidates[Random().nextInt(candidates.length)];
    await prefs.setString(key, chosen);
    return chosen;
  }
}
