import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocaleController extends GetxController {
  var locale = const Locale('en', 'US').obs;

  void changeLocale(Locale newLocale) {
    print('Changing locale to: $newLocale'); // Debug log
    locale.value = newLocale;
    Get.updateLocale(newLocale);
    update(); // Notify GetBuilder widgets
  }
}