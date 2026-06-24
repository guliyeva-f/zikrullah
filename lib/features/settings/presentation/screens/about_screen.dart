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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          const Text(
            'Zikrullah',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Versiya $_version',
            style: const TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          const Text(
            'Zikrullah — gündəlik zikr, dua və əməlləri izləmək üçün şəxsi yardımçı tətbiqdir.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Məxfilik siyasəti',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Zikrullah heç bir şəxsi məlumatınızı toplamır, sərvərə ötürmür və üçüncü '
            'tərəflərlə paylaşmır. Bütün əməllər, qeydlər və ayarlar yalnız sizin '
            'cihazınızda yerli olaraq saxlanılır. Bildirişlər tamamilə cihaz daxilində '
            'planlaşdırılır, internetə ehtiyac yoxdur. "Məlumatları ixrac et" funksiyası '
            'ilə yaratdığınız fayl yalnız siz seçdiyiniz yerə (paylaşma menyusu vasitəsilə) '
            'göndərilir.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
