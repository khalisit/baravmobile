import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/animation/fade_slide_in.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/routing/transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/barav_button.dart';
import '../../core/widgets/barav_text_field.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../core/session/session_controller.dart';
import '../../core/services/avatar_picker_service.dart';
import '../../data/api_service.dart';
import '../shell/main_shell.dart';

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

class CompleteProfileScreen extends StatefulWidget {
  final String token;
  final String provider;
  final String? initialName;
  final String? initialAvatarUrl;
  final String? initialUsername;

  final String? initialPhone;

  const CompleteProfileScreen({
    super.key,
    required this.token,
    required this.provider,
    this.initialName,
    this.initialAvatarUrl,
    this.initialUsername,
    this.initialPhone,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late _Country _selectedCountry;
  String? _avatarPath;
  bool _loading = false;

  bool _usernameTaken = false;
  bool _isCheckingUsername = false;
  Timer? _debounce;

  bool _phoneTaken = false;
  bool _isCheckingPhone = false;
  Timer? _phoneDebounce;

  final _avatarPicker = AvatarPickerService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _usernameController = TextEditingController(text: widget.initialUsername);
    _avatarPath = widget.initialAvatarUrl;
    
    final phone = widget.initialPhone ?? SessionController.instance.user?.phone ?? '';
    _Country? detectedCountry;

    for (final c in _countries) {
      if (phone.startsWith(c.code)) {
        detectedCountry = c;
        break;
      }
    }
    
    if (detectedCountry != null) {
      _selectedCountry = detectedCountry;
      final localNumber = phone.substring(detectedCountry.code.length);
      _phoneController = TextEditingController(text: localNumber);
    } else {
      _selectedCountry = _countries.first;
      _phoneController = TextEditingController(text: phone);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _phoneDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final cleanVal = value.trim().toLowerCase();
    if (cleanVal.isEmpty || Validators.username(cleanVal) != null) {
      setState(() {
        _usernameTaken = false;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameTaken = false;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final isAvailable = await ApiService.checkAvailability(
        field: 'username',
        value: cleanVal,
      );

      if (mounted) {
        setState(() {
          _usernameTaken = !isAvailable;
          _isCheckingUsername = false;
        });
      }
    });
  }

  void _onPhoneChanged(String value) {
    if (_phoneDebounce?.isActive ?? false) _phoneDebounce!.cancel();

    final cleanVal = value.trim();
    if (cleanVal.isEmpty) {
      setState(() {
        _phoneTaken = false;
        _isCheckingPhone = false;
      });
      return;
    }

    setState(() {
      _isCheckingPhone = true;
      _phoneTaken = false;
    });

    _phoneDebounce = Timer(const Duration(milliseconds: 500), () async {
      final isAvailable = await ApiService.checkAvailability(
        field: 'phone',
        value: cleanVal, // Assuming backend checks full phone or local phone?
      );
      // Backend actually expects full phone number with code, but wait!
      // In phone_login_screen we send `phone` which includes code? No, in register-provider we send phone: _phoneController.text.trim(), phoneCode: _selectedCountry.code.
      // But in users table it is stored as phone: "7701234567" and phoneCode: "+964".
      // Let's send only `cleanVal` to check-availability because that's what's stored in `phone` column.

      if (mounted) {
        setState(() {
          _phoneTaken = !isAvailable;
          _isCheckingPhone = false;
        });
      }
    });
  }

  Future<void> _pickAvatar() async {
    final result = await _avatarPicker.pickAndPersist(
      source: AvatarPickSource.gallery,
      userKey: 'new_user',
    );
    if (result is AvatarPickSuccess) {
      setState(() {
        _avatarPath = result.path;
      });
    } else if (result is AvatarPickFailure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.details ?? 'Failed to pick image'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_usernameTaken || _isCheckingUsername) return;
    if (widget.provider != 'phone' && (_phoneTaken || _isCheckingPhone)) return;

    setState(() => _loading = true);
    try {
      if (widget.provider == 'phone') {
        // Phone user was already registered in step 1. Update name, username, avatar.
        await SessionController.instance.updateProfile(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          phoneCode: _selectedCountry.code,
          avatarPath: _avatarPath,
          isInitialSetup: true,
        );
      } else {
        // OAuth user (Google, Apple, Facebook)
        await SessionController.instance.registerWithProvider(
          token: widget.token,
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          phoneCode: _selectedCountry.code,
          avatarPath: _avatarPath,
          provider: widget.provider,
        );
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushAndRemoveUntil(fadeRoute(const MainShell()), (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isSorani = LocaleController.instance.isSorani;

    return Scaffold(
      body: GlowBackdrop(
        intensity: 0.8,
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      AppStrings.completeProfileTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      isSorani
                          ? 'پێویستە ناو و ناوی بەکارهێنەر بنووسیت بۆ تەواوکردنی هەژمارەکەت.'
                          : 'Pêwîst e nav û navê bikarhêner binivîsî.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Avatar Picker
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.purpleLight.withValues(
                                alpha: 0.2,
                              ),
                              backgroundImage: _avatarPath != null
                                  ? (_avatarPath!.startsWith('http')
                                        ? NetworkImage(_avatarPath!)
                                              as ImageProvider
                                        : FileImage(File(_avatarPath!)))
                                  : null,
                              child: _avatarPath == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.purpleLight,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.purpleLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: BaravTextField(
                      label: AppStrings.fullName,
                      hint: AppStrings.fullNameHint,
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      validator: Validators.fullName,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 190),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BaravTextField(
                          label: AppStrings.username,
                          hint: AppStrings.usernameHint,
                          icon: Icons.alternate_email_rounded,
                          controller: _usernameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          onChanged: _onUsernameChanged,
                          maxLength: 20,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9çÇêÊîÎşŞûÛğĞöÖüÜ\u0621-\u064A\u0671-\u06D3\u067E\u0686\u0698\u06A4\u06A9\u06AF\u0660-\u0669\u06F0-\u06F9 ]')
                            ),
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              final text = newValue.text;
                              final lowerText = text.toLowerCase();

                              // Count spaces
                              final spaceCount = ' '.allMatches(lowerText).length;
                              if (spaceCount > 1) {
                                return oldValue;
                              }

                              // Prevent consecutive spaces
                              if (lowerText.contains('  ')) {
                                return oldValue;
                              }

                              // Enforce max length of 20 characters
                              if (lowerText.length > 20) {
                                return oldValue;
                              }

                              return newValue.copyWith(text: lowerText);
                            }),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return AppStrings.requiredField;
                            }
                            if (_usernameTaken) {
                              return isSorani ? '❌ ئەم ناوە پێشتر گیراوە' : '❌ Ev nav hatye girtin';
                            }
                            return Validators.username(v);
                          },
                          ltr: true,
                          suffixIcon: _isCheckingUsername
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        if (_isCheckingUsername)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isSorani ? 'چێک دەکرێت... 🔍' : 'Tê kontrolkirin... 🔍',
                                  style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
                                ),
                              ],
                            ),
                          )
                        else if (_usernameController.text.trim().isNotEmpty) ...[
                          if (Validators.username(_usernameController.text.trim()) != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                              child: Text(
                                '❌ ${Validators.username(_usernameController.text.trim())!}',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            )
                          else if (_usernameTaken)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                              child: Text(
                                isSorani ? '❌ ئەم ناوە پێشتر گیراوە' : '❌ Ev nav hatye girtin',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                              child: Text(
                                isSorani ? '✅ ئەم ناوە بەردەستە' : '✅ Ev nav berdest e',
                                style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.provider != 'phone') ...[
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 230),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8.0,
                              left: 4,
                              right: 4,
                            ),
                            child: Text(
                              isSorani ? 'ژمارەی مۆبایل' : 'Jimareya telefonê',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.textFaint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: colors.surface,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(28),
                                          ),
                                        ),
                                        builder: (ctx) => SizedBox(
                                          height:
                                              MediaQuery.of(context).size.height * 0.6,
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 10),
                                              Container(
                                                width: 40,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: colors.stroke,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(20),
                                                child: Text(
                                                  isSorani
                                                      ? 'وڵات هەڵبژێرە'
                                                      : 'Welat hilbijêre',
                                                  style: Theme.of(ctx)
                                                      .textTheme
                                                      .titleLarge,
                                                ),
                                              ),
                                              Expanded(
                                                child: ListView.builder(
                                                  itemCount: _countries.length,
                                                  itemBuilder: (_, i) {
                                                    final c = _countries[i];
                                                    final selected = c.code ==
                                                        _selectedCountry.code;
                                                    return Material(
                                                      color: Colors.transparent,
                                                      child: ListTile(
                                                        leading: Text(
                                                          c.flag,
                                                          style: const TextStyle(
                                                            fontSize: 26,
                                                          ),
                                                        ),
                                                        title: Text(
                                                          isSorani
                                                              ? c.nameKu
                                                              : c.name,
                                                        ),
                                                        trailing: Text(
                                                          c.code,
                                                          style: TextStyle(
                                                            color: colors.textMuted,
                                                            fontFamily: 'monospace',
                                                          ),
                                                        ),
                                                        selected: selected,
                                                        selectedColor:
                                                            AppColors.purpleLight,
                                                        onTap: () {
                                                          setState(
                                                            () => _selectedCountry = c,
                                                          );
                                                          Navigator.of(ctx).pop();
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: colors.stroke),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _selectedCountry.flag,
                                            style: const TextStyle(fontSize: 22),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _selectedCountry.code,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
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
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.number,
                                      textDirection: TextDirection.ltr,
                                      textAlign: TextAlign.left,
                                      textInputAction: TextInputAction.done,
                                      onChanged: _onPhoneChanged,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return AppStrings.requiredField;
                                        if (_phoneTaken) return isSorani ? '❌ ئەم ژمارەیە پێشتر گیراوە' : '❌ Ev hejmar hatye girtin';
                                        if (v.length < 9) return isSorani ? '❌ ژمارەکە زۆر کورتە' : '❌ Hejmar kurt e';
                                        return null;
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontFamily: 'monospace',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '750 000 0000',
                                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                          color: colors.textFaint,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.phone_outlined,
                                        ),
                                        suffixIcon: _isCheckingPhone
                                            ? const Padding(
                                                padding: EdgeInsets.all(12.0),
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              )
                                            : null,
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 17,
                                          horizontal: 16,
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: colors.surface,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(18),
                                          borderSide: BorderSide(color: colors.stroke),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(18),
                                          borderSide: BorderSide(color: colors.stroke),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(18),
                                          borderSide: BorderSide(color: AppColors.purple),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isCheckingPhone)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 1.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isSorani ? 'چێک دەکرێت... 🔍' : 'Tê kontrolkirin... 🔍',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
                                  ),
                                ],
                              ),
                            )
                          else if (_phoneController.text.trim().isNotEmpty) ...[
                            if (_phoneController.text.trim().length < 9)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                                child: Text(
                                  isSorani ? '❌ ژمارەکە زۆر کورتە' : '❌ Hejmar kurt e',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              )
                            else if (_phoneTaken)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                                child: Text(
                                  isSorani ? '❌ ئەم ژمارەیە پێشتر گیراوە' : '❌ Ev hejmar hatye girtin',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                                child: Text(
                                  isSorani ? '✅ ئەم ژمارەیە بەردەستە' : '✅ Ev hejmar berdest e',
                                  style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ] else
                    const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: BaravButton(
                        label: AppStrings.completeProfile,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
