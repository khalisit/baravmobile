// ignore_for_file: await_only_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/animation/fade_slide_in.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/routing/transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_translator.dart';
import '../../core/widgets/barav_logo.dart';
import '../../core/widgets/dialect_picker_dialog.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../core/widgets/social_auth_button.dart';
import '../../core/widgets/theme_toggle_button.dart';
import '../../core/widgets/barav_text_field.dart';
import '../../core/widgets/barav_button.dart';
import '../../core/session/session_controller.dart';
import '../shell/main_shell.dart';
import 'phone_login_screen.dart';
import 'complete_profile_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  String _loadingState = 'none'; // 'none', 'password', 'google', 'apple'
  bool _dialectPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowDialectPicker();
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isSorani => LocaleController.instance.isSorani;

  Future<void> _maybeShowDialectPicker() async {
    if (!mounted || _dialectPromptShown) return;
    if (LocaleController.instance.hasChosenDialect) return;
    _dialectPromptShown = true;

    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted || LocaleController.instance.hasChosenDialect) return;

    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (navigator == null) return;

    try {
      await showDialectPickerDialog(context);
    } catch (_) {
      if (!LocaleController.instance.hasChosenDialect) {
        await LocaleController.instance.chooseDialect(AppLocale.ckb);
      }
    }
  }

  // ── Password Auth ──────────────────────────────────────────────────────────

  Future<void> _handlePasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loadingState = 'password');
    try {
      String identifier = _identifierController.text.trim();
      if (identifier.startsWith('0') &&
          RegExp(r'^[0-9]+$').hasMatch(identifier)) {
        identifier = identifier.substring(1);
      }

      await SessionController.instance.signInWithPhone(
        identifier: identifier,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(const MainShell()));
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingState = 'none');
    }
  }

  // ── Social Providers Auth ──────────────────────────────────────────────────

  Future<void> _handleProviderLogin(SocialProvider provider) async {
    setState(() => _loadingState = provider.name);
    try {
      UserCredential? userCredential;

      if (provider == SocialProvider.google) {
        try {
          debugPrint('=== GOOGLE LOGIN START ===');

          final GoogleSignInAccount gUser = await GoogleSignIn.instance
              .authenticate();

          debugPrint('Google user: ${gUser.email}');
          debugPrint('Google user id: ${gUser.id}');

          final GoogleSignInAuthentication gAuth = await gUser.authentication;

          debugPrint('Google idToken exists: ${gAuth.idToken != null}');
          debugPrint('Google idToken length: ${gAuth.idToken?.length ?? 0}');

          if (gAuth.idToken == null) {
            throw Exception(
              'Google ID Token is null. Check Google OAuth configuration.',
            );
          }

          final credential = GoogleAuthProvider.credential(
            idToken: gAuth.idToken,
          );

          debugPrint('Firebase credential created');

          userCredential = await FirebaseAuth.instance.signInWithCredential(
            credential,
          );

          debugPrint('Firebase user: ${userCredential.user?.uid}');
          debugPrint('Firebase email: ${userCredential.user?.email}');
        } catch (e, stackTrace) {
          debugPrint('=== GOOGLE LOGIN ERROR ===');
          debugPrint('ERROR: $e');
          debugPrint('STACK: $stackTrace');

          if (mounted) {
            setState(() => _loadingState = 'none');
            if (!e.toString().toLowerCase().contains('cancel')) {
              _showErrorDialog(e.toString());
            }
          }

          return;
        }
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
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _loadingState = 'none');
    }
  }

  Future<void> _showErrorDialog(dynamic message) async {
    if (!mounted) return;
    await ErrorTranslator.showDialogError(context, message);
  }

  // ── Custom Social Button Builder ──────────────────────────────────────────

  Widget _buildSignUpLink(ThemeData theme, AppColors colors) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 120),
      child: SizedBox(
        height: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isSorani ? 'هەژمارت نییە؟' : 'Hesabê te nîne?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textMuted,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(softRoute(const PhoneLoginScreen(initialTabIndex: 1)));
              },
              child: Text(
                _isSorani ? 'دروستکردنی هەژمار' : 'Hesab çêke',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.purpleLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideSocialButton({
    required SocialProvider provider,
    required String text,
    required VoidCallback onTap,
    required bool isLoading,
    required bool isDisabled,
  }) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return PressableScale(
      onTap: isDisabled ? null : onTap,
      scale: isDisabled ? 1.0 : 0.96,
      child: Opacity(
        opacity: isDisabled && !isLoading ? 0.6 : 1.0,
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
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.ink),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialGlyph(provider, color: colors.ink),
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
        ),
      ),
    );
  }

  Widget _buildCredentialsForm(
    ThemeData theme,
    AppColors colors,
    double Function(double, double) fit,
    double Function(double) gap,
  ) {
    return Column(
      key: const ValueKey('credentials_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: BaravTextField(
            label: _isSorani ? 'ژمارەی مۆبایل' : 'Hejmara telefonê',
            hint: '07501234567',
            icon: Icons.phone_outlined,
            controller: _identifierController,
            ltr: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return _isSorani
                    ? 'ژمارەی مۆبایل بنووسە'
                    : 'Hejmara telefonê binivîse';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: BaravTextField(
            label: _isSorani ? 'تێپەڕی ووشە' : 'Şîfre',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            controller: _passwordController,
            obscure: !_passwordVisible,
            ltr: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handlePasswordLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: colors.textMuted,
              ),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return _isSorani ? 'تێپەڕی ووشە بنووسە' : 'Şîfre binivîse';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: gap(24)),

        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: BaravButton(
            label: _isSorani ? 'چوونە ژوورەوە' : 'Têketin',
            onPressed: _loadingState != 'none' ? null : _handlePasswordLogin,
            loading: _loadingState == 'password',
            height: fit(46, 50),
          ),
        ),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: const Duration(milliseconds: 220),
          child: SizedBox(
            height: 40,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: Text(
                _isSorani
                    ? 'وشەی نهێنیت لەبیرچووە؟'
                    : 'Şîfreya xwe ji bîr kir?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: gap(10)),

        _buildSignUpLink(theme, colors),
        SizedBox(height: gap(10)),
        FadeSlideIn(
          delay: const Duration(milliseconds: 250),
          child: Row(
            children: [
              Expanded(child: Divider(color: colors.stroke)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _isSorani ? 'یان چوونەژوورەوە بە' : 'An têketin bi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
              Expanded(child: Divider(color: colors.stroke)),
            ],
          ),
        ),
        SizedBox(height: gap(16)),
        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          child: Row(
            children: [
              Expanded(
                child: _buildWideSocialButton(
                  provider: SocialProvider.google,
                  text: 'Google',
                  onTap: () => _handleProviderLogin(SocialProvider.google),
                  isLoading: _loadingState == SocialProvider.google.name,
                  isDisabled: _loadingState != 'none',
                ),
              ),
              if (theme.platform != TargetPlatform.android) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWideSocialButton(
                    provider: SocialProvider.apple,
                    text: 'Apple',
                    onTap: () => _handleProviderLogin(SocialProvider.apple),
                    isLoading: _loadingState == SocialProvider.apple.name,
                    isDisabled: _loadingState != 'none',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Scaffold(
      body: GlowBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final t = ((constraints.maxHeight - 650) / 140).clamp(
                    0.0,
                    1.0,
                  );
                  double fit(double tight, double roomy) =>
                      tight + (roomy - tight) * t;
                  double gap(double value) => value * fit(0.6, 1.0);

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, gap(24), 24, gap(24)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - gap(48),
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
                            SizedBox(height: gap(8)),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 50),
                              child: Center(
                                child: BaravWordmark(fontSize: fit(20, 24)),
                              ),
                            ),
                            SizedBox(height: gap(8)),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 100),
                              child: Text(
                                AppStrings.loginTitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: fit(19, 22),
                                ),
                              ),
                            ),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 120),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  _isSorani
                                      ? 'زانیارییەکانت بنووسە بۆ چوونە ژوورەوە'
                                      : 'Agahiyên xwe binivîse bo têketinê',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: gap(24)),

                            // Animated Transition switcher
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      final offsetAnimation =
                                          Tween<Offset>(
                                            begin: const Offset(0.0, 0.08),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            ),
                                          );
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        ),
                                      );
                                    },
                                child: _buildCredentialsForm(
                                  theme,
                                  colors,
                                  fit,
                                  gap,
                                ),
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

// Helper glyph class
class _SocialGlyph extends StatelessWidget {
  const _SocialGlyph(this.provider, {this.color});
  final SocialProvider provider;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? AppColors.of(context).ink;
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