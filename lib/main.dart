import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/student_auth_provider.dart';
import 'core/theme/branding_provider.dart';
import 'core/theme/student_theme.dart';
import 'features/auth/student_login_screen.dart';
import 'features/navigation/student_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

    return MaterialApp(
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
      home: auth.isLoading
          ? Scaffold(
              backgroundColor: StudentTheme.backgroundDark,
              body: Center(
                child: CircularProgressIndicator(color: branding.accentColor),
              ),
            )
          : auth.isAuthenticated
              ? const StudentShellScreen()
              : const StudentLoginScreen(),
    );
  }
}
