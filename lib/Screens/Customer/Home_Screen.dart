import 'package:bizmatic_solutions/Components/Fonts.dart';
import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:bizmatic_solutions/Documentation/Doc_main.dart';
import 'package:bizmatic_solutions/FearureList/Feature_List.dart';
import 'package:bizmatic_solutions/Screens/Customer/Product_Selection_Screen_for_Chat.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String? restaurantName;
  final String? customerId;

  const HomeScreen({super.key, this.restaurantName, this.customerId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _backgroundColor;

  @override
  void initState() {
    super.initState();

    // Color animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Define a tween for background color animation
    _backgroundColor = ColorTween(
      begin: const Color(0xFF0D47A1),
      end: const Color(0xFF42A5F5),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleNavigation(Widget screen) {
    if (widget.customerId == null || widget.restaurantName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer information not available")),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _backgroundColor,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _backgroundColor.value ?? AppColors.primary,
                  Colors.white10,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello\nDear, ${widget.restaurantName ?? 'Guest'}",
                  style: ResponsiveTextStyles.title(context).copyWith(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "How can we help you?",
                  style: ResponsiveTextStyles.body(
                    context,
                  ).copyWith(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    children: [
                      _buildStyledButton(
                        text: "Chat with us",
                        icon: Icons.chat,
                        onPressed:
                            () => _handleNavigation(
                              ProductSelectionScreenforChat(
                                customerId: widget.customerId!,
                                restaurantName: widget.restaurantName!,
                              ),
                            ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      _buildStyledButton(
                        text: "Documentation",
                        icon: Icons.book,
                        onPressed:
                            () => _handleNavigation(
                              Doc_mainScreen(
                                customerId: widget.customerId!,
                                restaurantName: widget.restaurantName!,
                              ),
                            ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      _buildStyledButton(
                        text: "Feature List",
                        icon: Icons.featured_play_list,
                        onPressed:
                            () => _handleNavigation(
                              FeatureList(
                                customerId: widget.customerId!,
                                customerName: widget.restaurantName!,
                                customerEmail: 'bizmaticshaban@gmail.com',
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyledButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: ResponsiveTextStyles.body(context).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
