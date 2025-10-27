import 'package:flutter/material.dart';
import 'package:passwordsecurity/core/auth_guard.dart';
import 'package:passwordsecurity/screens/home_screen.dart';
import 'package:passwordsecurity/screens/intro_screen.dart';
import 'package:passwordsecurity/screens/login_screen.dart';
import 'package:passwordsecurity/screens/splash_screen.dart';

class Routes {
  static const String splash = "/";
  static const String intro = "/intro";
  static const String login = "/login";
  static const String home = "/home";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case intro:
        return MaterialPageRoute(builder: (_) => IntroScreen());
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case home:
        // Wrap HomeScreen with AuthGuard so only authenticated users can access it
        return MaterialPageRoute(
            builder: (_) => AuthGuard(child: HomeScreen()));
      default:
        return MaterialPageRoute(
          builder: (_) =>
              Scaffold(body: Center(child: Text('Rota não encontrada!'))),
        );
    }
  }
}
