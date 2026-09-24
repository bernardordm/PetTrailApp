class ChatMessage {
  const ChatMessage({
    required this.identifier,
    this.clientTempId,
    required this.tourId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isPending = false,
  });

  final String identifier;
  final String? clientTempId;
  final String tourId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final bool isPending;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        identifier: json['identifier'] as String,
        tourId: json['tour_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );

  ChatMessage copyWith({
    String? identifier,
    bool? isPending,
    String? clientTempId,
    DateTime? sentAt,
  }) =>
      ChatMessage(
        identifier: identifier ?? this.identifier,
        clientTempId: clientTempId ?? this.clientTempId,
        tourId: tourId,
        senderId: senderId,
        content: content,
        sentAt: sentAt ?? this.sentAt,
        isPending: isPending ?? this.isPending,
      );
}

class MessageAck {
  const MessageAck({
    required this.clientTempId,
    required this.identifier,
    required this.sentAt,
  });

  final String clientTempId;
  final String identifier;
  final DateTime sentAt;

  factory MessageAck.fromJson(Map<String, dynamic> json) => MessageAck(
        clientTempId: json['client_temp_id'] as String,
        identifier: json['identifier'] as String,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );
}

class ChatError {
  const ChatError({required this.code, required this.message});

  final String code;
  final String message;

  factory ChatError.fromJson(Map<String, dynamic> json) => ChatError(
        code: json['code'] as String,
        message: json['message'] as String,
      );
}
