import '../localization/locale_controller.dart';

/// ڕێکخستنی ژمارە و بەروار بە شێوازی کوردی.
abstract final class KurdishFormat {
  static const List<String> _monthsSorani = [
    'کانوونی دووەم',
    'شوبات',
    'ئازار',
    'نیسان',
    'ئایار',
    'حوزەیران',
    'تەمووز',
    'ئاب',
    'ئەیلوول',
    'تشرینی یەکەم',
    'تشرینی دووەم',
    'کانوونی یەکەم',
  ];

  static const List<String> _monthsBadini = [
    'Çile',
    'Sibat',
    'Adar',
    'Nîsan',
    'Gulan',
    'Hezîran',
    'Tîrmeh',
    'Tebax',
    'Îlon',
    'Cotmeh',
    'Mijdar',
    'Kanûn',
  ];

  static const List<String> _weekdaysSorani = [
    'دووشەممە',
    'سێشەممە',
    'چوارشەممە',
    'پێنجشەممە',
    'هەینی',
    'شەممە',
    'یەکشەممە',
  ];

  static const List<String> _weekdaysBadini = [
    'Duşem',
    'Sêşem',
    'Çarşem',
    'Pêncşem',
    'În',
    'Şemî',
    'Yekşem',
  ];

  static bool get _latin => LocaleController.instance.isBadini;

  static List<String> get months => _latin ? _monthsBadini : _monthsSorani;

  static List<String> get weekdays =>
      _latin ? _weekdaysBadini : _weekdaysSorani;

  static String digits(Object value) => value.toString();

  static String padded(int value) => digits(value.toString().padLeft(2, '0'));

  /// ژمارە بە جیاکەرەوەی هەزاران (ئینگلیزی)
  static String number(int amount) {
    final raw = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(raw[i]);
    }
    return buf.toString();
  }

  /// پارەی عێراقی بە جیاکەرەوەی هەزاران.
  static String moneyIqd(int amount) {
    final raw = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(raw[i]);
    }
    final n = buf.toString();
    return _latin ? '$n IQD' : '$n د.ع';
  }

  static String date(DateTime dateTime) {
    final local = dateTime.toLocal();
    if (_latin) {
      return '${local.day}ê ${months[local.month - 1]} ${local.year}';
    }
    return '${digits(local.day)}ی ${months[local.month - 1]} ${digits(local.year)}';
  }

  static String shortDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    if (_latin) {
      return '${weekdays[local.weekday - 1]}, ${local.day}ê ${months[local.month - 1]}';
    }
    return '${weekdays[local.weekday - 1]}، ${digits(local.day)}ی ${months[local.month - 1]}';
  }

  static String time(DateTime dateTime) {
    final local = dateTime.toLocal();
    final isEvening = local.hour >= 12;
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    if (_latin) {
      final period = isEvening ? 'êvar' : 'sibê';
      return '$hour12:${local.minute.toString().padLeft(2, '0')}ê $period';
    }
    final period = isEvening ? 'ئێوارە' : 'بەیانی';
    return '${digits(hour12)}:${padded(local.minute)}ی $period';
  }

  /// ژمارەی مۆبایل — تەنها لە سۆرانی (RTL) LTR isolate بۆ پاش و پێش نەبوون.
  static String phone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    // بادینی LTR ـە؛ پێویستی بە isolate نییە.
    if (_latin) return trimmed;
    return '\u2066$trimmed\u2069';
  }
}
