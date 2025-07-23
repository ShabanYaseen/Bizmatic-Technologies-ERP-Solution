import 'dart:async';
import 'dart:convert';
import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:bizmatic_solutions/Components/Fonts.dart';
import 'package:bizmatic_solutions/Components/Search_bar.dart';
import 'package:bizmatic_solutions/Models/Chat_Model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Customerchatscreen extends StatefulWidget {
  final String productNameforChat;
  final String customerId;
  final String restaurantName;

  const Customerchatscreen({
    super.key,
    required this.productNameforChat,
    required this.customerId,
    required this.restaurantName,
  });

  @override
  State<Customerchatscreen> createState() => _CustomerchatscreenState();
}

class _CustomerchatscreenState extends State<Customerchatscreen> {
  final TextEditingController _usertextcontroller = TextEditingController();
  List<Map<String, dynamic>> chatMessages = [];
  String? chatId;
  bool isAgentConnected = false;
  StreamSubscription<QuerySnapshot>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    // Start fresh - don't load any previous messages
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _listenForMessages() {
    if (chatId == null) return;

    _chatSubscription = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final message = change.doc.data() as Map<String, dynamic>;
          if (message['sender'] != widget.customerId) {
            setState(() {
              chatMessages.insert(0, {
                'message': message['text'],
                'isUser': false,
              });
            });
          }
        }
      }
    });
  }

  void sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    setState(() {
      chatMessages.insert(0, {'message': userText, 'isUser': true});
    });

    String lowerText = userText.toLowerCase();

    // Check if user wants to talk to agent
    if (lowerText.contains('talk with agent') || lowerText.contains('talk to agent')) {
      await _connectToAgent(userText);
      return;
    }

    // If already connected to agent, send message to agent
    if (isAgentConnected && chatId != null) {
      await _sendMessageToAgent(userText);
      return;
    }

    // Otherwise, use Voiceflow
    String botReply = await sendToVoiceflow(
        "This question is for ${widget.productNameforChat} product: $userText");
    setState(() {
      chatMessages.insert(0, {'message': botReply, 'isUser': false});
    });
  }

  Future<void> _connectToAgent(String initialMessage) async {
    // Get first available agent
    final agents = await FirebaseFirestore.instance
        .collection('Agents')
        .where('isAvailable', isEqualTo: true)
        .limit(1)
        .get();

    if (agents.docs.isEmpty) {
      setState(() {
        chatMessages.insert(0, {
          'message': 'All agents are currently busy. Please try again later.',
          'isUser': false,
        });
      });
      return;
    }

    final agent = agents.docs.first;
    final agentId = agent.id;
    final agentName = agent['agentName'];

    // Create new chat session with a fresh ID
    chatId = "${widget.customerId}_${DateTime.now().millisecondsSinceEpoch}";
    final chatDocRef = FirebaseFirestore.instance.collection("Chats").doc(chatId);
    
    await chatDocRef.set({
      'customerId': widget.customerId,
      'agentId': agentId,
      'restaurantName': widget.restaurantName,
      'lastMessage': initialMessage,
      'status': 'active',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Add initial message
    await chatDocRef.collection("messages").add({
      'text': initialMessage,
      'sender': widget.customerId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Mark agent as unavailable
    await FirebaseFirestore.instance.collection('Agents').doc(agentId).update({
      'isAvailable': false,
    });

    setState(() {
      isAgentConnected = true;
      chatMessages = []; // Clear previous messages
      chatMessages.insert(0, {'message': initialMessage, 'isUser': true});
      chatMessages.insert(0, {
        'message': 'You are now connected with agent $agentName',
        'isUser': false,
      });
    });

    _listenForMessages();
  }

  Future<void> _sendMessageToAgent(String message) async {
    if (chatId == null) return;

    await FirebaseFirestore.instance
        .collection("Chats")
        .doc(chatId!)
        .collection("messages")
        .add({
      'text': message,
      'sender': widget.customerId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message in chat document
    await FirebaseFirestore.instance.collection("Chats").doc(chatId!).update({
      'lastMessage': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.Background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: AppColors.white),
        title: Row(
          children: [
            Image.asset("Assets/Main_Logo/Logo.png", width: screenWidth * 0.08),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bizmatic Technologies", 
                    style: ResponsiveTextStyles.body(context).copyWith(color: AppColors.white)),
                Text(isAgentConnected ? "Connected with Agent" : "Online", 
                    style: ResponsiveTextStyles.small(context)),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenHeight * 0.03,
          vertical: screenWidth * 0.09,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: chatMessages.length,
                itemBuilder: (context, index) {
                  final chat = chatMessages[index];
                  return ChatBubble(
                    message: chat['message'],
                    isUser: chat['isUser'],
                    isAgentLoggedIn: false,
                    timestamp: null,
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MySearchBar(
                controller: _usertextcontroller,
                onSend: (text) {
                  if (text.trim().isNotEmpty) {
                    sendMessage(text.trim());
                    _usertextcontroller.clear();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> sendToVoiceflow(String userText) async {
  const String apiKey = 'VF.DM.68063ca4821a36494d3ec6d6.tVAkPiV28sL9wLzj';

  final url = Uri.parse('https://general-runtime.voiceflow.com/state/user/$apiKey/interact?logs=off');

  final response = await http.post(
    url,
    headers: {'Authorization': apiKey, 'Content-Type': 'application/json'},
    body: jsonEncode({"request": {"type": "text", "payload": userText}}),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    for (var item in data) {
      if (item['type'] == 'text') {
        return item['payload']['message'].toString();
      }
    }
    return 'No text response from Voiceflow';
  } else {
    return 'Error ${response.statusCode} from Voiceflow';
  }
}