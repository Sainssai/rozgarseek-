import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razgorsek/controllers/locale_controller.dart';
import 'package:razgorsek/screens/authentication.dart';
import 'firebase_options.dart';
import 'lang/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize LocaleController globally
  Get.put(LocaleController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocaleController>(
      builder: (controller) {
        print('GetMaterialApp locale: ${controller.locale.value}'); // Debug log
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RozgarSeek'.tr,
          translations: TranslationService(),
          locale: controller.locale.value, // Use reactive locale
          fallbackLocale: TranslationService.fallbackLocale,
          home: const AuthScreen(),
        );
      },
    );
  }
}