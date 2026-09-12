import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/animation/fade_slide_in.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/barav_button.dart';
import '../../core/widgets/barav_logo.dart';
import '../../core/widgets/barav_text_field.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../data/api_service.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter/services.dart';
import '../../core/utils/error_translator.dart';

// ─── Country picker model ────────────────────────────────────────────────────
class _Country {
  final String flag;
  final String name;
  final String nameKu;
  final String code;
  const _Country({
    required this.flag,
    required this.name,
    required this.nameKu,
    required this.code,
  });
}

const List<_Country> _countries = [
  _Country(flag: '🇮🇶', name: 'Iraq', nameKu: 'عێراق', code: '+964'),
];

enum ForgotPasswordStep { phone, otp, newPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.phone;
  bool _loading = false;

  // Phone step
  final _phoneCtrl = TextEditingController();
  final _Country _selectedCountry = _countries.first;

  // OTP step
  final _otpCtrl = TextEditingController();

  // New Password step
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _isSorani => LocaleController.instance.isSorani;

  String get _localPhone {
    String local = _phoneCtrl.text.trim();
    if (local.startsWith('0')) local = local.substring(1);
    return local;
  }

  String get _fullPhone {
    return '${_selectedCountry.code}$_localPhone';
  }

  void _showError(dynamic msg) {
    if (!mounted) return;
    ErrorTranslator.showDialogError(context, msg);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleInit() async {
    if (_localPhone.isEmpty || _localPhone.length < 9) {
      _showError(
        _isSorani
            ? 'ژمارە مۆبایلەکەت تەواو نییە'
            : 'Hejmara telefonê ne temam e',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await ApiService.forgotPasswordInit(_fullPhone);

      if (mounted) {
        setState(() {
          _loading = false;
          _currentStep = ForgotPasswordStep.otp;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpCtrl.text.length != 6) {
      _showError(_isSorani ? 'کۆدەکە تەواو نییە' : 'Kod ne temam e');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await ApiService.verifyOtp(_fullPhone, _otpCtrl.text);

      if (mounted) {
        setState(() {
          _loading = false;
          _currentStep = ForgotPasswordStep.newPassword;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await ApiService.forgotPasswordReset(
        _fullPhone,
        _otpCtrl.text,
        _passwordCtrl.text,
      );

      if (mounted) {
        setState(() {
          _loading = false;
          _currentStep = ForgotPasswordStep.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // ── Builders ───────────────────────────────────────────────────────────────

  Widget _buildPhoneStep(ThemeData theme, AppColors colors) {
    return Column(
      key: const ValueKey('step_phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Text(
            _isSorani ? 'گەڕاندنەوەی تێپەڕەوشە' : 'Şîfreyê vegerîne',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 10),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: Text(
            _isSorani
                ? 'ژمارە مۆبایلەکەت بنووسە بۆ ئەوەی کۆدی گەڕاندنەوەت بۆ بنێرین.'
                : 'Hejmara telefona xwe binivîse daku em koda vegerandinê ji te re bişînin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 32),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.stroke),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: colors.stroke),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountry.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCountry.code,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: '750 123 4567',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.textMuted.withOpacity(0.5),
                          letterSpacing: 1.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onSubmitted: (_) {
                        _handleInit();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        FadeSlideIn(
          delay: const Duration(milliseconds: 250),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : BaravButton(
                  label: _isSorani ? 'ناردنی کۆد' : 'Koda bişîne',
                  onPressed: _handleInit,
                ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(ThemeData theme, AppColors colors) {
    return Column(
      key: const ValueKey('step_otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Text(
            _isSorani ? 'کۆدەکە بنووسە' : 'Kodê binivîse',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 10),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: Text(
            _isSorani
                ? 'کۆدێکی ٦ ژمارەییمان ناردووە بۆ مۆبایلەکەت.'
                : 'Mameyek 6 hejmarî ji te re şandiye.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 32),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Pinput(
                controller: _otpCtrl,
                length: 6,
                onCompleted: (_) {
                  _handleVerifyOTP();
                },
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 58,
                  textStyle: theme.textTheme.titleLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.stroke),
                    boxShadow: [
                      BoxShadow(
                        color: colors.stroke.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 50,
                  height: 58,
                  textStyle: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.purple, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        FadeSlideIn(
          delay: const Duration(milliseconds: 250),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : BaravButton(
                  label: _isSorani ? 'پشتڕاستکردنەوە' : 'Piştrast bike',
                  onPressed: _handleVerifyOTP,
                ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(ThemeData theme, AppColors colors) {
    return Column(
      key: const ValueKey('step_password'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Text(
            _isSorani ? 'تێپەڕەوشەی نوێ' : 'Şîfreya nû',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 10),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: Text(
            _isSorani
                ? 'تکایە تێپەڕەوشەیەکی نوێ بۆ هەژمارەکەت بنووسە.'
                : 'Ji kerema xwe şîfreyek nû binivîse.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 32),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Form(
            key: _formKey,
            child: BaravTextField(
              label: _isSorani ? 'تێپەڕەوشەی نوێ' : 'Şîfreya nû',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              controller: _passwordCtrl,
              ltr: true,
              obscure: !_passwordVisible,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _loading ? null : _handleResetPassword(),
              helperText: _isSorani
                  ? 'کەمترین ٦ پیت یان ژمارە'
                  : 'Herî kêm 6 tîp',
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.ink.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
              validator: (val) {
                if (val == null || val.length < 6) {
                  return _isSorani
                      ? 'تێپەڕەوشە زۆر کورتە'
                      : 'Şîfre gelek kurt e';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 40),
        FadeSlideIn(
          delay: const Duration(milliseconds: 250),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : BaravButton(
                  label: _isSorani ? 'گۆڕینی تێپەڕەوشە' : 'Şîfreyê biguherîne',
                  onPressed: _handleResetPassword,
                ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep(ThemeData theme, AppColors colors) {
    return Column(
      key: const ValueKey('step_success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        FadeSlideIn(
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Text(
            _isSorani ? 'سەرکەوتوو بوو' : 'Serkeftî bû',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(color: Colors.green),
          ),
        ),
        const SizedBox(height: 10),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: Text(
            _isSorani
                ? 'تێپەڕەوشەکەت بەسەرکەوتوویی گۆڕدرا، دەتوانیت ئێستا بچیتە ژوورەوە.'
                : 'Şîfreya te bi serkeftî hat guherandin, niha tu dikarî têkevî.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
        ),
        const SizedBox(height: 40),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: BaravButton(
            label: _isSorani ? 'چوونە ژوورەوە' : 'Têketin',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    // Provide a floating back button to replace AppBar
    final backButton = PositionedDirectional(
      top: MediaQuery.of(context).padding.top + 8,
      start: 16,
      child: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: colors.ink),
        onPressed: () {
          if (_currentStep == ForgotPasswordStep.otp) {
            setState(() => _currentStep = ForgotPasswordStep.phone);
          } else if (_currentStep == ForgotPasswordStep.newPassword) {
            setState(() => _currentStep = ForgotPasswordStep.otp);
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );

    return Scaffold(
      body: GlowBackdrop(
        child: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_currentStep != ForgotPasswordStep.success) ...[
                            FadeSlideIn(child: Center(child: BaravLogo(size: 60))),
                            const SizedBox(height: 32),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: () {
                              switch (_currentStep) {
                                case ForgotPasswordStep.phone:
                                  return _buildPhoneStep(theme, colors);
                                case ForgotPasswordStep.otp:
                                  return _buildOtpStep(theme, colors);
                                case ForgotPasswordStep.newPassword:
                                  return _buildNewPasswordStep(theme, colors);
                                case ForgotPasswordStep.success:
                                  return _buildSuccessStep(theme, colors);
                              }
                            }(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            backButton,
          ],
        ),
      ),
    );
  }
}
