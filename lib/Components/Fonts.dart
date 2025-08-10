import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:flutter/material.dart';


class ResponsiveTextStyles {
  static TextStyle title(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.06; // 6% of screen width
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: AppColors.white,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle subtitle(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.045;
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: AppColors.white,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle body(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.04;
    return TextStyle(
      fontSize: size,
      color: AppColors.white,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle small(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.035;
    return TextStyle(
      fontSize: size,
      color: AppColors.white,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle button(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.04;
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: AppColors.Black,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle error(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.035;
    return TextStyle(
      fontSize: size,
      color: AppColors.error,
      decoration: TextDecoration.none,
    );
  }

  static caption(BuildContext context) {}
}
