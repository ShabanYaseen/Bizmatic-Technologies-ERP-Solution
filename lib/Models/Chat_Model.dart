import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isAgentLoggedIn;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.isAgentLoggedIn, required timestamp,
  });

  @override
  Widget build(BuildContext context) {
    // Get correct avatar widget based on type
    Widget getCustomerAvatar() {
      return CircleAvatar(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person, color: AppColors.Background),
      );
    }

    Widget getAgentAvatar() {
      return CircleAvatar(
        backgroundColor: Colors.grey[400],
        child: Image.asset("Assets/Main_Logo/Logo.png", height: 30, width: 30),
      );
    }

    // Decide which avatar to show for current message
    final avatar = () {
      if (isAgentLoggedIn) {
        return isUser ? getAgentAvatar() : getCustomerAvatar();
      } else {
        return isUser ? getCustomerAvatar() : getAgentAvatar();
      }
    }();

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[avatar, const SizedBox(width: 8)],
        Flexible(
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(0),
                  bottomRight:
                      isUser
                          ? const Radius.circular(0)
                          : const Radius.circular(16),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        if (isUser) ...[const SizedBox(width: 8), avatar],
      ],
    );
  }
}
