import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller; // 👈 Added controller option

  const MyTextField({
    super.key,
    this.hintText = '',
    this.controller, // 👈 Accept controller
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller, // 👈 Assign controller here
      cursorColor: AppColors.Black,
      style: TextStyle(color: AppColors.Black),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),

        // Border when not focused
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.Background, width: 1),
        ),

        // Border when focused
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.Background, width: 2),
        ),
      ),
    );
  }
}
