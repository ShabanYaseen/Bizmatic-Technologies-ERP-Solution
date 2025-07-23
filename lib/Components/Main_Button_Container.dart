import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:flutter/material.dart';

class MainButton extends StatefulWidget {
  final IconData? icon;
  final String? text;
  final VoidCallback? onPressed;

  const MainButton({
    super.key,
    this.icon,
    this.text,
    this.onPressed,
  });

  @override
  State<MainButton> createState() => _MainButtonState();
}

class _MainButtonState extends State<MainButton> {
  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive sizing
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: screenWidth * 0.8,
      child: ElevatedButton(
        onPressed: widget.onPressed ?? () {},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.02,
          ),
        ), // Default empty function if null
        child: Column(
          children: [
            if (widget.icon != null)
              Icon(widget.icon, size: 50, color: AppColors.primary,),
            if (widget.text != null)
              Text(
                widget.text!,
                style: TextStyle(fontSize: screenWidth * 0.08, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
