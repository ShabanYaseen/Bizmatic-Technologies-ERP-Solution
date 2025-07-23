import 'package:bizmatic_solutions/Components/Fonts.dart';
import 'package:bizmatic_solutions/Components/Textfield.dart';
import 'package:bizmatic_solutions/Components/colors.dart';
import 'package:bizmatic_solutions/Screens/AgentHomeScreen.dart';
import 'package:bizmatic_solutions/Screens/Home_Screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController userIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SingleChildScrollView(
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
                style: ResponsiveTextStyles.title(context),
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
                          String usernameInput = userNameController.text.trim();
                          String userIdInput = userIdController.text.trim();

                          if (usernameInput.isEmpty || userIdInput.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Please enter both fields")),
                            );
                            return;
                          }

                          try {
                            // Check Customers Collection
                            QuerySnapshot customerSnapshot =
                                await FirebaseFirestore.instance
                                    .collection('Customers')
                                    .where('restaurantName', isEqualTo: usernameInput)
                                    .where('customerId', isEqualTo: userIdInput)
                                    .limit(1)
                                    .get();

                            if (customerSnapshot.docs.isNotEmpty) {
                              final data = customerSnapshot.docs.first.data() as Map<String, dynamic>;
                              final isActive = data['isActive'] == true;

                              if (!isActive) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Customer account is not active")),
                                );
                                return;
                              }

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeScreen(
                                    restaurantName: data['restaurantName'],
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
                                    .where('agentName', isEqualTo: usernameInput)
                                    .where('agentId', isEqualTo: userIdInput)
                                    .limit(1)
                                    .get();

                            if (agentSnapshot.docs.isNotEmpty) {
                              final data = agentSnapshot.docs.first.data() as Map<String, dynamic>;
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
                              SnackBar(content: Text("Invalid login credentials")),
                            );
                          } catch (e) {
                            print("Login error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Login failed. Please try again.")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.02,
                          ),
                        ),
                        child: Text(
                          "Submit",
                          style: TextStyle(fontSize: screenWidth * 0.045, color: AppColors.primary),
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
    );
  }
}