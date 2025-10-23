import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:passwordsecurity/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
void initState() {
 super.initState();
 Future.delayed(Duration(seconds: 3), () {
 if (!mounted) return;
 Navigator.pushReplacementNamed(context, Routes.intro);
 });
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/lottie/Lock.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
