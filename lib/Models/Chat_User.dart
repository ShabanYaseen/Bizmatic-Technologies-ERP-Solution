class ChatUser {
  String? restaurantName;
  String? customerId;
  String? category;
  bool? isActive;
  String? pushToken;

  ChatUser(
      {this.restaurantName,
      this.customerId,
      this.category,
      this.isActive,
      this.pushToken});

  ChatUser.fromJson(Map<String, dynamic> json) {
    restaurantName = json['restaurantName'];
    customerId = json['customerId'];
    category = json['category'];
    isActive = json['isActive'];
    pushToken = json['pushToken'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['restaurantName'] = restaurantName;
    data['customerId'] = customerId;
    data['category'] = category;
    data['isActive'] = isActive;
    data['pushToken'] = pushToken;
    return data;
  }
}


class ChatMessage {
  final String text;
  final String sender;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  bool get isUser => sender == 'user';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          sender == other.sender &&
          timestamp == other.timestamp;

  @override
  int get hashCode => text.hashCode ^ sender.hashCode ^ timestamp.hashCode;
}