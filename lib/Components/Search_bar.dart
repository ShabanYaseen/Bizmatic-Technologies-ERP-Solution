import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:flutter/material.dart';

class MySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSend;
  final bool clearOnSend;

  const MySearchBar({
    super.key,
    required this.controller,
    this.hintText = "Search...",
    this.onChanged,
    this.onSend,
    this.clearOnSend = false,  // if true, clears after send
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: AppColors.primary),
            onPressed: () {
              if (onSend != null) {
                onSend!(controller.text);
              }
              if (clearOnSend) {
                controller.clear();
                if (onChanged != null) onChanged!('');
              }
            },
          ),
        ],
      ),
    );
  }
}
