import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/student_auth_provider.dart';
import 'core/theme/branding_provider.dart';
import 'core/theme/student_theme.dart';
import 'features/auth/student_login_screen.dart';
import 'features/navigation/student_shell_screen.dart';
import 'features/onboarding/student_onboarding_screen.dart';

import 'core/services/push_notification_service.dart';
import 'core/services/in_app_banner_service.dart';

// Provider to check if student has seen onboarding
final onboardingStateProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('has_seen_onboarding') ?? false;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FCM Push Notifications
  PushNotificationService().initialize();

  runApp(
    const ProviderScope(
      child: StudentAppRoot(),
    ),
  );
}

class StudentAppRoot extends ConsumerWidget {
  const StudentAppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider);
    final auth = ref.watch(studentAuthProvider);
    final onboardingAsync = ref.watch(onboardingStateProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      title: branding.centerName.isNotEmpty ? branding.centerName : 'EduZorar Student',
      debugShowCheckedModeBanner: false,
      theme: StudentTheme.buildTheme(branding),
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: onboardingAsync.when(
        loading: () => Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: branding.primaryColor),
          ),
        ),
        error: (_, __) => auth.isAuthenticated
            ? const StudentShellScreen()
            : const StudentLoginScreen(),
        data: (hasSeenOnboarding) {
          if (!hasSeenOnboarding) {
            return const StudentOnboardingScreen();
          }

          if (auth.isLoading) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: branding.primaryColor),
              ),
            );
          }

          return auth.isAuthenticated
              ? const StudentShellScreen()
              : const StudentLoginScreen();
        },
      ),
    );
  }
}
