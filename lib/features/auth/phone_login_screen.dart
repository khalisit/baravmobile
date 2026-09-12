import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/animation/fade_slide_in.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/routing/transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/barav_button.dart';
import '../../core/widgets/barav_logo.dart';
import '../../core/widgets/barav_text_field.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../core/widgets/social_auth_button.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/theme_toggle_button.dart';
import '../shell/main_shell.dart';
import 'complete_profile_screen.dart';
import 'otp_verification_screen.dart';
import '../../data/api_service.dart';
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

// ─── Screen ──────────────────────────────────────────────────────────────────

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key, int initialTabIndex = 0});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  _Country _selectedCountry = _countries.first;

  bool _loading = false;
  bool _phoneTaken = false;
  bool _isCheckingPhone = false;
  Timer? _phoneDebounce;

  @override
  void dispose() {
    _phoneDebounce?.cancel();
    _phoneCtrl.dispose();
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

  // ── Register with Phone ────────────────────────────────────────────────────

  Future<void> _doRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_phoneTaken || _isCheckingPhone) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(
        softRoute(
          OtpVerificationScreen(
            fullPhoneNumber: _fullPhone,
            localPhoneNumber: _localPhone,
            password: _passwordCtrl.text,
            phoneCode: _selectedCountry.code,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _onPhoneChanged(String value) {
    if (_phoneDebounce?.isActive ?? false) _phoneDebounce!.cancel();

    if (value.isEmpty) return;

    setState(() {
      _isCheckingPhone = true;
    });

    _phoneDebounce = Timer(const Duration(milliseconds: 500), () async {
      String local = value.trim();
      if (local.startsWith('0')) local = local.substring(1);

      final isAvailable = await ApiService.checkAvailability(
        field: 'phone',
        value: local,
      );

      if (mounted) {
        setState(() {
          _phoneTaken = !isAvailable;
          _isCheckingPhone = false;
        });
      }
    });
  }

  // ── Register with Social Providers ─────────────────────────────────────────

  Future<void> _handleProviderLogin(SocialProvider provider) async {
    setState(() => _loading = true);
    try {
      UserCredential? userCredential;

      if (provider == SocialProvider.google) {
        GoogleSignInAccount? gUser;
        try {
          gUser = await GoogleSignIn.instance.authenticate();
        } catch (e) {
          setState(() => _loading = false);
          if (e.toString().toLowerCase().contains('cancel')) {
            return;
          }
          _showError(e);
          return;
        }
        final GoogleSignInAuthentication gAuth = gUser.authentication;
        if (gAuth.idToken == null) {
          throw Exception(
            _isSorani
                ? 'ناسنامەی گۆگڵ دەستنەکەوت (ID Token null)'
                : 'Google ID token not found',
          );
        }
        final credential = GoogleAuthProvider.credential(
          idToken: gAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      } else if (provider == SocialProvider.apple) {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          oauthCredential,
        );
      }

      if (userCredential == null) {
        throw Exception("Authentication failed");
      }

      final token = await userCredential.user?.getIdToken();
      if (token == null) {
        throw Exception("Failed to get Firebase token");
      }

      final isNewUser = await SessionController.instance.signInWithProvider(
        token,
      );

      if (!mounted) return;

      if (isNewUser) {
        final fbUser = userCredential.user;
        final initialName = fbUser?.displayName;
        final initialAvatarUrl = fbUser?.photoURL;
        String? initialUsername;
        if (fbUser?.email != null) {
          initialUsername = fbUser!.email!.split('@')[0];
        } else if (fbUser?.displayName != null) {
          initialUsername = fbUser!.displayName!
              .replaceAll(' ', '')
              .toLowerCase();
        }

        Navigator.of(context).pushReplacement(
          softRoute(
            CompleteProfileScreen(
              token: token,
              provider: provider.name,
              initialName: initialName,
              initialAvatarUrl: initialAvatarUrl,
              initialUsername: initialUsername,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(fadeRoute(const MainShell()));
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().toLowerCase().contains('cancel') ||
          e.toString().contains('1001')) {
        return;
      }
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(dynamic msg) {
    if (!mounted) return;
    ErrorTranslator.showDialogError(context, msg);
  }

  // ── Country picker sheet ───────────────────────────────────────────────────

  Future<void> _pickCountry() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = AppColors.of(context);
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _isSorani ? 'وڵات هەڵبژێرە' : 'Welat hilbijêre',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (_, i) {
                    final c = _countries[i];
                    final selected = c.code == _selectedCountry.code;
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Text(
                          c.flag,
                          style: const TextStyle(fontSize: 26),
                        ),
                        title: Text(_isSorani ? c.nameKu : c.name),
                        trailing: Text(
                          c.code,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontFamily: 'monospace',
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppColors.purpleLight,
                        onTap: () {
                          setState(() => _selectedCountry = c);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Custom Wide Social Button Builder ──────────────────────────────────────

  Widget _buildWideSocialButton({
    required SocialProvider provider,
    required String text,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return PressableScale(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.stroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialGlyph(provider),
            const SizedBox(width: 12),
            Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Scaffold(
      body: GlowBackdrop(
        intensity: 0.7,
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final t = ((constraints.maxHeight - 600) / 140).clamp(
                    0.0,
                    1.0,
                  );
                  double fit(double tight, double roomy) =>
                      tight + (roomy - tight) * t;
                  double gap(double value) => value * fit(0.6, 1.0);

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, gap(16), 24, gap(24)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - gap(32),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeSlideIn(
                              child: Center(
                                child: BaravLogo(size: fit(54, 72)),
                              ),
                            ),
                            SizedBox(height: gap(10)),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 50),
                              child: Center(
                                child: BaravWordmark(fontSize: fit(20, 24)),
                              ),
                            ),
                            SizedBox(height: gap(24)),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 100),
                              child: Text(
                                _isSorani
                                    ? 'تۆمارکردنی نوێ'
                                    : 'Tomearkirina Nû',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: fit(19, 22),
                                ),
                              ),
                            ),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 120),
                              child: Text(
                                _isSorani
                                    ? 'زانیارییەکانت بنووسە بۆ دروستکردنی هەژمارێکی نوێ'
                                    : 'Agahiyên xwe binivîse bo çêkirina hesabekî nû',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                            SizedBox(height: gap(24)),

                            // Country picker + phone field
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 60),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 6,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      _isSorani
                                          ? 'ژمارەی مۆبایل'
                                          : 'Jimareya telefonê',
                                      style: theme.textTheme.labelMedium!
                                          .copyWith(color: colors.textMuted),
                                    ),
                                  ),
                                  FormField<String>(
                                    initialValue: _phoneCtrl.text,
                                    validator: (v) {
                                      final val = _phoneCtrl.text;
                                      if (val.trim().length < 7) {
                                        return _isSorani
                                            ? 'ژمارەی درووست بنووسە'
                                            : 'Jimareyeke rast binivîse';
                                      }
                                      if (_phoneTaken) {
                                        return _isSorani
                                            ? '❌ ئەم ژمارەیە پێشتر گیراوە'
                                            : '❌ Ev hejmar hatye girtin';
                                      }
                                      return null;
                                    },
                                    builder: (FormFieldState<String> state) {
                                      final hasError = state.hasError;
                                      final errorString = state.errorText;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Country button
                                                GestureDetector(
                                                  onTap: _pickCountry,
                                                  child: Container(
                                                    height: 56,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: colors.surface,
                                                      borderRadius:
                                                          BorderRadius.circular(18),
                                                      border: Border.all(
                                                        color: hasError ? AppColors.danger : colors.stroke,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _selectedCountry.flag,
                                                          style: const TextStyle(
                                                            fontSize: 22,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          _selectedCountry.code,
                                                          style: theme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight.w600,
                                                                fontFamily: 'monospace',
                                                              ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Icon(
                                                          Icons.expand_more_rounded,
                                                          color: colors.textMuted,
                                                          size: 18,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                // Phone number field
                                                Expanded(
                                                  child: TextField(
                                                    controller: _phoneCtrl,
                                                    keyboardType: TextInputType.number,
                                                    textDirection: TextDirection.ltr,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    onChanged: (val) {
                                                      state.didChange(val);
                                                      _onPhoneChanged(val);
                                                    },
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter
                                                          .digitsOnly,
                                                    ],
                                                    style: theme.textTheme.bodyLarge
                                                        ?.copyWith(
                                                          fontFamily: 'monospace',
                                                        ),
                                                    decoration: InputDecoration(
                                                      hintText: '750 000 0000',
                                                      hintStyle: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: colors.textFaint,
                                                          ),
                                                      prefixIcon: Icon(
                                                        Icons.phone_outlined,
                                                        color: hasError ? AppColors.danger : null,
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 17,
                                                            horizontal: 16,
                                                          ),
                                                      isDense: true,
                                                      filled: true,
                                                      fillColor: colors.surface,
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(18),
                                                        borderSide: BorderSide(
                                                          color: hasError ? AppColors.danger : colors.stroke,
                                                        ),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(18),
                                                        borderSide: BorderSide(
                                                          color: hasError ? AppColors.danger : colors.stroke,
                                                        ),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(18),
                                                        borderSide: BorderSide(
                                                          color: hasError ? AppColors.danger : AppColors.purpleLight,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      suffixIcon: _isCheckingPhone
                                                          ? const Padding(
                                                              padding: EdgeInsets.all(
                                                                12.0,
                                                              ),
                                                              child: SizedBox(
                                                                width: 16,
                                                                height: 16,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                      strokeWidth: 2,
                                                                    ),
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          if (errorString != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                                left: 8,
                                                right: 8,
                                              ),
                                              child: Text(
                                                errorString,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: AppColors.danger,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          else if (_isCheckingPhone)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                                left: 8,
                                                right: 8,
                                              ),
                                              child: Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 1.5,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _isSorani
                                                        ? 'چێک دەکرێت... 🔍'
                                                        : 'Tê kontrolkirin... 🔍',
                                                    style: theme.textTheme.bodySmall
                                                        ?.copyWith(
                                                          color: colors.textMuted,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else if (_phoneCtrl.text.trim().length >= 7 && !_phoneTaken)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                                left: 8,
                                                right: 8,
                                              ),
                                              child: Text(
                                                _isSorani
                                                    ? '✅ ئەم ژمارەیە بەردەستە'
                                                    : '✅ Ev hejmar berdest e',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 100),
                              child: BaravTextField(
                                label: _isSorani ? 'تێپەڕی ووشە' : 'Şîfre',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                controller: _passwordCtrl,
                                ltr: true,
                                obscure: !_passwordVisible,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) =>
                                    _loading ? null : _doRegister(),
                                helperText: _isSorani
                                    ? 'کەمترین ٦ پیت'
                                    : 'Herî kêm 6 tîp',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: colors.textMuted,
                                  ),
                                  onPressed: () => setState(
                                    () => _passwordVisible = !_passwordVisible,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return _isSorani
                                        ? 'تێپەڕی ووشە کەمترین ٦ پیت دەبێت'
                                        : 'Şîfre divê herî kêm 6 tîp be';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: gap(28)),

                            // Register Button
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 180),
                              child: _loading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : BaravButton(
                                      label: _isSorani
                                          ? 'دروستکردنی هەژمار'
                                          : 'Hesab çêke',
                                      onPressed: _doRegister,
                                    ),
                            ),
                            SizedBox(height: gap(24)),

                            // Horizontal Divider
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 210),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: colors.stroke),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      _isSorani
                                          ? 'یان خۆتۆمارکردن بە'
                                          : 'An tomarkirin bi',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: colors.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: colors.stroke),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: gap(16)),

                            // Horizontal Social Buttons row
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 240),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildWideSocialButton(
                                      provider: SocialProvider.google,
                                      text: 'Google',
                                      onTap: () => _handleProviderLogin(
                                        SocialProvider.google,
                                      ),
                                    ),
                                  ),
                                  if (theme.platform !=
                                      TargetPlatform.android) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildWideSocialButton(
                                        provider: SocialProvider.apple,
                                        text: 'Apple',
                                        onTap: () => _handleProviderLogin(
                                          SocialProvider.apple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: gap(28)),

                            // Already have account? Login link
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 270),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isSorani
                                        ? 'پێشتر هەژمارت دروستکردووە؟'
                                        : 'Hesabê te yê berê heye?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.textMuted,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(
                                      _isSorani ? 'چوونە ژوورەوە' : 'Têketin',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.purpleLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const PositionedDirectional(
                top: 8,
                start: 16,
                child: ThemeToggleButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Social Glyph Icon serving
class _SocialGlyph extends StatelessWidget {
  const _SocialGlyph(this.provider);
  final SocialProvider provider;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.of(context).ink;
    switch (provider) {
      case SocialProvider.apple:
        return Image.asset(
          'assets/images/apple.png',
          width: 26,
          fit: BoxFit.cover,
        );

      case SocialProvider.google:
        return Image.asset(
          'assets/images/google.png',
          width: 23,
          fit: BoxFit.cover,
        );
      case SocialProvider.phone:
        return Icon(Icons.phone_rounded, size: 24, color: ink);
    }
  }
}