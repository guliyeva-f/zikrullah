import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_colors.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version} (${info.buildNumber})');
    }
  }

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
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tətbiq haqqında',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          // ── Başlıq bloku ──────────────────────────────────────────────
          _HeroCard(version: _version),
          const SizedBox(height: 20),

          // ── Niyə bu tətbiq? ───────────────────────────────────────────
          const _SectionCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Niyə Zikrullah?',
            body:
                'Bəzən niyyət var, amma ardıcıllıq yoxdur. Bəzən 40 günlük bir əhd qurulur, '
                'amma orta yolda yaddan çıxır. Zikrullah elə bunun üçün yaradıldı — '
                'gündəlik zikr, dua və götürdüyün əhdlərə sadiq qalmağa kömək edən, '
                'sadə və sakit bir yoldaş.',
          ),
          const SizedBox(height: 12),

          // ── Əməl növləri ──────────────────────────────────────────────
          const _SectionLabel(label: 'Əməl növləri'),
          const SizedBox(height: 8),
          const _FeatureCard(
            emoji: '✓',
            title: 'Gündəlik əməl',
            body:
                'Hər gün bir işarə ilə tamamladığını qeyd et. Namaz, dua, '
                'sədəqə — bir toxunuşla işarələ, ardıcıllığını izlə.',
          ),
          const SizedBox(height: 8),
          const _FeatureCard(
            emoji: '📿',
            title: 'Zikr sayğacı',
            body:
                'SubhanAllah, Əlhəmdülillah, Allahuəkbər... Hədəf say '
                'təyin et, hər oturumda saydıqlarını qeyd et. Tətbiq günün '
                'tamamlanıb-tamamlanmadığını hədəfə çatmağa görə müəyyən edir.',
          ),
          const SizedBox(height: 8),
          const _FeatureCard(
            emoji: '📖',
            title: 'Qiraət / Qeyd',
            body:
                'Oxuduqlarını, düşüncələrini, şükür etdiklərini gündəlik '
                'qeyd et. Quran, hədis, ya da sadəcə gün sonu bir söz.',
          ),
          const SizedBox(height: 20),

          // ── Müddətli əhdlər ───────────────────────────────────────────
          const _SectionLabel(label: 'Müddətli əhdlər'),
          const SizedBox(height: 8),
          const _SectionCard(
            icon: Icons.flag_rounded,
            title: 'Əhd sistemi',
            body:
                'Əməl yaradarkən müddət təyin edə bilərsən — məsələn "40 gün Yasin" '
                'və ya "100 sədəqə". Tətbiq hədəfə çatana qədər əməli aktiv saxlayır, '
                'hədəfə çatdıqda isə onu arxivləyir.',
          ),
          const SizedBox(height: 8),
          const _TwoColumnCard(
            left: _InfoTile(
              emoji: '🔗',
              title: 'Ardıcıl rejim',
              body:
                  'Gün buraxıldımı, sayaç sıfırlanır. '
                  '"40 gün Yasin" kimi əhdlər üçün — fasilə olmaz.',
            ),
            right: _InfoTile(
              emoji: '🗓️',
              title: 'Fasiləli rejim',
              body:
                  'Aradakı fasilə sayılmır. '
                  '"40 cümə sədəqəsi" kimi əhdlər üçün — yalnız say hesablanır.',
            ),
          ),
          const SizedBox(height: 20),

          // ── Streak və statistika ──────────────────────────────────────
          const _SectionLabel(label: 'Ardıcıllıq və statistika'),
          const SizedBox(height: 8),
          const _SectionCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: Color(0xFFE07B39),
            title: 'Streak — ardıcıllıq sayğacı',
            body:
                'Hər əməlin öz ardıcıllıq sayğacı var. Bu gün etdinsə — sayğac artır. '
                'Bir gün buraxdınsa — sayğac sıfırlanır. Amma bu sənin tarixçəni '
                'silmir: detail ekranında keçmiş bütün cəhdlərini görə bilərsən.',
          ),
          const SizedBox(height: 8),
          const _SectionCard(
            icon: Icons.grid_view_rounded,
            title: 'İstilik xəritəsi',
            body:
                'Əsas ekranda və əməlin detail səhifəsində aktivliyini rəngli '
                'xəritə şəklində görürsən. Hər kvadrat bir gündür — nə qədər '
                'çox etdinsə, o qədər tünd.',
          ),
          const SizedBox(height: 20),

          // ── Yedəkləmə ─────────────────────────────────────────────────
          const _SectionLabel(label: 'Yedəkləmə'),
          const SizedBox(height: 8),
          const _SectionCard(
            icon: Icons.cloud_sync_rounded,
            title: 'İxrac və idxal',
            body:
                'Parametrlər → Yedəklə / Bərpa bölməsindən bütün əməllərin '
                'və tarixçəni JSON faylı kimi ixrac edə bilərsən. Cihaz dəyişdirəndə '
                'və ya yedəkdən bərpa edəndə isə həmin faylı idxal et. '
                'Eyni adlı əməllər üst-üstə düşəndə tətbiq sənə seçim təqdim edir — '
                'hansının saxlanacağına sən qərar verirsən.',
          ),
          const SizedBox(height: 20),

          // ── Bildirişlər ───────────────────────────────────────────────
          const _SectionLabel(label: 'Bildirişlər'),
          const SizedBox(height: 8),
          const _SectionCard(
            icon: Icons.notifications_none_rounded,
            title: 'Zikr vaxtları xatırlatması',
            body:
                'Parametrlərdən səhər, günorta və axşam üçün ayrıca vaxt '
                'təyin edə bilərsən. Gecə yarısı 23:00-da isə isteğe bağlı '
                '"günü bağlamadan əvvəl" xatırlatması göndərilir. '
                'Bütün bildirişlər cihaz daxilindədir — internet lazım deyil.',
          ),
          const SizedBox(height: 20),

          // ── Məxfilik ──────────────────────────────────────────────────
          const _SectionLabel(label: 'Məxfilik'),
          const SizedBox(height: 8),
          const _PrivacyCard(),
          const SizedBox(height: 28),

          // ── Footer ────────────────────────────────────────────────────
          Center(
            child: Text(
              'Zikrullah · $_version',
              style: const TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HERO CARD ──────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String version;
  const _HeroCard({required this.version});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('📿', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zikrullah',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                  if (version.isNotEmpty)
                    Text(
                      'Versiya $version',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Gündəlik zikr, dua və götürdüyün əhdləri ardıcıl izləmək üçün '
            'sadə, reklamsız, tamamilə şəxsi bir yoldaş.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION LABEL ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 0),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 0.9,
      ),
    ),
  );
}

// ─── SECTION CARD ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String body;

  const _SectionCard({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: iconColor ?? AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FEATURE CARD ────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TWO COLUMN CARD ─────────────────────────────────────────────────────────

class _TwoColumnCard extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TwoColumnCard({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 8),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;

  const _InfoTile({
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PRIVACY CARD ────────────────────────────────────────────────────────────

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const _PrivacyRow(
            icon: Icons.phonelink_lock_rounded,
            text: 'Bütün məlumatlar yalnız cihazında saxlanılır',
          ),
          _Divider(),
          const _PrivacyRow(
            icon: Icons.cloud_off_rounded,
            text: 'Heç bir serverə məlumat göndərilmir',
          ),
          _Divider(),
          const _PrivacyRow(
            icon: Icons.person_off_rounded,
            text: 'Şəxsi məlumat toplanmır, hesab lazım deyil',
          ),
          _Divider(),
          const _PrivacyRow(
            icon: Icons.wifi_off_rounded,
            text: 'Bildirişlər internet olmadan işləyir',
          ),
          _Divider(),
          const _PrivacyRow(
            icon: Icons.block_rounded,
            text: 'Reklam yoxdur, izləmə yoxdur',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLast;

  const _PrivacyRow({
    required this.icon,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: AppColors.separator,
  );
}
