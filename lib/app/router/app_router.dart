import 'package:flutter/material.dart';
import '../../features/ai_diagnosis/view/ai_diagnosis_page.dart';
import '../../features/auth/view/account_page.dart';
import '../../features/auth/view/interests_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/otp_page.dart';
import '../../features/auth/view/register_page.dart';
import '../../features/auth/view/verify_success_page.dart';
import '../../features/home/view/home_page.dart';
import '../../features/splash/view/splash_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../../features/profile/view/edit_profile_page.dart';
import '../../features/profile/view/settings_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case '/account':
        return MaterialPageRoute(builder: (_) => const AccountPage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case '/otp':
        return MaterialPageRoute(
          builder: (_) => const OtpPage(),
          settings: settings,
        );
      case '/verify-success':
        return MaterialPageRoute(builder: (_) => const VerifySuccessPage());
      case '/interests':
        return MaterialPageRoute(builder: (_) => const InterestsPage());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => const EditProfilePage());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());

      case '/ai-diagnosis':
        return MaterialPageRoute(builder: (_) => const AiDiagnosisPage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
