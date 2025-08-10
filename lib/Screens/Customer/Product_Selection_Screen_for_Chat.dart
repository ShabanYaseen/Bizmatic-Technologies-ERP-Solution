import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:bizmatic_solutions/Components/Fonts.dart';
import 'package:bizmatic_solutions/Components/Product_Selection_Button.dart';
import 'package:bizmatic_solutions/Screens/Customer/CustomerChatScreen.dart';
import 'package:flutter/material.dart';

class ProductSelectionScreenforChat extends StatefulWidget {
  final String customerId;
  final String restaurantName;

  const ProductSelectionScreenforChat({
    super.key,
    required this.customerId,
    required this.restaurantName,
  });

  @override
  State<ProductSelectionScreenforChat> createState() =>
      _ProductSelectionScreenforChatState();
}

class _ProductSelectionScreenforChatState
    extends State<ProductSelectionScreenforChat> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: Column(
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  "Please select the product",
                  style: ResponsiveTextStyles.title(context).copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You need help with!",
                  style: ResponsiveTextStyles.subtitle(context).copyWith(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // White card body with buttons
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ListView(
                children: [
                  _buildProductButton("Butter POS"),
                  SizedBox(height: screenHeight * 0.03),
                  _buildProductButton("Gofrugal Serveasy"),
                  SizedBox(height: screenHeight * 0.03),
                  _buildProductButton("Gofrugal RetailEasy"),
                  SizedBox(height: screenHeight * 0.03),
                  _buildProductButton("Odoo"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductButton(String productName) {
    return ProductSelectionButton(
      text: productName,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerChatScreen(
              productNameforChat: productName,
              customerId: widget.customerId,
              restaurantName: widget.restaurantName,
            ),
          ),
        );
      },
    );
  }
}
