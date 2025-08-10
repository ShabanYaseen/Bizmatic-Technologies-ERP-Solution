import 'package:bizmatic_solutions/Components/Fonts.dart';
import 'package:bizmatic_solutions/Components/Textfield.dart';
import 'package:bizmatic_solutions/Components/colors.dart';
import 'package:bizmatic_solutions/Screens/Agents/AgentHomeScreen.dart';
import 'package:bizmatic_solutions/Screens/Customer/Home_Screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController userNameController = TextEditingController();
  TextEditingController userIdController = TextEditingController();

  late AnimationController _animationController;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();

    // Animation controller for gradient background
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Color transitions
    _color1 = ColorTween(
      begin: const Color.fromARGB(255, 149, 192, 255),
      end: const Color.fromARGB(255, 255, 238, 163),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _color2 = ColorTween(
      begin: const Color.fromARGB(255, 255, 238, 163),
      end: const Color(0xFF90CAF9),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    userNameController.dispose();
    userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _color1.value ?? Colors.blue,
                  _color2.value ?? Colors.lightBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1,
                  vertical: screenHeight * 0.1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome to\nBizmatic Technologies\nSolutions",
                      style: ResponsiveTextStyles.title(context)
                          .copyWith(color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.08),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "Assets/Main_Logo/Logo.png",
                            width: screenWidth * 0.3,
                          ),
                          SizedBox(height: screenHeight * 0.05),
                          MyTextField(
                            hintText: "Enter username",
                            controller: userNameController,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          MyTextField(
                            hintText: "Enter your id",
                            controller: userIdController,
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          SizedBox(
                            width: screenWidth * 0.5,
                            child: ElevatedButton(
                              onPressed: () async {
                                String usernameInput =
                                    userNameController.text.trim();
                                String userIdInput =
                                    userIdController.text.trim();

                                if (usernameInput.isEmpty ||
                                    userIdInput.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Please enter both fields")),
                                  );
                                  return;
                                }

                                try {
                                  // Check Customers Collection
                                  QuerySnapshot customerSnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('Customers')
                                          .where('restaurantName',
                                              isEqualTo: usernameInput)
                                          .where('customerId',
                                              isEqualTo: userIdInput)
                                          .limit(1)
                                          .get();

                                  if (customerSnapshot.docs.isNotEmpty) {
                                    final data = customerSnapshot.docs.first
                                        .data() as Map<String, dynamic>;
                                    final isActive =
                                        data['isActive'] == true;

                                    if (!isActive) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Customer account is not active")),
                                      );
                                      return;
                                    }

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomeScreen(
                                          restaurantName:
                                              data['restaurantName'],
                                          customerId: data['customerId'],
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // Check Agents Collection
                                  QuerySnapshot agentSnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('Agents')
                                          .where('agentName',
                                              isEqualTo: usernameInput)
                                          .where('agentId',
                                              isEqualTo: userIdInput)
                                          .limit(1)
                                          .get();

                                  if (agentSnapshot.docs.isNotEmpty) {
                                    final data = agentSnapshot.docs.first
                                        .data() as Map<String, dynamic>;
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AgentHomeScreen(
                                          agentId: data['agentId'],
                                          agentName: data['agentName'],
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Invalid login credentials")),
                                  );
                                } catch (e) {
                                  debugPrint("Login error: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Login failed. Please try again.")),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02,
                                ),
                              ),
                              child: Text(
                                "Submit",
                                style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
