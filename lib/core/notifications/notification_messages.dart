import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_context.dart';
class NotificationMessages {
  NotificationMessages._();
  static String titleFor(NotifSlot slot) {
    switch (slot) {
      case NotifSlot.morning:
        return '☀️ Sabahın xeyir';
      case NotifSlot.noon:
        return '🤲 Bir anlıq dayan';
      case NotifSlot.evening:
        return '🌇 Gün sona yaxınlaşır';
      case NotifSlot.night:
        return '🌙 Gün bağlanır';
    }
  }
  static const String returnTitle = '🌿 Yenidən xoş gəldin';
  static const List<String> allCompleted = [
    'Bugünkü əhdinə vəfalı oldun. Allah qəbul etsin 🤲',
    'Bu gün üçün üzərinə götürdüklərini tamamladın. Nə gözəl gün ✨',
    'Bugünkü əməllərin tamamlandı. Qəlbin rahat olsun.',
    'Bu gün Allah üçün verdiyin sözü tutdun. Sabah da davam et.',
    'Əhdinə sadiq qaldın. Davamlılıq ən gözəl vəfadır.',
    'Bugünkü zəhmətin Axirətdə nur olsun.',
  ];
  static List<String> singleAmal(String title) => [
    '"$title" hələ səni gözləyir.',
    '"$title" — bu gün üçün son addımın.',
    'Gəl, "$title" ilə bugünkü əhdini tamamla.',
    'Bəlkə də bugünkü ən qiymətli əməl elə "$title" olacaq.',
    '"$title" səni gözləyir. Hazır olanda davam et.',
    'Bu günü "$title" ilə gözəlləşdir.',
    '"$title" tamamlananda bugünkü əhd də tamamlanacaq.',
    'Kiçik görünür, amma Allah yanında böyük ola bilər — "$title".',
    'Bir addım qalıb. "$title" ilə gününü tamamla.',
  ];
  static List<String> intention(String title, String intentionText) => [
    'Bir vaxt "$title" üçün belə yazmışdın:\n"$intentionText"\nBu niyyətini bu gün də yaşat.',
    '"$intentionText" — bunu "$title" üçün niyyət etmişdin. O hələ də səni gözləyir.',
    'Allah üçün yazdığın niyyəti unutma:\n"$intentionText"',
    'Niyyətini xatırla: "$intentionText".',
    'Hər şey bir niyyətlə başlamışdı.\n"$intentionText"',
    'Allah qəlbində olan niyyəti bilir.',
    'Bəlkə də bu bildiriş sənə niyyətini yenidən xatırlatmaq üçündür.',
    'Yazdığın niyyət sadəcə söz deyildi. Bu gün də onu yaşat.',
  ];
  static List<String> streak(String title, int milestone) => [
    '🔥 "$title" üçün $milestone günlük ardıcıllığa bir addım qalıb.',
    'Bu gün də davam etsən, "$title" $milestone gün olacaq 🔥',
    'Davamlılığın gözəldir. "$title" bu gün $milestone-ə çatacaq.',
    'Allah qatında davamlı əməl seviləndir. "$title" buna çox yaxındır.',
    '$milestone günə çatmaq üçün bu gün kifayətdir.',
    'Ardıcıllığını qoru. "$title" səni gözləyir.',
    'Səbir və davamlılıq səni $milestone günə gətirdi.',
    'Bir addım da at. "$title" üçün gözəl bir mərhələ yaxındadır.',
  ];
  static List<String> duration(String title, int remainingDays) {
    if (remainingDays == 1) {
      return [
        '"$title" — sabah bu əhd tamamlanacaq. Allahın izni ilə.',
        'Son gün. "$title" sabah başa çatır.',
        'Bu gün son addımdır. "$title" sabah tamamlanacaq.',
        'Bir gün qalıb. Allah bu əhdi qəbul etsin.',
        'Bu yolun son addımı qalıb. Davam et.',
      ];
    }
    return [
      '"$title" üçün $remainingDays gün qalıb.',
      '$remainingDays gün sonra "$title" tamamlanacaq. Davam et.',
      'Bu əhdin tamamlanmasına cəmi $remainingDays gün qalıb.',
      'Az qalıb. Bu gün də davam etsən, sona daha da yaxınlaşacaqsan.',
    ];
  }
  static List<String> multipleAmals(int count, List<String> titles) {
    if (titles.isNotEmpty) {
      final first = titles.first;
      final restCount = count - 1;
      if (restCount <= 0) {
        return singleAmal(first);
      }
      return [
        '"$first" səni gözləyir, daha $restCount əməl də qalıb.',
        '"$first" ilə başla — ardınca $restCount əməl də var.',
        '"$first" və daha $restCount əməl bu gün üçün gözləyir.',
        '"$first" ilk addımın olsun. Qalanları da Allahın izni ilə tamamlayarsan.',
        'Əhdinə "$first" ilə başla. Daha $restCount əməl qalıb.',
        '"$first" bu günün başlanğıcı ola bilər.',
        'Bir əməl digərinə yol açır. "$first" ilə başla.',
        'Ən çətin hissə başlamaqdır. "$first" səni gözləyir.',
        'Qalan $restCount əmələ aparan ilk addım "$first" ola bilər.',
      ];
    }
    return [
      'Bu gün $count əməl səni gözləyir 🤲',
      '$count əməl qalıb. Vaxtın hələ var.',
      'Günün hələ bitməyib — $count əməl səni gözləyir.',
      'Kiçik addımlar böyük yollar açır. $count əməl qalıb.',
      'Əhdini unutma. Bu gün $count əməl qalıb.',
      '$count kiçik addım səni gözləyir.',
      'Bəlkə də bu günün ən gözəl anı həmin $count əməlin içindədir.',
      '$count əməl... Bəlkə elə indi başlamağın vaxtıdır.',
    ];
  }
  static List<String> spiritualFor(NotifSlot slot) {
    switch (slot) {
      case NotifSlot.morning:
        return [
          'Bu gün Allaha yaxınlaşmaq üçün yeni bir fürsətdir.',
          'Kiçik bir zikr, böyük bir bərəkətin başlanğıcı ola bilər.',
          'Niyyətini yenilə, gününü gözəlləşdir.',
          'Bəlkə də bu gün həyatını dəyişəcək kiçik bir zərrədir.',
          'Allah üçün atılan heç bir kiçik addım itməz.',
          'Hər səhər yeni başlanğıcdır. Bu günü də boş buraxma.',
          'Qəlbin zikrlə oyansın, günün bərəkətlə davam etsin.',
          'Bəzən bir dəqiqəlik zikr bütün günün ruhunu dəyişir.',
        ];
      case NotifSlot.noon:
        return [
          'Qəlb bəzən sadəcə bir zikr qədər rahatlığa ehtiyac duyur.',
          'Bir anlıq dayan, qəlbini Allaha tərəf çevir.',
          'Hər nəfəs bir nemətdir. Onu zikrlə bəzə.',
          'Dünyanın səsindən bir anlıq uzaqlaş.',
          'Qəlb Allahı xatırlayanda sakitləşər.',
          'Əhdini xatırla və yoluna davam et.',
          'Bu günün ən gözəl anı bəlkə də Allahı xatırladığın an olacaq.',
          'Bir neçə dəqiqə Allah üçün ayır.',
          'Qəlbin yorulanda zikr ona istirahət olar.',
        ];
      case NotifSlot.evening:
        return [
          'Gün batmadan bugünkü əməllərinə nəzər sal.',
          'Əhdlər böyük addımlarla deyil, kiçik davamlı əməllərlə qorunur.',
          'Bu gün özünə Allahı xatırlamaq üçün bir neçə dəqiqə hədiyyə et.',
          'Hələ gec deyil. Bir addım da ata bilərsən.',
          'Bəlkə də Allah səni bu bildirişlə Özünə çağırır.',
          'Bu günün sonuna qədər qəlbini zikrlə bəzə.',
          'Hər günün öz payı var. Sənin payın hələ bitməyib.',
          'Əhdini gün bitmədən tamamla.',
          'Kiçik görünən əməl belə Allah yanında böyük ola bilər.',
          'Bir zikr, bir dua, bir səmimi niyyət...',
          'Bu günün son saatlarını boş buraxma.',
        ];
      case NotifSlot.night:
        return [
          'Gün sona çatır. Bu gün Allah üçün nə etdin?',
          'Yatmadan əvvəl qəlbini bir anlığa Allaha tərəf çevir.',
          'Gün bitməzdən əvvəl bir kiçik əməl belə dəyərlidir.',
          'Bu gecə qəlbini zikrlə rahatlaşdır.',
          'Sabaha hansı qəlblə oyanmaq istəyirsən?',
          'Allahı xatırlayaraq bitən gün daha gözəldir.',
          'Bəlkə də bu günün son zərrəsi axirətdə ən ağır gələcək.',
          'Əhdini sabaha saxlama.',
          'Yatmazdan əvvəl bir dəfə də Onu xatırla.',
          'Qəlbin gecə zikrlə rahatlıq tapar.',
          'Bu gün bitir, amma əməllər qalır.',
        ];
    }
  }
  static const List<String> verseHadith = [
    '"Bilin ki, qəlblər yalnız Allahı zikr etməklə rahatlıq tapar." (Ər-Rəd, 28)',
    '"Məni zikr edin, Mən də sizi zikr edim." (Bəqərə, 152)',
    '"Allahı çox zikr edən kişi və qadınlar üçün Allah böyük mükafat hazırlamışdır." (Əhzab, 35)',
    '"Allaha verdiyiniz əhdi yerinə yetirin." (Nəhl, 91)',
    '"Əhdə vəfa edin. Həqiqətən, əhd barəsində sorğu-sual olunacaqsınız." (İsra, 34)',
    '"Kim zərrə qədər xeyir etsə, onun qarşılığını görəcək." (Zəlzələ, 7)',
    '"Kim zərrə qədər şər etsə, onun qarşılığını görəcək." (Zəlzələ, 8)',
    '"Ey iman gətirənlər! Allahı çox zikr edin." (Əhzab, 41)',
    'Peyğəmbər (s): "Allah yanında ən sevimli əməl az da olsa davamlı olanıdır."',
    'Peyğəmbər (s): "Əməllər niyyətlərə görədir."',
    'İmam Əli (ə.s): "Zikr qəlbin nurudur."',
    'İmam Əli (ə.s): "Bu gün əməl günüdür, sabah isə hesab günü."',
    'İmam Əli (ə.s): "Fürsətlər bulud kimi ötüb keçir."',
    'İmam Sadiq (ə.s): "Allahı zikr etmək qəlbə şəfadır."',
    'İmam Sadiq (ə.s): "Kiçik saydığın xeyir əməli tərk etmə."',
    'Bəzən bir səmimi niyyət uzun bir ibadətdən daha dəyərlidir.',
    'Kiçik bir zərrə, böyük bir başlanğıc ola bilər.',
    'Qəlb Allahı unutduqda daralır, Onu xatırladıqda genişlənir.',
    'Bu günün kiçik əməlləri sabahın böyük qazancı ola bilər.',
    'Əhdini unutma. Allah verdiyin sözü bilir.',
    'Allah üçün atılan heç bir addım itmir.',
    'Bəzən Allaha ən yaxın an, Onu səssizcə xatırladığın andır.',
    'Əməlin kiçik görünə bilər, amma Allah yanında ölçü başqadır.',
    'Qayıtmaq üçün ən gözəl vaxt elə bu andır.',
    'Allah yolunda atılan heç bir addım cavabsız qalmaz.',
  ];
  static List<String> returnReminder(int inactiveDays) {
    if (inactiveDays >= 8) {
      return [
        'Hər yeni gün yenidən başlamaq üçün bir fürsətdir.',
        'Allahın rəhməti heç vaxt gec deyil. İstədiyin zaman qayıda bilərsən.',
        'Əhdin səni gözləyir. Hazır olanda davam edərsən 🌿',
        'Kiçik bir addım hər şeyi yenidən başlada bilər.',
        'Bəlkə də bu bildiriş yenidən başlamağın səbəbi olar.',
        'Allah yolunda gecikmək olar, vaz keçmək yox.',
        'Qayıtmaq üçün ən gözəl vaxt elə bu andır.',
        'Qaldığın yerdən davam etmək üçün bu gün kifayətdir.',
        'Bir zərrəlik xeyir belə Allah yanında itib getmir.',
        'Qəlbin nə vaxt hazır olsa, biz buradayıq 🤲',
      ];
    }
    return [
      'Qayıtmaq üçün bu gün gözəl gündür 🌿',
      'Əhdin hələ də səni gözləyir.',
      'Bir neçə dəqiqə ayırmaq kifayətdir.',
      'Bu gün kiçik bir addımla yenidən başla.',
      'Bir zikr, bir dua, bir səmimi niyyət...',
      'Allah üçün ayıracağın bir neçə dəqiqə bəs edər.',
      'Bəzən yenidən başlamaq ən gözəl addımdır.',
      'Bu gün də qəlbini Allaha tərəf çevir.',
      'Qaldığın yerdən davam et. Hər şey sıfırdan başlamır.',
      'Bu günün zərrəsi sabahın böyük qazancı ola bilər.',
      'Hazır hiss etdiyin anda yol yenə açıqdır.',
      'Səmimi bir niyyətlə yenidən başlamaq kifayətdir.',
    ];
  }
  static Future<String> compose(NotifPick pick, NotifSlot slot) async {
    final pool = _poolFor(pick, slot);
    final key = 'notif_last_msg_${slot.name}_${pick.category.name}';
    return _pickAvoidingRepeat(pool, key);
  }
  static Future<String> composeReturn(int inactiveDays) async {
    final pool = returnReminder(inactiveDays);
    return _pickAvoidingRepeat(pool, 'notif_last_msg_return');
  }
  static Future<String> composeDecay(NotifSlot slot, int dayOffset) async {
    final pool = returnReminder(dayOffset);
    final key = 'notif_last_msg_decay_${slot.name}_$dayOffset';
    return _pickAvoidingRepeat(pool, key);
  }
  static List<String> _poolFor(NotifPick pick, NotifSlot slot) {
    switch (pick.category) {
      case NotifCategory.allCompleted:
        return allCompleted;
      case NotifCategory.singleAmal:
        return singleAmal(pick.amal!.title);
      case NotifCategory.intention:
        return intention(pick.amal!.title, pick.amal!.intention!.trim());
      case NotifCategory.streak:
        return streak(pick.amal!.title, pick.streakValue!);
      case NotifCategory.duration:
        return duration(pick.amal!.title, pick.remainingDays!);
      case NotifCategory.multipleAmals:
        return multipleAmals(pick.remainingCount, pick.remainingTitles);
      case NotifCategory.spiritual:
        return spiritualFor(slot);
      case NotifCategory.verseHadith:
        return verseHadith;
      case NotifCategory.returnReminder:
        return returnReminder(0);
    }
  }
  static Future<String> _pickAvoidingRepeat(
    List<String> pool,
    String key,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(key);
    final candidates = pool.length > 1
        ? pool.where((m) => m != last).toList()
        : pool;
    final chosen = candidates[Random().nextInt(candidates.length)];
    await prefs.setString(key, chosen);
    return chosen;
  }
}
