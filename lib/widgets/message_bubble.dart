import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'audio_message_player.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final MessageModel? replyMessage;
  final VoidCallback onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onLongPress,
    this.replyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isMine 
        ? AppColors.bubbleSent 
        : (isDark ? AppColors.bubbleReceivedDark : AppColors.bubbleReceived);
    final fgColor = isMine 
        ? Colors.white 
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    // Group reactions by emoji
    final List<Widget> reactionChips = [];
    if (message.reactions.isNotEmpty) {
      message.reactions.forEach((emoji, users) {
        if (users.isNotEmpty) {
          reactionChips.add(
            Container(
              margin: const EdgeInsets.only(right: 4, top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 12)),
                  if (users.length > 1) ...[
                    const SizedBox(width: 2),
                    Text('${users.length}', style: TextStyle(fontSize: 10, color: fgColor)),
                  ]
                ],
              ),
            ),
          );
        }
      });
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.lg),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppSpacing.radiusLg),
                    topRight: const Radius.circular(AppSpacing.radiusLg),
                    bottomLeft: Radius.circular(isMine ? AppSpacing.radiusLg : 4),
                    bottomRight: Radius.circular(isMine ? 4 : AppSpacing.radiusLg),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reply Preview
                      if (replyMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border(
                              left: BorderSide(
                                color: isMine ? Colors.white : theme.colorScheme.primary,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replyMessage!.senderName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isMine ? Colors.white : theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getPreviewText(replyMessage!),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: fgColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Media Content
                      if (message.mediaType == MediaType.image && message.mediaUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: _buildImage(message.mediaUrl!),
                        ),
                        
                      if (message.mediaType == MediaType.audio && message.mediaUrl != null)
                        Container(
                          width: 200,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: AudioMessagePlayer(
                            audioUrl: message.mediaUrl!,
                            isMine: isMine,
                          ),
                        ),

                      // Text Content
                      if (message.text.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            left: 8, right: 8,
                            top: message.mediaType != MediaType.none ? 8 : 4,
                            bottom: 16, // Space for timestamp
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(color: fgColor, fontSize: 16),
                          ),
                        ),
                        
                      if (message.text.isEmpty && message.mediaType != MediaType.none)
                        const SizedBox(height: 16), // Space for timestamp if no text
                    ],
                  ),
                ),
              ),

              // Timestamp and Read Status
              Positioned(
                bottom: 8,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.timestamp != null ? DateFormat('HH:mm').format(message.timestamp!) : '',
                      style: TextStyle(
                        color: fgColor.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    if (message.isEdited) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(edited)',
                        style: TextStyle(
                          color: fgColor.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.read ? Icons.done_all : Icons.check,
                        size: 14,
                        color: message.read ? Colors.blue : fgColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
              ),

              // Reactions
              if (reactionChips.isNotEmpty)
                Positioned(
                  bottom: -10,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: reactionChips,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPreviewText(MessageModel msg) {
    if (msg.text.isNotEmpty) return msg.text;
    if (msg.mediaType == MediaType.image) return '📷 Photo';
    if (msg.mediaType == MediaType.audio) return '🎵 Voice note';
    return 'Message';
  }

  Widget _buildImage(String data) {
    try {
      if (data.startsWith('http')) {
        return Image.network(data, fit: BoxFit.cover);
      } else {
        return Image.memory(base64Decode(data), fit: BoxFit.cover);
      }
    } catch (e) {
      return Container(
        height: 200,
        color: Colors.grey.withValues(alpha: 0.2),
        child: const Center(child: Icon(Icons.broken_image, size: 40)),
      );
    }
  }
}
