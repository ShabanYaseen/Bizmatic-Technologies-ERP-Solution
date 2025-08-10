import 'package:bizmatic_solutions/Components/Fonts.dart';
import 'package:bizmatic_solutions/Components/colors.dart';
import 'package:bizmatic_solutions/Screens/Agents/Agent_feature_request_handaling.dart';
import 'package:bizmatic_solutions/Screens/Agents/Agentchatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AgentHomeScreen extends StatefulWidget {
  final String agentId;
  final String agentName;

  const AgentHomeScreen({
    super.key,
    required this.agentId,
    required this.agentName,
  });

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Mark agent as available when they log in
    FirebaseFirestore.instance.collection('Agents').doc(widget.agentId).update({
      'isAvailable': true,
    });
  }

  @override
  void dispose() {
    // Mark agent as unavailable when they log out
    FirebaseFirestore.instance.collection('Agents').doc(widget.agentId).update({
      'isAvailable': false,
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.Background,
      appBar: AppBar(
        title: Text(widget.agentName, style: ResponsiveTextStyles.title(context).copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("Chats")
                .where('agentId', isEqualTo: widget.agentId)
                .where('status', isEqualTo: 'active')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return Center(child: Text("No active chats yet."));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatId = chatDoc.id;
              final data = chatDoc.data() as Map<String, dynamic>;

              final customerId = data['customerId'] ?? 'Unknown';
              final restaurantName = data['restaurantName'] ?? 'Unknown';
              final lastMessage = data['lastMessage'] ?? 'No messages yet';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AgentChatScreen(
                              chatId: chatId,
                              customerId: customerId,
                              restaurantName: restaurantName,
                              agentId: widget.agentId,
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withOpacity(0.8),
                          child: Text(
                            restaurantName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurantName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                lastMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.featured_play_list, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgentFeatureRequests(agentId: widget.agentId , agentName: widget.agentName,),
            ), // your page
          );
        },
      ),
    );
  }
}
