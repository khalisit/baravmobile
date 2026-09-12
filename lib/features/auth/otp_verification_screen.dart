import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../data/api_service.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/routing/transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/barav_button.dart';
import '../../core/session/session_controller.dart';
import '../../core/utils/error_translator.dart';
import 'complete_profile_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String fullPhoneNumber;
  final String localPhoneNumber;
  final String password;
  final String phoneCode;

  const OtpVerificationScreen({
    super.key,
    required this.fullPhoneNumber,
    required this.localPhoneNumber,
    required this.password,
    required this.phoneCode,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sending = false;
  bool _isCodeComplete = false;
  bool _codeSent = false;

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

  Future<void> _sendCode() async {
    setState(() => _sending = true);
    try {
      await ApiService.sendOtp(widget.fullPhoneNumber);
      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_codeController.text.trim().length != 6) return;
    setState(() => _loading = true);

    try {
      final code = _codeController.text.trim();

      // Verify OTP with our backend
      await ApiService.verifyOtp(widget.fullPhoneNumber, code);

      // Register the user with backend after OTP is verified
      final res = await SessionController.instance.registerPhoneUser(
        phone: widget.localPhoneNumber,
        password: widget.password,
        code: code,
        phoneCode: widget.phoneCode,
      );

      if (!mounted) return;

      final accessToken = res['tokens']['accessToken'] as String;
      Navigator.of(context).pushReplacement(
        softRoute(CompleteProfileScreen(token: accessToken, provider: 'phone')),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorDialog(dynamic message) {
    if (!mounted) return;
    ErrorTranslator.showDialogError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final isSorani = LocaleController.instance.isSorani;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.ink),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isSorani ? 'دڵنیاکردنەوەی ژمارە' : 'Verifikasyona jimarê',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSorani
                      ? 'کۆدەکە بنێرە بۆ ${widget.fullPhoneNumber} دواتر بینووسە'
                      : 'Kod bişîne ji ${widget.fullPhoneNumber} re paşê binivîse',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),

                // Send Code Button
                BaravButton(
                  label: _codeSent
                      ? (isSorani ? 'کۆد دووبارە بنێرە' : 'Kod dîsa bişîne')
                      : (isSorani ? 'کۆد بنێرە' : 'Kod bişîne'),
                  loading: _sending,
                  onPressed: _sending ? null : _sendCode,
                ),

                if (_codeSent) ...[
                  const SizedBox(height: 24),
                  Text(
                    isSorani
                        ? '✅ کۆدەکەمان نارد بۆ ${widget.fullPhoneNumber}'
                        : '✅ Me kod şand ji ${widget.fullPhoneNumber} re',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
                            border: Border.all(
                              color: AppColors.purple,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: colors.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
      ),
    );
  }
}
