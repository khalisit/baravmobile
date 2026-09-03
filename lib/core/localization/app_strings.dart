import 'locale_controller.dart';

/// دەقەکانی UI — لە JSON دەخوێنرێنەوە بەپێی شێوەزاری هەڵبژێردراو.
abstract final class AppStrings {
  static String _t(
    String key, {
    String? fallbackCkb,
    String? fallbackBadini,
  }) {
    final translated = LocaleController.instance.t(key);
    if (translated != key) return translated;
    final isBadini = LocaleController.instance.isBadini;
    if (isBadini && fallbackBadini != null) return fallbackBadini;
    if (fallbackCkb != null) return fallbackCkb;
    return key;
  }

  static String get appName => _t('app_name');
  static String get appTagline => _t('app_tagline');

  static String get loginTitle => _t('login_title');
  static String get loginSubtitle => _t('login_subtitle');
  static String get loginIdentifier => _t('login_identifier', fallbackCkb: 'یوزەرنەیم، ئیمەیڵ، یان مۆبایل', fallbackBadini: 'یوزەرنەیم، ئیمەیڵ، یان مۆبایل');
  static String get email => _t('email');
  static String get emailHint => _t('email_hint');
  static String get password => _t('password');
  static String get passwordHint => _t('password_hint');
  static String get forgotPassword => _t('forgot_password');
  static String get login => _t('login');
  static String get continueWithAccount => _t('continue_with_account');
  static String get orContinueWith => _t('or_continue_with');
  static String get continueWithGoogle => _t('continue_with_google');
  static String get continueWithApple => _t('continue_with_apple');
  static String get continueWithFacebook => _t('continue_with_facebook');
  static String get noAccount => _t('no_account');
  static String get createAccount => _t('create_account');

  static String get registerTitle => _t('register_title');
  static String get registerSubtitle => _t('register_subtitle');
  static String get fullName => _t('full_name');
  static String get fullNameHint => _t('full_name_hint');
  static String get username => _t('username', fallbackCkb: 'ناوی بەکارهێنەر', fallbackBadini: 'ناڤێ بکارئینەر');
  static String get usernameHint => _t('username_hint', fallbackCkb: 'barav_user', fallbackBadini: 'barav_user');
  static String get phone => _t('phone');
  static String get phoneHint => _t('phone_hint');
  static String get register => _t('register');
  static String get haveAccount => _t('have_account');
  static String get confirmPassword => _t('confirm_password', fallbackCkb: 'دڵنیابوونەوە لە تێپەڕی ووشە', fallbackBadini: 'پشتڕاستکرنا پەیڤا نهێنی');
  static String get confirmPasswordHint => _t('confirm_password_hint', fallbackCkb: '***', fallbackBadini: '***');
  
  static String get completeProfileTitle => _t('complete_profile_title', fallbackCkb: 'تەواوکردنی زانیارییەکان', fallbackBadini: 'تەمامکرنا پێزانینان');
  static String get completeProfileSubtitle => _t('complete_profile_subtitle', fallbackCkb: 'تکایە زانیارییەکانت تەواو بکە بۆ بەردەوامبوون', fallbackBadini: 'هیڤی دارین پێزانینێن خۆ تەمام بکە بۆ بەردەوامبوونێ');
  static String get completeProfile => _t('complete_profile', fallbackCkb: 'تەواوکردن', fallbackBadini: 'تەمامکرن');
  static String get pickAvatar => _t('pick_avatar', fallbackCkb: 'وێنەیەک هەڵبژێرە', fallbackBadini: 'وێنەکێ هەلبژێرە');

  static String get forgotTitle => _t('forgot_title');
  static String get forgotSubtitle => _t('forgot_subtitle');
  static String get sendLink => _t('send_link');
  static String get backToLogin => _t('back_to_login');
  static String get linkSent => _t('link_sent');

  static String get tabHome => _t('tab_home');
  static String get tabAccount => _t('tab_account');
  static String get tabAdmin => _t('tab_admin');

  static String get greeting => _t('greeting');
  static String get sponsored => _t('sponsored');
  static String get video => _t('video');
  static String get nextQuiz => _t('next_quiz');
  static String get liveNow => _t('live_now');
  static String get days => _t('days');
  static String get hours => _t('hours');
  static String get minutes => _t('minutes');
  static String get seconds => _t('seconds');
  static String get questionsSection => _t('questions_section');
  static String get questionLabel => _t('question_label');
  static String get answerLabel => _t('answer_label');
  static String get showAnswer => _t('show_answer');
  static String get hideAnswer => _t('hide_answer');

  static String get accountTitle => _t('account_title');
  static String get personalInfo => _t('personal_info');
  static String get accountPreferences => _t(
        'account_preferences',
        fallbackCkb: 'ڕێکخستنەکان',
        fallbackBadini: 'Mîheng',
      );
  static String get accountActions => _t(
        'account_actions',
        fallbackCkb: 'هەژمار',
        fallbackBadini: 'Hesab',
      );
  static String get levelTitle => _t('level_title');
  static String get levelLabel => _t(
        'level_label',
        fallbackCkb: 'لیفڵ',
        fallbackBadini: 'Level',
      );
  static String get levelUpTitle => _t(
        'level_up_title',
        fallbackCkb: 'لیفڵ بەرزبووەوە!',
        fallbackBadini: 'Level bilind bû!',
      );
  static String get levelUpBody => _t(
        'level_up_body',
        fallbackCkb: 'پیرۆزە! گەیشیتە ئاستێکی نوێ.',
        fallbackBadini: 'Pîroz be! Tu gihîştî asta nû.',
      );
  static String get levelUpContinue => _t(
        'level_up_continue',
        fallbackCkb: 'باشە',
        fallbackBadini: 'Baş e',
      );
  static String get totalPoints => _t('total_points');
  static String get nextLevel => _t('next_level');
  static String get pointsToNextLevel => _t('points_to_next_level');
  static String get correctAnswerReward => _t('correct_answer_reward');
  static String get appearance => _t('appearance');
  static String get darkMode => _t('dark_mode');
  static String get lightMode => _t('light_mode');
  static String get dialect => _t('dialect');
  static String get dialectSorani => _t('dialect_sorani');
  static String get dialectBadini => _t('dialect_badini');
  static String get logout => _t('logout');
  static String get deleteAccount => _t('delete_account');
  static String get deleteAccountTitle => _t('delete_account_title');
  static String get deleteAccountBody => _t('delete_account_body');
  static String get cancel => _t('cancel');
  static String get confirmDelete => _t('confirm_delete');
  
  static String get editProfile => _t('edit_profile', fallbackCkb: 'دەستکاری پرۆفایل', fallbackBadini: 'Destkariya profîlê');
  static String get claimHistory => _t(
        'claim_history',
        fallbackCkb: 'مێژووی وەرگرتنی خەڵاتەکان',
        fallbackBadini: 'مێژوویا وەرگرتنا خەلاتان',
      );
  static String get noClaimsYet => _t(
        'no_claims_yet',
        fallbackCkb: 'هیچ وەرگرتنێکی خەڵات تۆمار نەکراوە',
        fallbackBadini: 'چ وەرگرتنێن خەلاتان نەهاتینە تۆمارکرن',
      );
  static String get update => _t('update', fallbackCkb: 'نوێکردنەوە', fallbackBadini: 'Nûvekirin');
  static String get updating => _t('updating', fallbackCkb: 'نوێ دەکرێتەوە...', fallbackBadini: 'Tê nûvekirin...');
  static String get usernameTaken => _t('username_taken', fallbackCkb: 'ئەم ناوە گیراوە', fallbackBadini: 'Ev nav hatiye girtin');
  static String get emailTaken => _t('email_taken', fallbackCkb: 'ئەم ئیمەیڵە گیراوە', fallbackBadini: 'Ev e-name hatiye girtin');
  static String get phoneTaken => _t('phone_taken', fallbackCkb: 'ئەم ژمارەیە گیراوە', fallbackBadini: 'Ev hejmar hatiye girtin');
  static String get profileCooldownMessage => _t('profile_cooldown_message', 
    fallbackCkb: 'دەتوانیت دوای %s ڕۆژی تر زانیارییەکانت بگۆڕیتەوە.', 
    fallbackBadini: 'Tu dikarî piştî %s rojên din zanyariyên xwe biguherî.');
  static String get usernameCooldownMessage => _t('username_cooldown_message', 
    fallbackCkb: 'دەتوانیت دوای %s ڕۆژی تر ناوی بەکارهێنەر بگۆڕیتەوە.', 
    fallbackBadini: 'Tu dikarî piştî %s rojên din navê bikarhêner biguherî.');
  static String get fullNameCooldownMessage => _t('full_name_cooldown_message', 
    fallbackCkb: 'دەتوانیت دوای %s ڕۆژی تر ناوی سیانی بگۆڕیتەوە.', 
    fallbackBadini: 'Tu dikarî piştî %s rojên din navê sêyanî biguherî.');
  static String get fullNameChangeRule => _t('full_name_change_rule', 
    fallbackCkb: 'ناوی سیانی تەنها ٣٠ ڕۆژ جارێک دەگۆڕدرێت.', 
    fallbackBadini: 'Navê sêyanî tenê 30 rojan carekê tê guherîn.');
  static String get usernameChangeRule => _t('username_change_rule', 
    fallbackCkb: 'ناوی بەکارهێنەر تەنها ٣٠ ڕۆژ جارێک دەگۆڕدرێت.', 
    fallbackBadini: 'Navê bikarhêner tenê 30 rojan carekê tê guherîn.');
  static String get canChangeAfterDays => _t('can_change_after_days', 
    fallbackCkb: 'دوای %s ڕۆژی تر دەتوانیت بیگۆڕیت', 
    fallbackBadini: 'Piştî %s rojên din tu dikarî biguherî');
  static String get cannotChangeUntil30Days => _t('cannot_change_until_30_days', 
    fallbackCkb: 'تا ٣٠ ڕۆژی تر ناتوانیت بیگۆڕیت', 
    fallbackBadini: 'Heta 30 rojên din tu nikarî biguherî');
  static String get profileUpdated => _t('profile_updated', fallbackCkb: 'پرۆفایلەکەت نوێکرایەوە', fallbackBadini: 'Profîla te hate nûvekirin');
  static String get usernameRule => _t('username_rule', fallbackCkb: 'تەنها پیت، ژمارە و ژێر هێڵ (_)', fallbackBadini: 'Tenê tîp, hejmar û xêz (_)');
  static String get invalidUsername => _t('invalid_username', fallbackCkb: 'ناوی بەکارهێنەر هەڵەیە', fallbackBadini: 'Navê bikarhêner xelet e');

  static String get extraLifeTitle => _t(
        'extra_life_title',
        fallbackCkb: 'هەلی زیاتر',
        fallbackBadini: 'Derfetê Zêdetir',
      );
  static String get extraLifeHint => _t(
        'extra_life_hint',
        fallbackCkb: '٣ ڕێکلام سەیر بکە بۆ هەلی زیاتری تێپەڕاندن',
        fallbackBadini: '3 reklam temaşe bike bo derfeta zêdetir a derbasbûnê',
      );
  static String get extraLifeAdsProgress => _t(
        'extra_life_ads_progress',
        fallbackCkb: 'پێشکەوتنی ڕیکلام',
        fallbackBadini: 'Pêşketina reklamê',
      );
  static String get watchAdButton => _t(
        'watch_ad_button',
        fallbackCkb: 'بینینی ڕیکلام',
        fallbackBadini: 'Reklamê temaşe bike',
      );
  static String get watchAdTitle => _t(
        'watch_ad_title',
        fallbackCkb: 'ڕیکلامی ڤیدیۆ',
        fallbackBadini: 'Reklama vîdyoyê',
      );
  static String get watchAdHint => _t(
        'watch_ad_hint',
        fallbackCkb: 'چاوەڕێ بکە تا ڕیکلامەکە تەواو دەبێت',
        fallbackBadini: 'Li benda qedandina reklamê be',
      );
  static String get watchAdDone => _t(
        'watch_ad_done',
        fallbackCkb: 'ڕیکلامەکە تەواو بوو',
        fallbackBadini: 'Reklam qediya',
      );
  static String get watchAdClaim => _t(
        'watch_ad_claim',
        fallbackCkb: 'وەرگرتنی خەڵات',
        fallbackBadini: 'Xelatê bistîne',
      );
  static String get extraLifeEarned => _t(
        'extra_life_earned',
        fallbackCkb: '١ Extra Life وەرگیرا!',
        fallbackBadini: '1 Extra Life hat standin!',
      );
  static String get extraLifeAdProgress => _t(
        'extra_life_ad_progress',
        fallbackCkb: 'ڕیکلام تۆمارکرا — بەردەوامبە',
        fallbackBadini: 'Reklam hate tomar kirin — berdewam bike',
      );
  static String get extraLifeOfferTitle => _t(
        'extra_life_offer_title',
        fallbackCkb: 'Extra Life بەکاربهێنە؟',
        fallbackBadini: 'Extra Life bi kar bîne?',
      );
  static String get extraLifeOfferBody => _t(
        'extra_life_offer_body',
        fallbackCkb: 'ئەم پرسیارە تێپەڕێنە و لە یاری بمێنەرەوە',
        fallbackBadini: 'Vê pirsê derbas bike û di lîstikê de bimîne',
      );
  static String get useExtraLife => _t(
        'use_extra_life',
        fallbackCkb: 'بەکارهێنانی Extra Life',
        fallbackBadini: 'Extra Life bi kar bîne',
      );
  static String get skipQuestion => _t(
        'skip_question',
        fallbackCkb: 'تێپەڕاندن',
        fallbackBadini: 'Derbasbûn',
      );
  static String get skipExtraLife => _t(
        'skip_extra_life',
        fallbackCkb: 'نەخێر، وەک بینەر بمێنەوە',
        fallbackBadini: 'Na, wek temaşevan bimîne',
      );

  static String get compromisedDeviceTitle => _t(
        'compromised_device_title',
        fallbackCkb: 'ئامێرەکە پارێزراو نییە',
        fallbackBadini: 'Amûr ne parastî ye',
      );
  static String get compromisedDeviceBody => _t(
        'compromised_device_body',
        fallbackCkb:
            'موبایلی ڕووتکراو، جەیلبرێک، یان سیمولەیتەر مەترسیدارە بۆ کویز. بۆ بەشداریکردن ئامێرێکی ئاسایی بەکاربهێنە.',
        fallbackBadini:
            'Amûrên rootkirî, jailbreakkirî an emulator ji bo quîzê xeternak in. Ji kerema xwe amûrek asayî bi kar bîne.',
      );
  static String get compromisedDeviceExit => _t(
        'compromised_device_exit',
        fallbackCkb: 'دەرچوون لە ئەپ',
        fallbackBadini: 'Ji appê derkeve',
      );
  static String get compromisedDeviceBlocked => _t(
        'compromised_device_blocked',
        fallbackCkb: 'لەم ئامێرەدا ناتوانیت بەشداری کویز بکەیت',
        fallbackBadini: 'Li ser vê amûrê nikarî beşdarî quîzê bibî',
      );

  static String get requiredField => _t('required_field');
  static String get invalidEmail => _t('invalid_email');
  static String get shortPassword => _t('short_password');
  static String get invalidPhone => _t('invalid_phone');
  static String get shortName => _t('short_name');

  static String get quizLobbyTitle => _t('quiz_lobby_title');
  static String get quizLobbyHint => _t('quiz_lobby_hint');
  static String get playersJoined => _t('players_joined');
  static String get quizPreparing => _t('quiz_preparing');
  static String get backToHome => _t('back_to_home');
  static String get nextQuestionSoon => _t('next_question_soon');
  static String get eliminatedTitle => _t('eliminated_title');
  static String get eliminatedBody => _t('eliminated_body');
  static String get spectatorWatching => _t('spectator_watching');
  static String get continueWatching => _t(
        'continue_watching',
        fallbackCkb: 'بەردەوامبە وەک بینەر',
        fallbackBadini: 'Wek temaşevan berdewam bike',
      );
  static String get wrongAnswerTitle => _t(
        'wrong_answer_title',
        fallbackCkb: 'وەڵامەکە هەڵە بوو',
        fallbackBadini: 'Bersiv şaş bû',
      );
  static String get waitingForWinners => _t('waiting_for_winners');
  static String get stillAlive => _t('still_alive');
  static String get winnersTitle => _t('winners_title');
  static String get winnersSubtitle => _t('winners_subtitle');
  static String get youWon => _t('you_won');
  static String get youBadge => _t('you_badge');
  static String get joinLiveQuiz => _t('join_live_quiz');
  static String get readyForQuiz => _t('ready_for_quiz');
  static String get readyRegistered => _t('ready_registered');
  static String get lobbyStartsIn => _t('lobby_starts_in');
  static String get quizInProgress => _t(
        'quiz_in_progress',
        fallbackCkb: 'کویز دەستی پێکرد',
        fallbackBadini: 'Quîz dest pê kir',
      );

  static String get adminDashboard => _t('admin_dashboard');
  static String get adminDashboardHint => _t('admin_dashboard_hint');
  static String get createQuiz => _t('create_quiz');
  static String get startQuizNow => _t('start_quiz_now');
  static String get lastWinners => _t('last_winners');
  static String get hideQuiz => _t(
        'hide_quiz',
        fallbackCkb: 'شاردنەوەی کویز',
        fallbackBadini: 'Quîzê veşêre',
      );
  static String get quizHidden => _t(
        'quiz_hidden',
        fallbackCkb: 'کویزەکە شاردرایەوە',
        fallbackBadini: 'Quîz hate veşartin',
      );
  static String get quizStatusIdle => _t('quiz_status_idle');
  static String get quizStatusScheduled => _t('quiz_status_scheduled');
  static String get quizTitle => _t('quiz_title');
  static String get change => _t('change');
  static String get addQuestion => _t('add_question');
  static String get saveQuiz => _t('save_quiz');
  static String get saveAndStartNow => _t('save_and_start_now');
  static String get quizSaved => _t('quiz_saved');
  static String get optionLabel => _t('option_label');
  static String get correctAnswerHint => _t('correct_answer_hint');
  static String get quizSponsorSection => _t('quiz_sponsor_section');
  static String get quizSponsorHint => _t('quiz_sponsor_hint');
  static String get sponsorBrand => _t('sponsor_brand');
  static String get sponsorBrandHint => _t('sponsor_brand_hint');
  static String get sponsorMediaUrl => _t('sponsor_media_url');
  static String get sponsorMediaHint => _t('sponsor_media_hint');
  static String get sponsorTagline => _t('sponsor_tagline');
  static String get sponsorImage => _t('sponsor_image');
  static String get questionAsText => _t(
        'question_as_text',
        fallbackCkb: 'دەق',
        fallbackBadini: 'Nivîs',
      );
  static String get questionAsImage => _t(
        'question_as_image',
        fallbackCkb: 'وێنە (PNG)',
        fallbackBadini: 'Wêne (PNG)',
      );
  static String get questionImageUrl => _t(
        'question_image_url',
        fallbackCkb: 'لینکی وێنەی پرسیار',
        fallbackBadini: 'Lînka wêneya pirsê',
      );
  static String get questionImageHint => _t(
        'question_image_hint',
        fallbackCkb: 'https://… یان هەڵبژاردن لە گەلەری (PNG)',
        fallbackBadini: 'https://… an ji galeriyê hilbijêre (PNG)',
      );
  static String get questionImageCaption => _t(
        'question_image_caption',
        fallbackCkb: 'دەقی کورت (ئارەزوومەندانە)',
        fallbackBadini: 'Nivîsa kurt (bijare)',
      );
  static String get pickQuestionImage => _t(
        'pick_question_image',
        fallbackCkb: 'هەڵبژاردنی وێنەی PNG',
        fallbackBadini: 'Wêneya PNG hilbijêre',
      );
  static String get questionImageRequired => _t(
        'question_image_required',
        fallbackCkb: 'تکایە وێنەی پرسیار دابنێ',
        fallbackBadini: 'Ji kerema xwe wêneya pirsê bike',
      );

  static String get changeProfilePhoto => _t(
        'change_profile_photo',
        fallbackCkb: 'گۆڕینی وێنەی پرۆفایل',
        fallbackBadini: 'Wêneya profîlê biguhêre',
      );
  static String get chooseFromGallery => _t(
        'choose_from_gallery',
        fallbackCkb: 'هەڵبژاردن لە گەلەری',
        fallbackBadini: 'Ji galeriyê hilbijêre',
      );
  static String get takePhoto => _t(
        'take_photo',
        fallbackCkb: 'گرتنی وێنە',
        fallbackBadini: 'Wêneyê bigire',
      );
  static String get removeProfilePhoto => _t(
        'remove_profile_photo',
        fallbackCkb: 'سڕینەوەی وێنە',
        fallbackBadini: 'Wêneyê jê bibe',
      );
  static String get tapToChangePhoto => _t(
        'tap_to_change_photo',
        fallbackCkb: 'کرتە بکە بۆ گۆڕینی وێنە',
        fallbackBadini: 'Ji bo guhertina wêneyê bitikîne',
      );
  static String get profilePhotoPickFailed => _t(
        'profile_photo_pick_failed',
        fallbackCkb:
            'نەتوانرا وێنە هەڵبژێردرێت. تکایە ئەپەکە داخە و دووبارە بی کردنەوە، یان مۆڵەتی کامێرا/وێنەکان چالاک بکە.',
        fallbackBadini:
            'Wêne nehat hilbijartin. Ji kerema xwe appê bigire û dîsa vekî, an jî destûra kamerayê/wêneyan çalak bike.',
      );
  static String get profilePhotoPermissionDenied => _t(
        'profile_photo_permission_denied',
        fallbackCkb:
            'مۆڵەتی وێنە/کامێرا پێویستە. لە ڕێکخستنەکانی ئامێرەکەدا چالاکی بکە.',
        fallbackBadini:
            'Destûra wêne/kamerayê pêwîst e. Di mîhengên amûrê de çalak bike.',
      );

  static String get pushPermissionTitle => _t(
        'push_permission_title',
        fallbackCkb: 'ئاگادارییەکانی دەرەوەی ئەپ',
        fallbackBadini: 'Agahdarîyên derve yên appê',
      );
  static String get pushPermissionBody => _t(
        'push_permission_body',
        fallbackCkb:
            'کاتێک کویزێکی نوێ خشتە دەکرێت یان دەستپێدەکات، ئاگاداری لەسەر شاشەکەت وەردەگریت — تەنانەت کاتێک ئەپەکە داخراوە.',
        fallbackBadini:
            'Dema quîzek nû were plansazkirin an dest pê bike, agahdarî li ser ekranê distînî — tewra dema app girtî be.',
      );
  static String get pushPermissionEnable => _t(
        'push_permission_enable',
        fallbackCkb: 'چالاککردنی ئاگاداری',
        fallbackBadini: 'Agahdarîyan çalak bike',
      );
  static String get pushPermissionLater => _t(
        'push_permission_later',
        fallbackCkb: 'دواتر',
        fallbackBadini: 'Paşê',
      );
  static String get pushPermissionDenied => _t(
        'push_permission_denied',
        fallbackCkb: 'مۆڵەتی ئاگاداری ڕەتکرایەوە.',
        fallbackBadini: 'Destûra agahdarîyê hate redkirin.',
      );
  static String get pushPermissionOpenSettings => _t(
        'push_permission_open_settings',
        fallbackCkb:
            'لە ڕێکخستنەکانی ئامێرەکەدا مۆڵەتی ئاگاداری چالاک بکە.',
        fallbackBadini:
            'Di mîhengên amûrê de destûra agahdarîyê çalak bike.',
      );
  static String get pushNotificationsLabel => _t(
        'push_notifications_label',
        fallbackCkb: 'ئاگادارییەکانی دەرەوە',
        fallbackBadini: 'Agahdarîyên derve',
      );
  static String get pushNotificationsEnabled => _t(
        'push_notifications_enabled',
        fallbackCkb: 'چالاکە — کویز و هەواڵەکان دەگەیەنرێن',
        fallbackBadini: 'Çalak e — quîz û nûçe têne şandin',
      );
  static String get pushNotificationsDisabled => _t(
        'push_notifications_disabled',
        fallbackCkb: 'ناچالاکە — کرتە بکە بۆ چالاککردن',
        fallbackBadini: 'Neçalak e — bitikîne ji bo çalakkirinê',
      );
  static String get pushPermissionDisableHint => _t(
        'push_permission_disable_hint',
        fallbackCkb:
            'بۆ کوژاندنەوە، لە ڕێکخستنەکانی ئامێرەکەدا مۆڵەتی ئاگاداری بکوژێنەوە.',
        fallbackBadini:
            'Ji bo girtinê, di mîhengên amûrê de destûra agahdarîyê bigire.',
      );

  static String get notificationsTitle => _t(
        'notifications_title',
        fallbackCkb: 'ئاگادارییەکان',
        fallbackBadini: 'Agahdarî',
      );
  static String get notificationsEmpty => _t(
        'notifications_empty',
        fallbackCkb: 'هیچ ئاگادارییەک نییە',
        fallbackBadini: 'Agahdarî tune',
      );
  static String get notificationsEmptyHint => _t(
        'notifications_empty_hint',
        fallbackCkb: 'کاتێک کویز یان هەواڵێکی نوێ هەبێت لێرە دەردەکەوێت',
        fallbackBadini: 'Dema quîz an nûçeyek nû hebe li vir xuya dibe',
      );
  static String get markAllRead => _t(
        'mark_all_read',
        fallbackCkb: 'هەموویان بخوێنەوە',
        fallbackBadini: 'Hemûyan bixwîne',
      );
  static String get notificationJustNow => _t(
        'notification_just_now',
        fallbackCkb: 'ئێستا',
        fallbackBadini: 'Niha',
      );
  static String get notificationMinutesAgo => _t(
        'notification_minutes_ago',
        fallbackCkb: 'خ',
        fallbackBadini: 'd',
      );
  static String get notificationHoursAgo => _t(
        'notification_hours_ago',
        fallbackCkb: 'ک',
        fallbackBadini: 's',
      );

  static String get notificationTypeQuiz => _t(
        'notification_type_quiz',
        fallbackCkb: 'کویز',
        fallbackBadini: 'Quîz',
      );
  static String get notificationTypePromo => _t(
        'notification_type_promo',
        fallbackCkb: 'پڕۆمۆ',
        fallbackBadini: 'Promo',
      );
  static String get notificationTypeGeneral => _t(
        'notification_type_general',
        fallbackCkb: 'گشتی',
        fallbackBadini: 'Giştî',
      );
}
