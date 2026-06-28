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
        setState(() => _version = '${info.version} (${info.buildNumber})');
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
          'Tətbiq haqqında',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
        children: [
          // ── App identity ───────────────────────────────────────────────
          _AppHeader(version: _version),
          const SizedBox(height: 24),

          // ── Əməl növləri ──────────────────────────────────────────────
          const _Label('Əməl növləri'),
          const SizedBox(height: 10),
          const _TypeRow(
            items: [
              _TypeItem(
                emoji: '✓',
                title: 'Gündəlik',
                sub: 'Hər gün bir toxunuşla işarələ',
              ),
              _TypeItem(
                emoji: '📿',
                title: 'Zikr',
                sub: 'Hədəf say təyin et, saydıqca qeyd et',
              ),
              _TypeItem(
                emoji: '📖',
                title: 'Qiraət',
                sub: 'Mətni saxla, hər gün oxu',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Əhd sistemi ───────────────────────────────────────────────
          const _Label('Əhd sistemi'),
          const SizedBox(height: 10),
          const _Block(child: _AhdContent()),
          const SizedBox(height: 24),

          // ── Ardıcıllıq ────────────────────────────────────────────────
          const _Label('Ardıcıllıq'),
          const SizedBox(height: 10),
          const _Block(child: _StreakContent()),
          const SizedBox(height: 24),

          // ── Yedəkləmə ─────────────────────────────────────────────────
          const _Label('Yedəkləmə'),
          const SizedBox(height: 10),
          const _Block(child: _BackupContent()),
          const SizedBox(height: 24),

          // ── Bildirişlər ───────────────────────────────────────────────
          const _Label('Bildirişlər'),
          const SizedBox(height: 10),
          const _Block(child: _NotifContent()),
          const SizedBox(height: 24),

          // ── Məxfilik ──────────────────────────────────────────────────
          const _Label('Məxfilik'),
          const SizedBox(height: 10),
          const _PrivacyList(),
          const SizedBox(height: 32),

          // ── Footer ────────────────────────────────────────────────────
          Center(
            child: Text(
              'Zikrullah · $_version',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── APP HEADER ──────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  final String version;
  const _AppHeader({required this.version});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('📿', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zikrullah',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Gündəlik əməlləri və götürdüyün əhdləri izləmək üçün şəxsi tətbiq.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (version.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'v$version',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
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
        fontSize: 11,
        fontWeight: FontWeight.w700,
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
            sub,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
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
              'Əməl yaradarkən müddət təyin edə bilərsən — 7, 21, 40 gün və ya özün seç.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.archive_rounded,
          text: 'Hədəfə çatdıqda tətbiq həmin əməli avtomatik arxivləyir.',
        ),
        SizedBox(height: 16),
        Divider(height: 1, color: AppColors.separator),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ModeCard(
                emoji: '🔗',
                title: 'Ardıcıl',
                body: 'Bir gün buraxsan sayaç sıfırlanır.',
                example: 'məs: 40 gün Yasin',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _ModeCard(
                emoji: '🗓',
                title: 'Fasiləli',
                body: 'Yalnız ümumi say hesablanır.',
                example: 'məs: 40 cümə sədəqəsi',
              ),
            ),
          ],
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
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            example,
            style: const TextStyle(
              fontSize: 11,
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
              'Hər əməlin öz ardıcıllıq sayğacı var. Bu gün etdinsə artır, buraxdınsa sıfırlanır.',
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
              'Streak sıfırlansa da keçmiş tarixçən silinmir — detallar ekranında bütün cəhdlərini görə bilərsən.',
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
          text:
              'Parametrlər › Yedəklə / Bərpa bölməsindən bütün əməlləri fayl kimi ixrac et.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.download_rounded,
          text:
              'Cihaz dəyişdirəndə həmin faylı idxal et. Üst-üstə düşən əməlləri sən seçirsən.',
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
          icon: Icons.wb_sunny_outlined,
          text: 'Səhər, günorta, axşam — hər biri üçün ayrıca vaxt seç.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.bedtime_outlined,
          text:
              'Gecə 23:00-da istəyə görə "günü bağlamadan əvvəl" xatırlatması göndərilir.',
        ),
        SizedBox(height: 12),
        _InfoRow(
          icon: Icons.wifi_off_rounded,
          text:
              'Bütün bildirişlər cihaz daxilindədir — internet olmadan işləyir.',
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
                          fontSize: 13,
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
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}
