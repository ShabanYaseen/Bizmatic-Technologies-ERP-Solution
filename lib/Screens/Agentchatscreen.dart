import 'dart:async';
import 'package:bizmatic_solutions/Components/Search_bar.dart';
import 'package:bizmatic_solutions/Components/colors.dart';
import 'package:bizmatic_solutions/Models/Chat_Model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AgentChatScreen extends StatefulWidget {
  final String chatId;
  final String customerId;
  final String restaurantName;
  final String agentId;

  const AgentChatScreen({
    super.key,
    required this.chatId,
    required this.customerId,
    required this.restaurantName,
    required this.agentId,
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> chatMessages = [];
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  bool _isDisposed = false;
  bool _greetingSent = false;

  @override
  void initState() {
    super.initState();
    _loadChatMessages();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _loadChatMessages() {
    FirebaseFirestore.instance
        .collection("Chats")
        .doc(widget.chatId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .get()
        .then((snapshot) {
      if (_isDisposed) return;

      // Check for existing greeting message
      final existingMessages = snapshot.docs.map((doc) {
        final message = doc.data();
        return {
          'message': message['text'],
          'isUser': message['sender'] == widget.agentId,
        };
      }).toList();

      // Check if greeting was already sent
      _greetingSent = existingMessages.any((msg) => 
          !msg['isUser'] && msg['message'] == "Hello from Bizmatic Technologies! How can I help you today?");

      setState(() {
        chatMessages = existingMessages;
      });

      _listenForNewMessages();
    });
  }

  void _listenForNewMessages() {
  _messageSubscription = FirebaseFirestore.instance
      .collection("Chats")
      .doc(widget.chatId)
      .collection("messages")
      .orderBy("timestamp", descending: false)
      .snapshots()
      .listen((snapshot) {
    if (_isDisposed) return;

    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final message = change.doc.data() as Map<String, dynamic>;
        
        // First check if this is a customer message
        if (message['sender'] != widget.agentId) {
          // Then check if it's a request to talk with agent
          final text = message['text'].toLowerCase();
          final isAgentRequest = text.contains('talk with agent') || 
                               text.contains('talk to agent');
          
          if (isAgentRequest && !_greetingSent) {
            _greetingSent = true;
            _sendGreetingMessage();
          }
        }

        setState(() {
          chatMessages.add({
            'message': message['text'],
            'isUser': message['sender'] == widget.agentId,
          });
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  });
}

  Future<void> _sendGreetingMessage() async {
    final greetingMessage = "Hello from Bizmatic Technologies! How can I help you today?";
    
    try {
      final chatRef = FirebaseFirestore.instance.collection("Chats").doc(widget.chatId);

      final messageData = {
        'text': greetingMessage,
        'sender': widget.agentId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await chatRef.collection("messages").add(messageData);
      await chatRef.update({
        'lastMessage': greetingMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending greeting message: $e");
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      final chatRef = FirebaseFirestore.instance.collection("Chats").doc(widget.chatId);

      final messageData = {
        'text': text,
        'sender': widget.agentId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await chatRef.collection("messages").add(messageData);
      await chatRef.update({
        'lastMessage': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _controller.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  Future<void> _endChat() async {
    try {
      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .update({'status': 'completed'});

      await FirebaseFirestore.instance
          .collection('Agents')
          .doc(widget.agentId)
          .update({'isAvailable': true});

      setState(() {
        chatMessages.clear();
        _greetingSent = false;
      });

      Navigator.pop(context);
    } catch (e) {
      print("Error ending chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.Background,
      appBar: AppBar(
        title: Text(widget.restaurantName),
        actions: [
          IconButton(icon: Icon(Icons.call_end), onPressed: _endChat),
        ],
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
                controller: _scrollController,
                itemCount: chatMessages.length,
                itemBuilder: (context, index) {
                  final chat = chatMessages[index];
                  return ChatBubble(
                    message: chat['message'],
                    isUser: chat['isUser'],
                    isAgentLoggedIn: true,
                    timestamp: null,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MySearchBar(
                controller: _controller,
                hintText: "Type your message...",
                onSend: (text) {
                  if (text.trim().isNotEmpty) {
                    sendMessage(text.trim());
                  }
                },
                clearOnSend: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}