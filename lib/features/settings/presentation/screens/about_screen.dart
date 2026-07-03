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
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = info.version);
      }
    });
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
          'Haqqında',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
        children: [
          // ── MƏNA: niyə bu app var ────────────────────────────────────
          const _HeroManifesto(),
          const SizedBox(height: 28),
          // ── MƏXFİLİK ─────────────────────────────────────────────────
          const _Label('Sənin məlumatın, sənin telefonunda'),
          const SizedBox(height: 10),
          const _PrivacyList(),
          const SizedBox(height: 28),
          // ── NECƏ İŞLƏYİR ─────────────────────────────────────────────
          const _Label('Əməllərini necə izləyirsən'),
          const SizedBox(height: 10),
          const _TypeRow(
            items: [
              _TypeItem(
                emoji: '✓',
                title: 'Sadə',
                sub: 'Sayılmayan əməllər üçün. Bir toxunuşla tamamla.',
              ),
              _TypeItem(
                emoji: '📿',
                title: 'Zikr',
                sub: 'Hədəf sayını seç. Sayğac vasitəsilə tamamla.',
              ),
              _TypeItem(
                emoji: '📖',
                title: 'Qiraət',
                sub: 'Mətni yaz və tətbiqin içindən rahatlıqla oxu.',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _Block(child: _AhdContent()),
          const SizedBox(height: 10),
          const _Block(child: _StreakContent()),
          const SizedBox(height: 10),
          const _Block(child: _BackupContent()),
          const SizedBox(height: 10),
          const _Block(child: _NotifContent()),
          const SizedBox(height: 32),
          // ── FOOTER ───────────────────────────────────────────────────
          Center(
            child: Text(
              'Zikrullah · v$_version',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HERO MANIFESTO ───────────────────────────────────────────────────────
class _HeroManifesto extends StatelessWidget {
  const _HeroManifesto();

  Widget _dotsDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.05),
                AppColors.accent.withValues(alpha: 0.4),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 52,
          height: 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.4),
                AppColors.accent.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accentLight.withValues(alpha: 0.10),
            AppColors.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ── Loqo ───────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/icon/icon.png',
              width: 80,
              height: 80,
              errorBuilder: (_, _, _) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text('📿', style: TextStyle(fontSize: 30)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _dotsDivider(),
          const SizedBox(height: 22),
          // ── Ayə (ana ekrandakı ilə eyni) ──────────────────────────────
          RichText(
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 26,
                height: 2.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: 'أَلاَ بِ'),
                TextSpan(
                  text: 'ذِكْرِ اللّهِ',
                  style: TextStyle(color: Color(0xFF6B8C5A)),
                ),
                TextSpan(text: ' تَطْمَئِنُّ الْقُلُوبُ'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bilin ki, qəlblər yalnız Allahı zikr etməklə\nrahatlıq tapar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌿', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              const Text(
                'Ər-Rəd surəsi, 28',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(3.14159),
                child: const Text('🌿', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _dotsDivider(),
          const SizedBox(height: 22),
          // ── Manifest ───────────────────────────────────────────────
          const Text(
            'Zikrullah — zikrlərini, qiraətlərini və digər ibadətlərini bir yerdə izləmək üçün hazırlanmış şəxsi ibadət köməkçindir.\n\n'
            'Allah üçün verdiyin sözləri və etdiyin niyyətləri unutmağın qarşısını alan sadə bir vasitədir. '
            'Məqsəd çox əməl etmək deyil. Məqsəd az da olsa davamlı olmaqdır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LABEL ───────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textHint,
        letterSpacing: 1.0,
      ),
    );
  }
}

// ─── GENERIC BLOCK ───────────────────────────────────────────────────────────
class _Block extends StatelessWidget {
  final Widget child;
  const _Block({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ─── ƏMƏL NÖVLƏRİ: 3 SÜTUN ──────────────────────────────────────────────────
class _TypeRow extends StatelessWidget {
  final List<_TypeItem> items;
  const _TypeRow({required this.items});
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items
            .expand(
              (item) => [
                Expanded(child: item),
                if (item != items.last) const SizedBox(width: 8),
              ],
            )
            .toList(),
      ),
    );
  }
}

class _TypeItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  const _TypeItem({
    required this.emoji,
    required this.title,
    required this.sub,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ƏHD SİSTEMİ ─────────────────────────────────────────────────────────────
class _AhdContent extends StatelessWidget {
  const _AhdContent();
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.event_available_rounded,
          text:
              'İstəsən əməlin üçün müəyyən müddət təyin edə bilərsən. Məsələn 7, 21, 40 gün və ya istədiyin qədər.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.archive_rounded,
          text:
              'Əhd tamamlandıqda əməl avtomatik arxivə köçürülür. Beləliklə keçmiş əhdlərin həmişə qorunur.',
        ),
        SizedBox(height: 16),
        Divider(height: 1, color: AppColors.separator),
        SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ModeCard(
                  emoji: '🔗',
                  title: 'Ardıcıl',
                  body:
                      'Hər gün edilməli olan əməllər üçündür. Bir gün buraxıldıqda ardıcıllıq yenidən başlayır.',
                  example: 'məs: 40 gün ardıcıl Aşura Ziyarətnaməsi oxumaq',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ModeCard(
                  emoji: '🗓',
                  title: 'Fasiləli',
                  body:
                      'Hər gün edilməyən əməllər üçündür. Ara vermək sayğacı sıfırlamır, yalnız ümumi say artır.',
                  example: 'məs: hər cümə edilən ibadətlər',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  final String example;
  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.body,
    required this.example,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.3,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 6),
          Text(
            example,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STREAK ──────────────────────────────────────────────────────────────────
class _StreakContent extends StatelessWidget {
  const _StreakContent();
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.local_fire_department_rounded,
          iconColor: Color(0xFFE07B39),
          text:
              'Davamlılıq Zikrullahın əsas hissəsidir. Hər əməlin öz ardıcıllığı ayrıca izlənilir.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.grid_view_rounded,
          text:
              'Ana ekranda il boyu aktivliyini rəngli xəritə şəklində görürsən. Hər kvadrat bir gündür.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.history_rounded,
          text:
              'Sayğac sıfırlansa da keçmiş tarixçən silinmir — detallar ekranında bütün cəhdlərini görə bilərsən.',
        ),
      ],
    );
  }
}

// ─── BACKUP ──────────────────────────────────────────────────────────────────
class _BackupContent extends StatelessWidget {
  const _BackupContent();
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.upload_rounded,
          text: 'Bütün əməllərini bir fayl kimi ixrac edə bilərsən.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.download_rounded,
          text:
              'Yeni telefonda həmin faylı seçərək hər şeyi bir neçə saniyəyə geri qaytara bilərsən.',
        ),
      ],
    );
  }
}

// ─── BİLDİRİŞLƏR ─────────────────────────────────────────────────────────────
class _NotifContent extends StatelessWidget {
  const _NotifContent();
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.auto_awesome_rounded,
          text:
              'Bildirişlər hamıya eyni deyil. Onlar həmin andakı vəziyyətinə uyğun seçilir. Bəzən son qalan əməlini xatırladır.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.favorite_border_rounded,
          text:
              'Bəzən yazdığın niyyəti yenidən sənə göstərir. Bəzən isə sadəcə bir ayə və ya hədislə qəlbini Allahı xatırlamağa çağırır.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.wb_sunny_outlined,
          text:
              'Səhər, günorta, axşam, gecə — hər vaxtın öz tonu var, hər biri üçün ayrıca saat seçə bilərsən.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.wifi_off_rounded,
          text:
              'Hamısı cihaz daxilində qərarlaşdırılır — internetə ehtiyac yoxdur.',
        ),
      ],
    );
  }
}

// ─── MƏXFİLİK ────────────────────────────────────────────────────────────────
class _PrivacyList extends StatelessWidget {
  const _PrivacyList();
  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.phonelink_lock_rounded,
        'Bütün məlumatlar yalnız cihazında saxlanılır',
      ),
      (Icons.cloud_off_rounded, 'Heç bir serverə məlumat göndərilmir'),
      (Icons.person_off_rounded, 'Hesab lazım deyil, şəxsi məlumat toplanmır'),
      (Icons.block_rounded, 'Reklam yoxdur, izləmə yoxdur'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.indexed.map((entry) {
          final (i, item) = entry;
          final (icon, text) = item;
          return Column(
            children: [
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.separator,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 17, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── INFO ROW ────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;
  const _InfoRow({required this.icon, this.iconColor, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 16,
            color: iconColor ?? AppColors.accentLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
