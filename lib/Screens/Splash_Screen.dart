import 'dart:async';

import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:flutter/material.dart';
import 'package:bizmatic_solutions/Screens/Login_Screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Splash Screen function for page route
    @override
    void initState() {
      super.initState();
      // Timer for 3 seconds then navigate
      Timer(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: AppColors.Background,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Image.asset(
                "Assets/Main_Logo/Logo.png",
                width: screenWidth * 0.3, // 20% of screen width
                height: screenWidth * 0.3,
              ),
        ),
      ),
    );
  }
}
