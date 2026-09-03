import '../localization/app_strings.dart';
import '../localization/locale_controller.dart';

abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _phone = RegExp(r'^[\d\u0660-\u0669\s+-]{10,17}$');

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? AppStrings.requiredField : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    return _email.hasMatch(value.trim()) ? null : AppStrings.invalidEmail;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;
    return value.length >= 8 ? null : AppStrings.shortPassword;
  }

  /// بۆ لۆگینی تێست — `karox` / `admin` قبوڵ دەکات، یان ئیمەیڵی دروست.
  static String? loginEmail(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    final v = value.trim().toLowerCase();
    if (v == 'karox' || v == 'admin') return null;
    return email(value);
  }

  /// بۆ لۆگینی تێست — `karox` / `admin` قبوڵ دەکات، یان وشەی نهێنیی ٨ پیتی+.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;
    if (value == 'karox' || value == 'admin') return null;
    return password(value);
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    return _phone.hasMatch(value.trim()) ? null : AppStrings.invalidPhone;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    return value.trim().split(RegExp(r'\s+')).length >= 3
        ? null
        : AppStrings.shortName;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    final val = value.trim();
    
    final isSorani = LocaleController.instance.isSorani;

    if (val.length < 3) {
      return isSorani
          ? 'ناوی بەکارهێنەر نابێت لە ٣ پیت کەمتر بێت'
          : 'Navê bikarhêner nikare ji 3 tîpan kêmtir be';
    }
    if (val.length > 20) {
      return isSorani
          ? 'نابێت ناوی بەکار‌هێنەر لە ٢٠ پیت زیاتر بێت'
          : 'Navê bikarhêner nikare ji 20 tîpan zêdetir be';
    }

    // Check spaces count
    final spaceCount = ' '.allMatches(val).length;
    if (spaceCount > 1) {
      return isSorani
          ? 'نابێت لە یەک بۆشایی (سپەیس) زیاتر هەبێت'
          : 'Nikare ji valahiyekê zêdetir hebe';
    }

    // Check no uppercase
    if (val != val.toLowerCase()) {
      return isSorani
          ? 'نابێت پیتی گەورە (کەپیتەڵ) لە ناوی بەکارهێنەردا هەبێت'
          : 'Navê bikarhêner nikare tîpên mezin hebe';
    }

    // Allowed characters: lowercase letters, numbers, and at most one space (English, Kurdish Arabic, Kurmanji Latin)
    // No symbols.
    final allowedRegex = RegExp(
      r'^[a-z0-9çêîşûğöü\u0621-\u064A\u0671-\u06D3\u067E\u0686\u0698\u06A4\u06A9\u06AF\u0660-\u0669\u06F0-\u06F9 ]+$'
    );
    if (!allowedRegex.hasMatch(val)) {
      return isSorani
          ? 'تەنها پیت و ژمارە ڕێگەپێدراوە، نابێت سیمبول بەکاربهێنیت'
          : 'Tenê tîp û hejmar destûr in, nikare sembol hebe';
    }

    return null;
  }
}
