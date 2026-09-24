import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pet_trail/data/services/chat_service.dart';
import 'package:pet_trail/domain/models/chat_message.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required String chatBaseUrl,
    required String token,
    required this.tourId,
    required this.currentUserId,
  }) : _service = ChatService(chatBaseUrl: chatBaseUrl, token: token) {
    _subscribe();
    _service.connect();
  }

  final ChatService _service;
  final String tourId;
  final String currentUserId;

  bool _isDisposed = false;
  bool _connected = false;
  String? _errorMessage;
  final List<ChatMessage> _messages = [];
  final List<ChatMessage> _pending = [];
  int _unreadCount = 0;
  bool _chatOpen = false;

  bool get connected => _connected;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;
  List<ChatMessage> get messages => List.unmodifiable([..._pending, ..._messages]
    ..sort((a, b) => a.sentAt.compareTo(b.sentAt)));

  late final StreamSubscription<bool> _connSub;
  late final StreamSubscription<ChatMessage> _newMsgSub;
  late final StreamSubscription<MessageAck> _ackSub;
  late final StreamSubscription<List<ChatMessage>> _missedSub;
  late final StreamSubscription<ChatError> _errorSub;
  late final StreamSubscription<String> _closedSub;

  void _subscribe() {
    _connSub = _service.onConnectionChange.listen(_onConnectionChange);
    _newMsgSub = _service.onNewMessage.listen(_onNewMessage);
    _ackSub = _service.onMessageAck.listen(_onAck);
    _missedSub = _service.onMissedMessages.listen(_onMissed);
    _errorSub = _service.onError.listen(_onError);
    _closedSub = _service.onChatClosed.listen(_onClosed);
  }

  void _onConnectionChange(bool connected) {
    _connected = connected;
    if (connected) {
      final lastId = _messages.isNotEmpty ? _messages.last.identifier : null;
      _service.joinTour(tourId, lastReceivedId: lastId);
      _retryPending();
    }
    _notify();
  }

  void _retryPending() {
    for (final msg in List.of(_pending)) {
      _service.sendMessage(tourId, msg.content, msg.clientTempId!);
    }
  }

  void _onNewMessage(ChatMessage msg) {
    // Remove pending whose ack already assigned the same real identifier.
    _pending.removeWhere((p) => p.identifier == msg.identifier);
    if (!_messages.any((m) => m.identifier == msg.identifier)) {
      _messages.add(msg);
      if (msg.senderId != currentUserId && !_chatOpen) {
        _unreadCount++;
      }
    }
    _notify();
  }

  void _onAck(MessageAck ack) {
    final idx = _pending.indexWhere((p) => p.clientTempId == ack.clientTempId);
    if (idx != -1) {
      final confirmed = _pending[idx].copyWith(
        identifier: ack.identifier,
        isPending: false,
        // Use server-authoritative timestamp so sort order is consistent
        // with received messages regardless of device clock skew.
        sentAt: ack.sentAt,
      );
      _pending.removeAt(idx);
      if (!_messages.any((m) => m.identifier == confirmed.identifier)) {
        _messages.add(confirmed);
      }
    }
    _notify();
  }

  void _onMissed(List<ChatMessage> msgs) {
    for (final msg in msgs) {
      if (!_messages.any((m) => m.identifier == msg.identifier)) {
        _messages.add(msg);
      }
    }
    _notify();
  }

  void _onError(ChatError error) {
    _errorMessage = error.message;
    _notify();
  }

  void _onClosed(String closedTourId) {
    _errorMessage = 'Chat encerrado';
    _notify();
  }

  DateTime _pendingSentAt() {
    final now = DateTime.now();
    final all = [..._pending, ..._messages];
    if (all.isEmpty) return now;
    final latest = all.map((m) => m.sentAt).reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.isAfter(now) ? latest.add(const Duration(milliseconds: 1)) : now;
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;
    final tempId =
        '${DateTime.now().microsecondsSinceEpoch}_${_pending.length}';
    final pending = ChatMessage(
      identifier: tempId,
      clientTempId: tempId,
      tourId: tourId,
      senderId: currentUserId,
      content: content.trim(),
      sentAt: _pendingSentAt(),
      isPending: true,
    );
    _pending.add(pending);
    _notify();

    if (_connected) {
      _service.sendMessage(tourId, content.trim(), tempId);
    }
  }

  String? consumeError() {
    final err = _errorMessage;
    _errorMessage = null;
    return err;
  }

  void setChatOpen(bool open) {
    _chatOpen = open;
    if (open) resetUnread();
  }

  void resetUnread() {
    _unreadCount = 0;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connSub.cancel();
    _newMsgSub.cancel();
    _ackSub.cancel();
    _missedSub.cancel();
    _errorSub.cancel();
    _closedSub.cancel();
    _service.dispose();
    super.dispose();
  }
}
