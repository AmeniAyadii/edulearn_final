class ConversationSession {
  final String id;
  String title;
  final DateTime createdAt;
  List<Message> messages;
  
  ConversationSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };
  
  factory ConversationSession.fromJson(Map<String, dynamic> json) => ConversationSession(
    id: json['id'],
    title: json['title'],
    createdAt: DateTime.parse(json['createdAt']),
    messages: (json['messages'] as List)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList(),
  );
}

class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  String? detectedLanguage;
  Map<String, dynamic>? sentiment;
  double? confidence;
  List<String>? alternativeReplies;
  
  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.detectedLanguage,
    this.sentiment,
    this.confidence,
    this.alternativeReplies,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'detectedLanguage': detectedLanguage,
    'sentiment': sentiment,
    'confidence': confidence,
    'alternativeReplies': alternativeReplies,
  };
  
  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    detectedLanguage: json['detectedLanguage'],
    sentiment: json['sentiment'],
    confidence: json['confidence'],
    alternativeReplies: json['alternativeReplies']?.cast<String>(),
  );
}