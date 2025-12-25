import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/splash/view/splash_page.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>();

class PetConnectApp extends ConsumerWidget {
  const PetConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: '/',
      navigatorKey: rootNavKey,
    );
  }
}
