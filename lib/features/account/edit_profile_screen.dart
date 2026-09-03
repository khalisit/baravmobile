import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../core/animation/fade_slide_in.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/barav_button.dart';
import '../../core/widgets/barav_text_field.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../core/session/session_controller.dart';
import '../../core/services/avatar_picker_service.dart';
import '../../data/api_service.dart';

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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;

  bool _passwordVisible = false;

  String? _avatarPath;
  bool _loading = false;
  bool isDummyEmail = false;  // true بۆ بەکارهێنەرانی Phone

  bool _usernameTaken = false;
  bool _emailTaken = false;
  bool _phoneTaken = false;

  bool _isCheckingUsername = false;
  bool _isCheckingEmail = false;
  bool _isCheckingPhone = false;

  Timer? _debounce;
  final _avatarPicker = AvatarPickerService();
  _Country _selectedCountry = _countries.first;
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    final user = SessionController.instance.user;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    // ئیمێڵی فەیک بۆ بەکارهێنەرانی Phone — بوش بهێڵەوە
    final email = user?.email ?? '';
    isDummyEmail = email.endsWith('@barav.app') || email.startsWith('phone_');
    _emailController = TextEditingController(text: isDummyEmail ? '' : email);
    _passwordController = TextEditingController();
    _avatarPath = user?.avatarPath;

    // Detect country code: prefer stored phoneCode field, then prefix-match from phone
    final phone = user?.phone ?? '';
    final storedCode = user?.phoneCode;
    _Country? detectedCountry;

    if (storedCode != null && storedCode.isNotEmpty) {
      try {
        detectedCountry = _countries.firstWhere((c) => c.code == storedCode);
      } catch (_) {}
    }
    if (detectedCountry == null) {
      for (final c in _countries) {
        if (phone.startsWith(c.code)) {
          detectedCountry = c;
          break;
        }
      }
    }
    if (detectedCountry != null) {
      _selectedCountry = detectedCountry;
      final localNumber = phone.startsWith(detectedCountry.code)
          ? phone.substring(detectedCountry.code.length)
          : phone;
      _phoneController = TextEditingController(text: localNumber);
    } else {
      _selectedCountry = _countries.first;
      _phoneController = TextEditingController(text: phone);
    }

    _realtimeTimer = Timer.periodic(const Duration(seconds: 22), (_) {
      SessionController.instance.refreshSession();
    });
  }




  void _onFieldChanged(
    String value,
    String field,
    VoidCallback setCheckingState,
    VoidCallback setTakenState,
    bool isTaken,
  ) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final user = SessionController.instance.user;
    // Don't check if the value is the same as current
    if (field == 'username' && value == user?.username) {
      setState(() => _usernameTaken = false);
      return;
    }
    if (field == 'email' && value == user?.email) {
      setState(() => _emailTaken = false);
      return;
    }
    if (field == 'phone' && value == user?.phone) {
      setState(() => _phoneTaken = false);
      return;
    }

    if (value.isEmpty) return;

    setCheckingState();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final isAvailable = await ApiService.checkAvailability(
        field: field,
        value: value,
        excludeId: user?.id,
      );

      if (mounted) {
        setState(() {
          if (field == 'username') {
            _usernameTaken = !isAvailable;
            _isCheckingUsername = false;
          } else if (field == 'email') {
            _emailTaken = !isAvailable;
            _isCheckingEmail = false;
          } else if (field == 'phone') {
            _phoneTaken = !isAvailable;
            _isCheckingPhone = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    _debounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final user = SessionController.instance.user;
    if (user == null) return;

    final result = await _avatarPicker.pickAndPersist(
      source: AvatarPickSource.gallery,
      userKey: user.email,
    );

    if (!mounted) return;

    if (result is AvatarPickSuccess) {
      setState(() => _avatarPath = result.path);
    }
  }

  // هەموو جۆری provider بتوانێت ژمارەکەی بگۆڕێت
  bool get canEditPhone => true;

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
                  LocaleController.instance.isSorani ? 'کۆدی وڵات دیاری بکە' : 'Koda welat hilbijêre',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Divider(height: 1, color: colors.stroke),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final c = _countries[index];
                    final isKu = LocaleController.instance.isSorani;
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Text(
                          c.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          isKu ? c.nameKu : c.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        trailing: Text(
                          c.code,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.textMuted,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCountry = c;
                          });
                          Navigator.pop(context);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameTaken || _emailTaken) return;

    setState(() => _loading = true);

    try {
      final user = SessionController.instance.user;
      final newName = _nameController.text.trim();
      final newUsername = _usernameController.text.trim().toLowerCase();
      final newEmail = _emailController.text.trim().toLowerCase();
      
      String local = _phoneController.text.trim();
      if (local.startsWith('0')) local = local.substring(1);
      final newPhone = local;

      final newPassword = _passwordController.text.trim();

      await SessionController.instance.updateProfile(
        fullName: newName != user?.fullName ? newName : null,
        username: newUsername != user?.username ? newUsername : null,
        email: newEmail != user?.email ? newEmail : null,
        phone: newPhone != user?.phone ? newPhone : null,
        phoneCode: _selectedCountry.code != user?.phoneCode ? _selectedCountry.code : null,
        password: newPassword.isNotEmpty ? newPassword : null,
        avatarPath: _avatarPath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.profileUpdated),
          backgroundColor: AppColors.purple,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
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



    return ListenableBuilder(
      listenable: SessionController.instance,
      builder: (context, _) {
        final user = SessionController.instance.user;
        final now = DateTime.now();
        final bool isPhoneVerified = user?.verifyPhone ?? false;

        // Calculate username cooldown active and days left
        bool usernameCooldownActive = false;
        int usernameCooldownDaysLeft = 0;
        final lastUsernameChangedAt = user?.lastUsernameChangedAt;
        if (lastUsernameChangedAt != null) {
          final date = lastUsernameChangedAt;
          if (date.isAfter(now)) {
            final remaining = date.difference(now);
            final days = (remaining.inHours / 24).ceil();
            if (days > 0) {
              usernameCooldownActive = true;
              usernameCooldownDaysLeft = days;
            }
          }
        }

        // Calculate name cooldown active and days left
        bool nameCooldownActive = false;
        int nameCooldownDaysLeft = 0;
        final lastNameChangedAt = user?.lastNameChangedAt;
        if (lastNameChangedAt != null) {
          final date = lastNameChangedAt;
          if (date.isAfter(now)) {
            final remaining = date.difference(now);
            final days = (remaining.inHours / 24).ceil();
            if (days > 0) {
              nameCooldownActive = true;
              nameCooldownDaysLeft = days;
            }
          }
        }

        final displayAvatarPath = _avatarPath ?? user?.avatarPath;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.editProfile),
            centerTitle: true,
            backgroundColor: Colors.transparent,
          ),
          extendBodyBehindAppBar: true,
          body: GlowBackdrop(
            intensity: 0.4,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar Picker
                      FadeSlideIn(
                        child: Center(
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.purple.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 2,
                                    ),
                                    image:
                                        displayAvatarPath != null &&
                                                displayAvatarPath.isNotEmpty
                                            ? DecorationImage(
                                                image: displayAvatarPath.startsWith('http')
                                                    ? NetworkImage(displayAvatarPath) as ImageProvider
                                                    : FileImage(File(displayAvatarPath)),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: displayAvatarPath == null || displayAvatarPath.isEmpty
                                      ? const Icon(
                                          Icons.person_rounded,
                                          size: 50,
                                          color: AppColors.purpleLight,
                                        )
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.cta,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BaravTextField(
                              label: AppStrings.fullName,
                              controller: _nameController,
                              icon: Icons.badge_outlined,
                              enabled: !nameCooldownActive,
                              validator: Validators.fullName,
                              suffixIcon: nameCooldownActive
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 14),
                                      child: Icon(
                                        Icons.lock_outline_rounded,
                                        size: 19,
                                        color: AppColors.warning,
                                      ),
                                    )
                                  : null,
                            ),
                            if (nameCooldownActive)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(start: 8, top: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: AppColors.warning.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppStrings.canChangeAfterDays.replaceAll(
                                        '%s',
                                        nameCooldownDaysLeft.toString(),
                                      ),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsetsDirectional.only(start: 8, top: 6),
                                child: Text(
                                  AppStrings.cannotChangeUntil30Days,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BaravTextField(
                              label: AppStrings.username,
                              controller: _usernameController,
                              icon: Icons.alternate_email,
                              enabled: !usernameCooldownActive,
                              onChanged: (val) => _onFieldChanged(
                                val,
                                'username',
                                () => setState(() => _isCheckingUsername = true),
                                () {},
                                _usernameTaken,
                              ),
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
                              validator: (val) {
                                if (_usernameTaken) {
                                  return LocaleController.instance.isSorani ? '❌ ئەم ناوە پێشتر گیراوە' : '❌ Ev nav hatye girtin';
                                }
                                return Validators.username(val);
                              },
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
                                  : (usernameCooldownActive
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 14),
                                          child: Icon(
                                            Icons.lock_outline_rounded,
                                            size: 19,
                                            color: AppColors.warning,
                                          ),
                                        )
                                      : null),
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
                                      LocaleController.instance.isSorani ? 'چێک دەکرێت... 🔍' : 'Tê kontrolkirin... 🔍',
                                      style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
                                    ),
                                  ],
                                ),
                              )
                            else if (!usernameCooldownActive && _usernameController.text.trim().isNotEmpty && _usernameController.text.trim() != SessionController.instance.user?.username) ...[
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
                                    LocaleController.instance.isSorani ? '❌ ئەم ناوە پێشتر گیراوە' : '❌ Ev nav hatye girtin',
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                                  child: Text(
                                    LocaleController.instance.isSorani ? '✅ ئەم ناوە بەردەستە' : '✅ Ev nav berdest e',
                                    style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ] else if (usernameCooldownActive)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(start: 8, top: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: AppColors.warning.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppStrings.canChangeAfterDays.replaceAll(
                                        '%s',
                                        usernameCooldownDaysLeft.toString(),
                                      ),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsetsDirectional.only(start: 8, top: 6),
                                child: Text(
                                  '${AppStrings.cannotChangeUntil30Days} • ${AppStrings.usernameRule}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (canEditPhone) ...[
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 6,
                            bottom: 8,
                          ),
                          child: Text(
                            AppStrings.phone,
                            style: theme.textTheme.labelMedium!
                                .copyWith(color: colors.textMuted),
                          ),
                        ),
                        if (isPhoneVerified)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: AppColors.success.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  LocaleController.instance.isSorani ? 'ئەم ژمارەیە سەلمێندراوە و ناتوانیت بیگۆڕیت' : 'Ev hejmar hatiye pejirandin',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 250),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Country button
                                GestureDetector(
                                  onTap: isPhoneVerified ? null : _pickCountry,
                                  child: Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: colors.stroke,
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
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
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
                                // Phone number field
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    enabled: !isPhoneVerified,
                                    keyboardType: TextInputType.phone,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.left,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (v) {
                                      if (isPhoneVerified) return;
                                      String local = v.trim();
                                      if (local.startsWith('0')) local = local.substring(1);
                                      _onFieldChanged(
                                        local,
                                        'phone',
                                        () => setState(() => _isCheckingPhone = true),
                                        () => setState(() => _phoneTaken = true),
                                        _phoneTaken,
                                      );
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return AppStrings.requiredField;
                                      if (_phoneTaken) return LocaleController.instance.isSorani ? '❌ ئەم ژمارەیە پێشتر گیراوە' : '❌ Ev hejmar hatye girtin';
                                      if (v.length < 9) return LocaleController.instance.isSorani ? '❌ ژمارەکە زۆر کورتە' : '❌ Hejmar kurt e';
                                      return Validators.phone(v);
                                    },
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
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 17,
                                        horizontal: 16,
                                      ),
                                      isDense: true,
                                      filled: true,
                                      fillColor: colors.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: colors.stroke,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: colors.stroke,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: const BorderSide(
                                          color: AppColors.purple,
                                          width: 1.5,
                                        ),
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isPhoneVerified) ...[
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
                                    LocaleController.instance.isSorani ? 'چێک دەکرێت... 🔍' : 'Tê kontrolkirin... 🔍',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
                                  ),
                                ],
                              ),
                            )
                          else if (_phoneController.text.trim().isNotEmpty && _phoneController.text.trim() != user?.phone) ...[
                            if (_phoneController.text.trim().length < 9)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                                child: Text(
                                  LocaleController.instance.isSorani ? '❌ ژمارەکە زۆر کورتە' : '❌ Hejmar kurt e',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              )
                            else if (_phoneTaken)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                                child: Text(
                                  LocaleController.instance.isSorani ? '❌ ئەم ژمارەیە پێشتر گیراوە' : '❌ Ev hejmar hatye girtin',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                                child: Text(
                                  LocaleController.instance.isSorani ? '✅ ئەم ژمارەیە بەردەستە' : '✅ Ev hejmar berdest e',
                                  style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ],
                      ],

                      if (user?.provider == 'phone') ...[
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 270),
                          child: BaravTextField(
                            label: LocaleController.instance.isSorani
                                ? 'تێپەڕی ووشەی نوێ (ئارەزوومەندانە)'
                                : 'Şîfreya Nû (Bijartî)',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscure: !_passwordVisible,
                            ltr: true,
                            validator: (v) {
                              if (v != null && v.isNotEmpty && v.length < 6) {
                                  return LocaleController.instance.isSorani
                                      ? 'تێپەڕی ووشە کەمترین ٦ پیت دەبێت'
                                      : 'Şîfre divê herî kêm 6 tîp be';
                              }
                              return null;
                            },
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
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: BaravButton(
                          label: _loading ? AppStrings.updating : AppStrings.update,
                          onPressed:
                              _loading ||
                                      _isCheckingUsername ||
                                      _isCheckingEmail
                                  ? null
                                  : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
