import 'package:flutter/foundation.dart';
import 'package:witt_ai/witt_ai.dart';

export 'package:witt_ai/witt_ai.dart' show SageMode, AiMessage;

@immutable
class SageConversation {
  const SageConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<AiMessage> messages;
  final SageMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;

  SageConversation copyWith({
    String? id,
    String? title,
    List<AiMessage>? messages,
    SageMode? mode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SageConversation(
        id: id ?? this.id,
        title: title ?? this.title,
        messages: messages ?? this.messages,
        mode: mode ?? this.mode,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static SageConversation create({SageMode mode = SageMode.chat}) {
    final now = DateTime.now();
    return SageConversation(
      id: 'conv_${now.millisecondsSinceEpoch}',
      title: 'New conversation',
      messages: const [],
      mode: mode,
      createdAt: now,
      updatedAt: now,
    );
  }
}

@immutable
class SageSessionState {
  const SageSessionState({
    required this.conversation,
    required this.isStreaming,
    required this.streamingContent,
    required this.mode,
    this.error,
    this.limitMessage,
  });

  final SageConversation conversation;
  final bool isStreaming;
  final String streamingContent;
  final SageMode mode;
  final String? error;
  final String? limitMessage;

  List<AiMessage> get messages => conversation.messages;

  SageSessionState copyWith({
    SageConversation? conversation,
    bool? isStreaming,
    String? streamingContent,
    SageMode? mode,
    String? error,
    String? limitMessage,
  }) =>
      SageSessionState(
        conversation: conversation ?? this.conversation,
        isStreaming: isStreaming ?? this.isStreaming,
        streamingContent: streamingContent ?? this.streamingContent,
        mode: mode ?? this.mode,
        error: error,
        limitMessage: limitMessage,
      );

  static SageSessionState initial() => SageSessionState(
        conversation: SageConversation.create(),
        isStreaming: false,
        streamingContent: '',
        mode: SageMode.chat,
      );
}
