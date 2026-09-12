import 'package:flutter/material.dart';
import '../localization/locale_controller.dart';
import '../theme/app_colors.dart';

/// وەرگێڕی هەڵەکان بۆ زمانی کوردی (سۆرانی و بادینی/کرمانجی).
/// ئەم پۆلە هەموو هەڵەکانی Backend، Firebase، و سیستەم وەردەگێڕێت
/// بۆ دەقی کوردی پاراو تا هیچ دەقێکی نەخوازراوی ئینگلیزی پیشانی بەکارهێنەر نەدرێت.
class ErrorTranslator {
  ErrorTranslator._();

  /// وەرگێڕانی هەر پەیامێکی هەڵە بۆ کوردی بەپێی شێوەزاری هەڵبژێردراو.
  static String translate(dynamic error, {bool? isSorani}) {
    if (error == null) return '';

    final sorani = isSorani ?? LocaleController.instance.isSorani;
    final raw = error.toString();
    final e = raw
        .replaceAll('Exception: ', '')
        .replaceAll('PlatformException: ', '')
        .trim()
        .toLowerCase();

    // ١. هەڵوەشاندنەوە لەلایەن بەکارهێنەر (Cancel)
    if (e.contains('cancel') || e.contains('1001')) {
      return '';
    }

    // ٢. هەژمار نەدۆزرایەوە (No Account / User Not Found)
    if (e.contains('no account found with this phone number') ||
        e.contains('no account found')) {
      return sorani
          ? 'هیچ هەژمارێک بەم ژمارە مۆبایلە نەدۆزرایەوە.'
          : 'Bi vê hejmara telefonê ti hesab nehate dîtin.';
    }
    if (e.contains('user not found') || e.contains('user-not-found')) {
      return sorani
          ? 'ئەم هەژمارە بوونی نییە.'
          : 'Ev hesab tune ye.';
    }

    // ٣. تێپەڕەوشەی هەڵە و کێشەی داتا
    if (e.contains('incorrect password') ||
        e.contains('wrong-password') ||
        e.contains('wrong password') ||
        e.contains('invalid-credential') ||
        e.contains('invalid credentials') ||
        e.contains('invalid password')) {
      return sorani
          ? 'تێپەڕەوشە یان ژمارەی مۆبایلەکە هەڵەیە.'
          : 'Şîfre an hejmara telefonê çewt e.';
    }
    if (e.contains('password must be at least 6 characters') ||
        e.contains('password too short')) {
      return sorani
          ? 'تێپەڕەوشە دەبێت لانی کەم ٦ پیت یان ژمارە بێت.'
          : 'Pêwîst e şîfre herî kêm 6 tîp an hejmar be.';
    }
    if (e.contains('password reset is not allowed') ||
        e.contains('this account uses')) {
      return sorani
          ? 'ئەم هەژمارە بە گووگڵ یان ئەپڵ دروستکراوە، ناتوانیت تێپەڕەوشەی بۆ دابنێیت.'
          : 'Ev hesab bi Google an Apple hatiye çêkirin, nikarî şîfreyê bo deynî.';
    }
    if (e.contains('failed to reset password')) {
      return sorani
          ? 'گۆڕینی تێپەڕەوشە سەرکەوتوو نەبوو، تکایە دواتر هەوڵبدەرەوە.'
          : 'Guhertina şîfreyê bi ser neket, ji kerema xwe paşê hewl bide.';
    }

    // ٤. کێشەی کۆدی کورتەنامە (OTP)
    if (e.contains('invalid or expired code') ||
        e.contains('phone number not verified or invalid code') ||
        e.contains('invalid code') ||
        e.contains('expired code') ||
        e.contains('invalid-verification-code')) {
      return sorani
          ? 'کۆدی پشتڕاستکردنەوە هەڵەیە یان بەسەرچووە.'
          : 'Koda piştrastkirinê çewt e an dema wê derbas bûye.';
    }
    if (e.contains('failed to send otp') ||
        e.contains('failed to send code') ||
        e.contains('error sending sms')) {
      return sorani
          ? 'ناردنی کۆد سەرکەوتوو نەبوو، تکایە کەمێکی تر هەوڵبدەرەوە.'
          : 'Şandina kodê bi ser neket, ji kerema xwe hinek şûnde hewl bide.';
    }

    // ٥. ژمارەی مۆبایل و یوزەرنەیم دووبارەیە
    if (e.contains('phone number already registered') ||
        e.contains('phone number already in use') ||
        e.contains('phone already in use') ||
        e.contains('phone is already taken')) {
      return sorani
          ? 'ئەم ژمارە مۆبایلە پێشتر تۆمارکراوە.'
          : 'Ev hejmara telefonê berê hatiye tomarkirin.';
    }
    if (e.contains('username already taken') ||
        e.contains('username is already taken') ||
        e.contains('username is taken') ||
        e.contains('username_taken')) {
      return sorani
          ? 'ئەم ناوی بەکارهێنەرە پێشتر گیراوە، ناوێکی تر هەڵبژێرە.'
          : 'Ev navê bikarhêner berê hatiye girtin, navekî din hilbijêre.';
    }
    if (e.contains('email already in use') ||
        e.contains('email-already-in-use')) {
      return sorani
          ? 'ئەم ئیمەیڵە پێشتر تۆمارکراوە.'
          : 'Ev e-mail berê hatiye tomarkirin.';
    }

    // ٦. کاتی گۆڕینی ناو یان ناوی بەکارهێنەر (Limit 30 days)
    if (e.contains('30 days')) {
      return sorani
          ? 'تەنها لە هەر ٣٠ ڕۆژدا یەک جار دەتوانیت ئەم زانیارییە بگۆڕیت.'
          : 'Tenê her 30 rojan carekê dikarî van agahiyan biguherî.';
    }

    // ٧. کێشەی هێڵی ئینتەرنێت
    if (e.contains('network-request-failed') ||
        e.contains('socketexception') ||
        e.contains('failed host lookup') ||
        e.contains('clientexception') ||
        e.contains('httpexception') ||
        e.contains('timeoutexception') ||
        e.contains('connection refused') ||
        e.contains('network error')) {
      return sorani
          ? 'کێشە لە هێڵی ئینتەرنێت هەیە، تکایە پەیوەندییەکەت بپشکنە.'
          : 'Pirsgirêka înternetê heye, ji kerema xwe înterneta xwe kontrol bike.';
    }

    // ٨. زۆریی هەوڵدان (Rate limit)
    if (e.contains('too-many-requests') || e.contains('too many requests')) {
      return sorani
          ? 'هەوڵێکی زۆر دراوە لە ماوەیەکی کەمدا، تکایە کەمێکی تر هەوڵبدەرەوە.'
          : 'Gelek hewldan hatin kirin, ji kerema xwe hinek şûnde hewl bide.';
    }

    // ٩. چوونەژوورەوەی گووگڵ و ئەپڵ
    if (e.contains('google_sign_in') ||
        e.contains('google login error') ||
        e.contains('gidclientid')) {
      return sorani
          ? 'چوونەژوورەوە بە گووگڵ سەرکەوتوو نەبوو، تکایە دووبارە هەوڵبدەرەوە.'
          : 'Têketina bi Google bi ser neket, ji kerema xwe dîsa hewl bide.';
    }
    if (e.contains('signinwithappleauthorizationexception') ||
        e.contains('authorizationerror') ||
        e.contains('authenticationservices')) {
      return sorani
          ? 'چوونەژوورەوە بە ئەپڵ سەرکەوتوو نەبوو، تکایە دووبارە هەوڵبدەرەوە.'
          : 'Têketina bi Apple bi ser neket, ji kerema xwe dîsa hewl bide.';
    }
    if (e.contains('authentication failed')) {
      return sorani
          ? 'سەلماندنی هەژمار سەرکەوتوو نەبوو.'
          : 'Pejirandina hesabî bi ser neket.';
    }

    // ١٠. ژمارە و ئیمەیڵی نادروست
    if (e.contains('invalid-phone-number') || e.contains('invalid phone')) {
      return sorani
          ? 'ژمارەی مۆبایلەکە دروست نییە.'
          : 'Hejmara telefonê ne rast e.';
    }
    if (e.contains('invalid-email') || e.contains('invalid email')) {
      return sorani ? 'ئیمەیڵەکە دروست نییە.' : 'E-mail ne rast e.';
    }

    // ١١. هەژماری ڕاگیراو
    if (e.contains('banned') ||
        e.contains('disabled') ||
        e.contains('user-disabled')) {
      return sorani
          ? 'ئەم هەژمارە ڕاگیراوە، تکایە پەیوەندی بە پشتگیرییەوە بکە.'
          : 'Ev hesab hatiye sekinandin, ji kerema xwe peywendiyê bi piştgiriyê re bike.';
    }

    // ١٢. کاتی بەکارهێنان بەسەرچوو
    if (e.contains('unauthorized') ||
        e.contains('session expired') ||
        e.contains('token expired')) {
      return sorani
          ? 'کاتی بەکارهێنان بەسەرچوو، تکایە دووبارە بچۆرەوە ژوورەوە.'
          : 'Dema rûniştinê derbas bû, ji kerema xwe dîsa têkeve.';
    }

    // ١٣. وێنەی پڕۆفایل
    if (e.contains('failed to pick image') ||
        e.contains('failed to upload avatar')) {
      return sorani
          ? 'دانانی وێنە سەرکەوتوو نەبوو.'
          : 'Barkirina wêneyê bi ser neket.';
    }

    // ئەگەر دەقەکە پێشتر کوردی بوو، وەک خۆی بیگەڕێنەرەوە
    final hasArabicScript = RegExp(r'[\u0600-\u06FF]').hasMatch(raw);
    if (hasArabicScript && !raw.contains('Exception') && !raw.contains('Error:')) {
      return raw.trim();
    }

    // دەقی بنەڕەتی (Fallback)
    return sorani
        ? 'کێشەیەک ڕوویدا، تکایە کەمێکی تر هەوڵبدەرەوە.'
        : 'Pirsgirêkek çêbû, ji kerema xwe hinek şûnde hewl bide.';
  }

  /// نیشاندانی دیالۆگی ستاندارد و پاراوی کوردی بۆ هەموو هەڵەکان
  static Future<void> showDialogError(
    BuildContext context,
    dynamic error, {
    String? customTitle,
    VoidCallback? onConfirm,
  }) async {
    final sorani = LocaleController.instance.isSorani;
    final translated = translate(error, isSorani: sorani);

    // ئەگەر هەڵوەشێنرابێتەوە، هیچ دیالۆگێک پیشان مەدە
    if (translated.isEmpty) return;

    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: colors.stroke),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  customTitle ?? (sorani ? 'کێشەیەک هەیە' : 'Pirsgirêkek heye'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            translated,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                onConfirm?.call();
              },
              child: Text(
                sorani ? 'باشە' : 'Baş e',
                style: TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
