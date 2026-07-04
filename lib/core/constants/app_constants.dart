class AppConstants {
  AppConstants._();
  static const int maxCounterValue = 99999;
  static String formatThousands(int value) {
    final isNegative = value < 0;
    final str = value.abs().toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return '${isNegative ? '-' : ''}$buffer';
  }
  static const months = [
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
    'İyun',
    'İyul',
    'Avqust',
    'Sentyabr',
    'Oktyabr',
    'Noyabr',
    'Dekabr',
  ];
  static const monthsShort = [
    'Yan',
    'Fev',
    'Mar',
    'Apr',
    'May',
    'İyn',
    'İyl',
    'Avq',
    'Sen',
    'Okt',
    'Noy',
    'Dek',
  ];
  static const weekdays = [
    '',
    'Bazar ertəsi',
    'Çərşənbə axşamı',
    'Çərşənbə',
    'Cümə axşamı',
    'Cümə',
    'Şənbə',
    'Bazar',
  ];
  static const weekdaysShort = ['BE', 'ÇA', 'Ç', 'CA', 'C', 'Ş', 'B'];
}
