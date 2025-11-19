import 'package:flutter/material.dart';
import 'package:just_chat_app/models/message_model.dart';
import 'package:just_chat_app/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;
  final bool showTime;
  final String timeText;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    this.showTime = false,
    required this.timeText,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTime) ...[
          SizedBox(height: 16),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
        ] else
          SizedBox(height: 4),

        Row(
          mainAxisAlignment:
              isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMyMessage) ...[SizedBox(width: 8)],
            Flexible(
              child: GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isMyMessage
                            ? AppTheme.primaryColor
                            : AppTheme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(isMyMessage ? 20 : 4),
                      bottomRight: Radius.circular(isMyMessage ? 4 : 20),
                    ),
                    border:
                        isMyMessage
                            ? null
                            : Border.all(color: AppTheme.borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              isMyMessage
                                  ? Colors.white
                                  : AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (message.isEdited) ...[
                        SizedBox(height: 4),
                        Text(
                          '(edited)',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                isMyMessage
                                    ? Colors.white.withOpacity(0.7)
                                    : AppTheme.textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (isMyMessage) ...[SizedBox(width: 8), _buildMessageStatus()],
          ],
        ),
      ],
    );
  }

  Widget _buildMessageStatus() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Icon(
        message.isRead ? Icons.done_all : Icons.done,
        size: 16,
        color:
            message.isRead
                ? AppTheme.primaryColor
                : AppTheme.textSecondaryColor,
      ),
    );
  }
}
