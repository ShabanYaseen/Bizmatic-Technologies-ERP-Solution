import 'dart:async';
import 'dart:convert';
import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:bizmatic_solutions/Components/Fonts.dart';
import 'package:bizmatic_solutions/Components/Search_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustomerChatScreen extends StatefulWidget {
  final String productNameforChat;
  final String customerId;
  final String restaurantName;

  const CustomerChatScreen({
    super.key,
    required this.productNameforChat,
    required this.customerId,
    required this.restaurantName,
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final TextEditingController _userTextController = TextEditingController();
  List<Map<String, dynamic>> chatMessages = [];
  String? chatId;
  bool isAgentConnected = false;
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  bool _isLoading = false;
  final List<String> _lastThreeResponses = [];
  bool _showPredefinedQuestions = true;

  // Predefined questions based on product
  final List<String> predefinedQuestions = [
    "What are the key features of this product?",
    "How do I use this product?",
    "What are the benefits of this product?",
    "Are there any discounts available?",
    "What makes this product special?",
  ];

  @override
  void initState() {
    super.initState();
    // No automatic greeting message
    _showPredefinedQuestions = true;
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _userTextController.dispose();
    super.dispose();
  }

  void _addBotMessage(String message) {
    setState(() {
      chatMessages.insert(0, {
        'message': message,
        'isUser': false,
        'timestamp': DateTime.now(),
      });
      _lastThreeResponses.add(message);
      if (_lastThreeResponses.length > 3) {
        _lastThreeResponses.removeAt(0);
      }
      _showPredefinedQuestions = false;
    });
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
                    'timestamp': (message['timestamp'] as Timestamp).toDate(),
                  });
                });
              }
            }
          }
        });
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    setState(() {
      chatMessages.insert(0, {
        'message': userText,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
      _showPredefinedQuestions = false;
    });

    // If already connected to agent, send message to agent
    if (isAgentConnected && chatId != null) {
      await _sendMessageToAgent(userText);
      setState(() => _isLoading = false);
      return;
    }

    // Otherwise, use Ollama
    try {
      final botReply = await _sendToOllama(userText);
      _addBotMessage(botReply);

      // Check if last 3 responses are 80% similar
      if (_lastThreeResponses.length >= 3 && _areResponsesSimilar()) {
        await _connectToAgent("I need to speak with an agent");
      }
    } catch (e) {
      _addBotMessage("Sorry, I'm having trouble connecting. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _areResponsesSimilar() {
    if (_lastThreeResponses.length < 3) return false;

    // Simple similarity check - could be enhanced with more sophisticated algorithm
    final first = _lastThreeResponses[0].toLowerCase();
    final second = _lastThreeResponses[1].toLowerCase();
    final third = _lastThreeResponses[2].toLowerCase();

    // Check if at least two responses are 80% similar
    return _calculateSimilarity(first, second) > 0.8 ||
        _calculateSimilarity(first, third) > 0.8 ||
        _calculateSimilarity(second, third) > 0.8;
  }

  double _calculateSimilarity(String s1, String s2) {
    // Simple similarity calculation based on shared words
    final words1 = s1.split(' ');
    final words2 = s2.split(' ');
    final intersection = words1.where((word) => words2.contains(word)).length;
    final union = (words1.length + words2.length) / 2;
    return intersection / union;
  }

  Future<String> _sendToOllama(String userText) async {
    const String apiKey =
        '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';
    const String url = 'https://api.groq.com/openai/v1/chat/completions';

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "messages": [
        {
          "role": "system",
          "content":
              "You are a helpful assistant for ${widget.restaurantName}, "
              "specializing in ${widget.productNameforChat}. "
              "Be concise and helpful. If you can't help, suggest connecting with an agent.",
        },
        {"role": "user", "content": userText},
      ],
      "model": "meta-llama/llama-4-maverick-17b-128e-instruct",
      "temperature": 0.7,
      "max_tokens": 1024,
      "top_p": 1,
      "stream": false,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get response from Ollama');
    }
  }

  Future<void> _connectToAgent(String initialMessage) async {
    setState(() => _isLoading = true);

    try {
      // Get first available agent
      final agents =
          await FirebaseFirestore.instance
              .collection('Agents')
              .where('isAvailable', isEqualTo: true)
              .limit(1)
              .get();

      if (agents.docs.isEmpty) {
        _addBotMessage(
          'All agents are currently busy. Please try again later.',
        );
        return;
      }

      final agent = agents.docs.first;
      final agentId = agent.id;
      final agentName = agent['agentName'];

      // Create new chat session with a fresh ID
      chatId = "${widget.customerId}_${DateTime.now().millisecondsSinceEpoch}";
      final chatDocRef = FirebaseFirestore.instance
          .collection("Chats")
          .doc(chatId);

      await chatDocRef.set({
        'customerId': widget.customerId,
        'agentId': agentId,
        'restaurantName': widget.restaurantName,
        'productName': widget.productNameforChat,
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
      await FirebaseFirestore.instance.collection('Agents').doc(agentId).update(
        {'isAvailable': false},
      );

      setState(() {
        isAgentConnected = true;
        chatMessages = []; // Clear previous messages
      });

      _addBotMessage('You are now connected with agent $agentName');
      _listenForMessages();
    } catch (e) {
      _addBotMessage('Error connecting to agent. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.Background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset("Assets/Main_Logo/Logo.png"),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ERP Support",
                  style: ResponsiveTextStyles.body(context)
                      .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  isAgentConnected ? "Live Agent" : "Virtual Assistant",
                  style: ResponsiveTextStyles.small(context)
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!isAgentConnected)
            IconButton(
              icon: const Icon(Icons.person, size: 20),
              onPressed: () => _connectToAgent("I'd like to speak with an agent"),
              tooltip: 'Connect with agent',
            ),
        ],
      ),
      body: Container(
        color: AppColors.Background, // Set the background color here
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.Background, // Ensure this matches
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      ListView.builder(
                        reverse: true,
                        padding: EdgeInsets.only(
                          top: 12,
                          bottom: _isLoading ? 60 : 12,
                          left: 12,
                          right: 12,
                        ),
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final chat = chatMessages[index];
                          return ChatBubble(
                            message: chat['message'],
                            isUser: chat['isUser'],
                            timestamp: chat['timestamp'],
                          );
                        },
                      ),
                      if (_showPredefinedQuestions && chatMessages.isEmpty)
                        Align(
                          alignment: Alignment.center,
                          child: PredefinedQuestions(
                            questions: predefinedQuestions,
                            onQuestionSelected: (question) {
                              sendMessage(question);
                            },
                          ),
                        ),
                      if (_isLoading)
                        const Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: TypingIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: MySearchBar(
                      controller: _userTextController,
                      onSend: (text) {
                        if (text.trim().isNotEmpty) {
                          sendMessage(text.trim());
                          _userTextController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime? timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isUser ? 48 : 8,
                right: isUser ? 8 : 48,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTime(timestamp!),
                        style: TextStyle(
                          color: isUser ? Colors.white70 : Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser)
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          _buildDot(1),
          _buildDot(2),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        curve: Curves.easeInOut,
        child: const SizedBox(),
      ),
    );
  }
}

class PredefinedQuestions extends StatelessWidget {
  final List<String> questions;
  final Function(String) onQuestionSelected;

  const PredefinedQuestions({
    super.key,
    required this.questions,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick questions about this product:",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...questions.map((question) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onQuestionSelected(question),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}