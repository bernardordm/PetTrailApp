import 'package:flutter/material.dart';
import 'package:pet_trail/domain/models/chat_message.dart';
import 'package:pet_trail/presentation/controllers/chat_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.controller,
    required this.currentUserId,
    required this.counterpartName,
  });

  final ChatController controller;
  final String currentUserId;
  final String counterpartName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.setChatOpen(true);
    _controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final err = _controller.consumeError();
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _controller.sendMessage(text);
    _textController.clear();
  }

  @override
  void dispose() {
    _controller.setChatOpen(false);
    _controller.removeListener(_onUpdate);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.counterpartName),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _controller.connected ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _controller.connected ? 'Conectado' : 'Reconectando…',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _controller.messages.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma mensagem ainda.\nDiga olá!',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: _controller.messages.length,
                    itemBuilder: (context, index) {
                      final msg = _controller.messages[index];
                      return _MessageBubble(
                        message: msg,
                        isMine: msg.senderId == widget.currentUserId,
                        cs: cs,
                        tt: tt,
                      );
                    },
                  ),
          ),
          _InputBar(
            controller: _textController,
            onSend: _send,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.cs,
    required this.tt,
  });

  final ChatMessage message;
  final bool isMine;
  final ColorScheme cs;
  final TextTheme tt;

  Color _receivedBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.sentAt.toLocal());
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine ? cs.secondary : _receivedBg(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: tt.bodyMedium?.copyWith(
                color: isMine ? cs.onSecondary : cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: tt.bodySmall?.copyWith(
                    color: isMine
                        ? cs.onSecondary.withValues(alpha: 0.7)
                        : cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isPending ? Icons.access_time : Icons.done,
                    size: 12,
                    color: cs.onSecondary.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.cs,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Digite uma mensagem…',
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
