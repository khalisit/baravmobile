import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../data/api_service.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/barav_button.dart';
import '../../core/session/session_controller.dart';
import '../../core/utils/kurdish_format.dart';
import '../../core/utils/error_translator.dart';

class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({super.key});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _codeController = TextEditingController();

  bool _loading = false;
  bool _codeSent = false;
  bool _isCodeComplete = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      final isComplete = _codeController.text.trim().length == 6;
      if (isComplete != _isCodeComplete) {
        setState(() {
          _isCodeComplete = isComplete;
        });
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showErrorDialog(dynamic message) {
    if (!mounted) return;
    ErrorTranslator.showDialogError(context, message);
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    final isSorani = LocaleController.instance.isSorani;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(isSorani ? 'سەرکەوتوو بوو' : 'Serkeftî'),
        content: Text(
          isSorani
              ? 'مۆبایلەکەت بە سەرکەوتوویی سەلمێندرا.'
              : 'Mobîla te bi serkeftî hate pejirandin.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(isSorani ? 'باشە' : 'Temam'),
          ),
        ],
      ),
    );
  }

  String _getSanitizedPhone() {
    final user = SessionController.instance.user;
    if (user == null) return '';
    String phone = user.phone;
    final code = user.phoneCode ?? '+964';

    // If phone already starts with the code, just return it
    if (phone.startsWith(code)) {
      return phone;
    }

    // Remove leading 0 if present
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    return '$code$phone';
  }

  Future<void> _sendOtp() async {
    final user = SessionController.instance.user;
    if (user == null || user.phone.isEmpty) return;

    setState(() => _loading = true);
    try {
      final fullPhone = _getSanitizedPhone();
      await ApiService.sendOtp(fullPhone);

      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _verifyOtp() async {
    if (_codeController.text.trim().length != 6) return;

    final user = SessionController.instance.user;
    if (user == null || user.phone.isEmpty) return;

    setState(() => _loading = true);

    try {
      final code = _codeController.text.trim();
      final fullPhone = _getSanitizedPhone();

      // Verify OTP with our backend
      await ApiService.verifyOtp(fullPhone, code);

      // Refresh session to pull verifyPhone = true
      await SessionController.instance.refreshSession();

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final isSorani = LocaleController.instance.isSorani;
    final user = SessionController.instance.user;
    final fullPhone = KurdishFormat.phone(
      '${user?.phoneCode ?? ''}${user?.phone ?? ''}',
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.ink),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSorani ? 'سەلماندنی مۆبایل' : 'Pejirandina Mobîlê',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (!_codeSent) ...[
                Text(
                  isSorani
                      ? 'بۆ سەلماندنی ژمارەی مۆبایلەکەت، کۆدێک دەنێرین بۆ ئەم ژمارەیە:\n\n$fullPhone'
                      : 'Ji bo pejirandina hejmara te, em ê kodê bişînin vê hejmarê:\n\n$fullPhone',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                BaravButton(
                  label: isSorani ? 'ناردنی کۆد' : 'Koda bişîne',
                  loading: _loading,
                  onPressed: _sendOtp,
                ),
              ] else ...[
                Text(
                  isSorani
                      ? 'کۆدەکەمان نارد بۆ $fullPhone'
                      : 'Me kod şand ji $fullPhone re',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 32),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Center(
                    child: Pinput(
                      length: 6,
                      controller: _codeController,
                      autofocus: true,
                      defaultPinTheme: PinTheme(
                        width: 50,
                        height: 56,
                        textStyle: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.stroke),
                          borderRadius: BorderRadius.circular(12),
                          color: colors.surface,
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 50,
                        height: 56,
                        textStyle: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.purple, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: colors.surface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                BaravButton(
                  label: isSorani ? 'پشتڕاستکردنەوە' : 'Pesend bike',
                  loading: _loading,
                  onPressed: _isCodeComplete ? _verifyOtp : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
