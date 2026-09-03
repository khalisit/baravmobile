import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../utils/kurdish_format.dart';

/// Material بە کوردی (سۆرانی / بادینی) — بەروار، کات، کۆپی/پەیست.
class KurdishMaterialLocalizations extends DefaultMaterialLocalizations {
  const KurdishMaterialLocalizations(this.isBadini);

  final bool isBadini;

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _KurdishMaterialDelegate();

  @override
  String get copyButtonLabel => isBadini ? 'Kopî' : 'کۆپی';

  @override
  String get cutButtonLabel => isBadini ? 'Jêbike' : 'بڕین';

  @override
  String get pasteButtonLabel => isBadini ? 'Paste bike' : 'پەیست';

  @override
  String get selectAllButtonLabel => isBadini ? 'Hemû hilbijêre' : 'هەمووی هەڵبژێرە';

  @override
  String get lookUpButtonLabel => isBadini ? 'Lêgerîn' : 'گەڕان';

  @override
  String get searchWebButtonLabel => isBadini ? 'Li webê bigere' : 'گەڕان لە وێب';

  @override
  String get shareButtonLabel => isBadini ? 'Parve bike' : 'هاوبەشکردن';

  @override
  String get okButtonLabel => isBadini ? 'Baş e' : 'باشە';

  @override
  String get cancelButtonLabel => isBadini ? 'Betal bike' : 'پاشگەزبوونەوە';

  @override
  String get closeButtonLabel => isBadini ? 'Bigire' : 'داخستن';

  @override
  String get deleteButtonTooltip => isBadini ? 'Jê bibe' : 'سڕینەوە';

  @override
  String get nextMonthTooltip => isBadini ? 'Meha pêş' : 'مانگی داهاتوو';

  @override
  String get previousMonthTooltip => isBadini ? 'Meha berê' : 'مانگی پێشوو';

  @override
  String get nextPageTooltip => isBadini ? 'Rûpela pêş' : 'پەڕەی داهاتوو';

  @override
  String get previousPageTooltip => isBadini ? 'Rûpela berê' : 'پەڕەی پێشوو';

  @override
  String get saveButtonLabel => isBadini ? 'Tomar bike' : 'پاشەکەوتکردن';

  @override
  String get datePickerHelpText => isBadini ? 'Roje hilbijêre' : 'بەروار هەڵبژێرە';

  @override
  String get dateInputLabel => isBadini ? 'Roj' : 'بەروار';

  @override
  String get dateOutOfRangeLabel =>
      isBadini ? 'Derveyî sînor e' : 'دەرەوەی مەودایە';

  @override
  String get timePickerDialHelpText => isBadini ? 'Demê hilbijêre' : 'کات هەڵبژێرە';

  @override
  String get timePickerInputHelpText => isBadini ? 'Demê binivîse' : 'کات بنووسە';

  @override
  String get timePickerHourLabel => isBadini ? 'Saet' : 'کاتژمێر';

  @override
  String get timePickerMinuteLabel => isBadini ? 'Deqîqe' : 'خولەک';

  @override
  String get anteMeridiemAbbreviation => isBadini ? 'SB' : 'ب‌ن';

  @override
  String get postMeridiemAbbreviation => isBadini ? 'EV' : 'د‌ن';

  @override
  String get dialModeButtonLabel =>
      isBadini ? 'Moda dialê' : 'دۆخی بازنەیی';

  @override
  String get inputDateModeButtonLabel =>
      isBadini ? 'Moda nivîsînê' : 'دۆخی نووسین';

  @override
  String get inputTimeModeButtonLabel =>
      isBadini ? 'Moda nivîsînê' : 'دۆخی نووسین';

  @override
  String formatYear(DateTime date) => KurdishFormat.digits(date.year);

  @override
  String formatMonthYear(DateTime date) {
    final month = KurdishFormat.months[date.month - 1];
    return '$month ${KurdishFormat.digits(date.year)}';
  }

  @override
  String formatMediumDate(DateTime date) => KurdishFormat.shortDate(date);

  @override
  String formatFullDate(DateTime date) =>
      '${KurdishFormat.shortDate(date)} ${KurdishFormat.digits(date.year)}';

  @override
  String formatCompactDate(DateTime date) {
    final d = KurdishFormat.padded(date.day);
    final m = KurdishFormat.padded(date.month);
    final y = KurdishFormat.digits(date.year);
    return '$d/$m/$y';
  }

  @override
  String formatShortDate(DateTime date) => formatCompactDate(date);

  @override
  String formatShortMonthDay(DateTime date) {
    return '${KurdishFormat.digits(date.day)} ${KurdishFormat.months[date.month - 1]}';
  }

  @override
  String formatDecimal(int number) => KurdishFormat.digits(number);

  @override
  String formatHour(TimeOfDay timeOfDay, {bool alwaysUse24HourFormat = false}) {
    final hour = alwaysUse24HourFormat
        ? timeOfDay.hour
        : (timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod);
    return alwaysUse24HourFormat
        ? KurdishFormat.padded(hour)
        : KurdishFormat.digits(hour);
  }

  @override
  String formatMinute(TimeOfDay timeOfDay) =>
      KurdishFormat.padded(timeOfDay.minute);

  @override
  String formatTimeOfDay(
    TimeOfDay timeOfDay, {
    bool alwaysUse24HourFormat = false,
  }) {
    final hour = formatHour(
      timeOfDay,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );
    final minute = formatMinute(timeOfDay);
    if (alwaysUse24HourFormat) return '$hour:$minute';
    final period = timeOfDay.period == DayPeriod.am
        ? anteMeridiemAbbreviation
        : postMeridiemAbbreviation;
    return '$hour:$minute $period';
  }

  @override
  List<String> get narrowWeekdays {
    if (isBadini) {
      return const ['Y', 'D', 'S', 'Ç', 'P', 'Î', 'Ş'];
    }
    return const ['ی', 'د', 'س', 'چ', 'پ', 'ه', 'ش'];
  }

  @override
  int get firstDayOfWeekIndex => 1;
}

class _KurdishMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _KurdishMaterialDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ckb' || locale.languageCode == 'badini';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
      KurdishMaterialLocalizations(locale.languageCode == 'badini'),
    );
  }

  @override
  bool shouldReload(_KurdishMaterialDelegate old) => false;
}

class KurdishWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const KurdishWidgetsLocalizations(this.isBadini);

  final bool isBadini;

  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      _KurdishWidgetsDelegate();

  @override
  TextDirection get textDirection =>
      isBadini ? TextDirection.ltr : TextDirection.rtl;

  @override
  String get reorderItemToStart => isBadini ? 'Bike serî' : 'بۆ سەرەتا';

  @override
  String get reorderItemToEnd => isBadini ? 'Bike dawiyê' : 'بۆ کۆتایی';

  @override
  String get reorderItemUp => isBadini ? 'Bike jor' : 'بۆ سەرەوە';

  @override
  String get reorderItemDown => isBadini ? 'Bike jêr' : 'بۆ خوارەوە';

  @override
  String get reorderItemLeft => isBadini ? 'Bike çep' : 'بۆ چەپ';

  @override
  String get reorderItemRight => isBadini ? 'Bike rast' : 'بۆ ڕاست';

  @override
  String get copyButtonLabel => isBadini ? 'Kopî' : 'کۆپی';

  @override
  String get cutButtonLabel => isBadini ? 'Jêbike' : 'بڕین';

  @override
  String get pasteButtonLabel => isBadini ? 'Paste bike' : 'پەیست';

  @override
  String get selectAllButtonLabel =>
      isBadini ? 'Hemû hilbijêre' : 'هەمووی هەڵبژێرە';
}

class _KurdishWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _KurdishWidgetsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ckb' || locale.languageCode == 'badini';

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return SynchronousFuture<WidgetsLocalizations>(
      KurdishWidgetsLocalizations(locale.languageCode == 'badini'),
    );
  }

  @override
  bool shouldReload(_KurdishWidgetsDelegate old) => false;
}

/// Cupertino (iOS) — کۆپی/پەیست و بەروار.
class KurdishCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const KurdishCupertinoLocalizations(this.isBadini);

  final bool isBadini;

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _KurdishCupertinoDelegate();

  @override
  String get copyButtonLabel => isBadini ? 'Kopî' : 'کۆپی';

  @override
  String get cutButtonLabel => isBadini ? 'Jêbike' : 'بڕین';

  @override
  String get pasteButtonLabel => isBadini ? 'Paste bike' : 'پەیست';

  @override
  String get selectAllButtonLabel =>
      isBadini ? 'Hemû hilbijêre' : 'هەمووی هەڵبژێرە';

  @override
  String get todayLabel => isBadini ? 'Îro' : 'ئەمڕۆ';

  @override
  String get alertDialogLabel => isBadini ? 'Hişyarî' : 'ئاگاداری';

  @override
  DatePickerDateOrder get datePickerDateOrder => DatePickerDateOrder.dmy;

  @override
  String datePickerMonth(int monthIndex) =>
      KurdishFormat.months[monthIndex - 1];

  @override
  String datePickerDayOfMonth(int dayIndex, [int? weekDay]) =>
      KurdishFormat.digits(dayIndex);

  @override
  String datePickerYear(int yearIndex) => KurdishFormat.digits(yearIndex);

  @override
  String datePickerHour(int hour) => KurdishFormat.digits(hour);

  @override
  String datePickerMinute(int minute) => KurdishFormat.padded(minute);

  @override
  String get anteMeridiemAbbreviation => isBadini ? 'SB' : 'ب‌ن';

  @override
  String get postMeridiemAbbreviation => isBadini ? 'EV' : 'د‌ن';
}

class _KurdishCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _KurdishCupertinoDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ckb' || locale.languageCode == 'badini';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<CupertinoLocalizations>(
      KurdishCupertinoLocalizations(locale.languageCode == 'badini'),
    );
  }

  @override
  bool shouldReload(_KurdishCupertinoDelegate old) => false;
}
