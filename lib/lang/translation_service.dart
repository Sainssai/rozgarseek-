import 'dart:ui';

import 'package:get/get.dart';
import 'package:razgorsek/lang/de_DE.dart';
import 'package:razgorsek/lang/ta_in.dart';
import 'package:razgorsek/lang/te_in.dart';
import 'en_us.dart';
import 'hi_in.dart';

class TranslationService extends Translations {
  static final fallbackLocale = const Locale('en', 'US');

  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'hi_IN': hiIN,
    'te_IN': teIN,
    'ta_IN': taIN,
    'de_DE':deDE
  };
}
