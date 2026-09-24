import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:pet_trail/domain/models/chat_message.dart';

class ChatService {
  ChatService({required String chatBaseUrl, required String token}) {
    _socket = io.io(
      chatBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );
    _setupListeners();
  }

  late final io.Socket _socket;

  final _newMessageController =
      StreamController<ChatMessage>.broadcast();
  final _ackController = StreamController<MessageAck>.broadcast();
  final _missedController =
      StreamController<List<ChatMessage>>.broadcast();
  final _errorController = StreamController<ChatError>.broadcast();
  final _closedController = StreamController<String>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();

  Stream<ChatMessage> get onNewMessage => _newMessageController.stream;
  Stream<MessageAck> get onMessageAck => _ackController.stream;
  Stream<List<ChatMessage>> get onMissedMessages => _missedController.stream;
  Stream<ChatError> get onError => _errorController.stream;
  Stream<String> get onChatClosed => _closedController.stream;
  Stream<bool> get onConnectionChange => _connectedController.stream;

  bool get isConnected => _socket.connected;

  void _setupListeners() {
    _socket.onConnect((_) => _connectedController.add(true));
    _socket.onDisconnect((_) => _connectedController.add(false));

    _socket.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        _newMessageController.add(ChatMessage.fromJson(data));
      }
    });

    _socket.on('message_ack', (data) {
      if (data is Map<String, dynamic>) {
        _ackController.add(MessageAck.fromJson(data));
      }
    });

    _socket.on('missed_messages', (data) {
      if (data is Map<String, dynamic>) {
        final list = (data['messages'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ChatMessage.fromJson)
            .toList();
        _missedController.add(list);
      }
    });

    _socket.on('message_error', (data) {
      if (data is Map<String, dynamic>) {
        _errorController.add(ChatError.fromJson(data));
      }
    });

    _socket.on('chat_closed', (data) {
      if (data is Map<String, dynamic>) {
        _closedController.add(data['tour_id'] as String);
      }
    });

    _socket.on('auth_error', (data) {
      _errorController.add(
        ChatError(
          code: 'AUTH_ERROR',
          message: (data is Map ? data['message'] as String? : null) ??
              'Erro de autenticação',
        ),
      );
    });
  }

  void connect() => _socket.connect();

  void joinTour(String tourId, {String? lastReceivedId}) {
    _socket.emit('join_tour', {
      'tour_id': tourId,
      if (lastReceivedId != null) 'last_received_id': lastReceivedId,
    });
  }

  void sendMessage(String tourId, String content, String clientTempId) {
    _socket.emit('send_message', {
      'tour_id': tourId,
      'content': content,
      'client_temp_id': clientTempId,
    });
  }

  void dispose() {
    _socket.dispose();
    _newMessageController.close();
    _ackController.close();
    _missedController.close();
    _errorController.close();
    _closedController.close();
    _connectedController.close();
  }
}
