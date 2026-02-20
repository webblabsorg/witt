/// OneSignal push notification trigger service.
///
/// Call the static methods at the appropriate action points to send
/// targeted push notifications to specific users.
library;

import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();

  /// Tag the current device with the user's ID so we can target them.
  static Future<void> identifyUser(String userId) async {
    OneSignal.login(userId);
  }

  /// Remove user identity on sign-out.
  static void clearUser() {
    OneSignal.logout();
  }

  // ── Social ────────────────────────────────────────────────────────────────

  /// Notify group members when a new post is created in a group they joined.
  /// [memberUserIds] — list of OneSignal external user IDs to notify.
  static Future<void> notifyGroupPost({
    required List<String> memberUserIds,
    required String groupName,
    required String authorName,
  }) async {
    if (memberUserIds.isEmpty) return;
    await _sendToUsers(
      userIds: memberUserIds,
      title: groupName,
      body: '$authorName posted in your group',
      data: {'type': 'group_post', 'group': groupName},
    );
  }

  /// Notify a user when they receive a friend request.
  static Future<void> notifyFriendRequest({
    required String targetUserId,
    required String fromName,
  }) async {
    await _sendToUsers(
      userIds: [targetUserId],
      title: 'New Friend Request',
      body: '$fromName wants to connect with you',
      data: {'type': 'friend_request'},
    );
  }

  // ── Games ─────────────────────────────────────────────────────────────────

  /// Notify a user when they receive a multiplayer game invite.
  static Future<void> notifyGameInvite({
    required String targetUserId,
    required String fromName,
    required String gameTitle,
    required String sessionId,
  }) async {
    await _sendToUsers(
      userIds: [targetUserId],
      title: 'Game Invite',
      body: '$fromName challenged you to $gameTitle!',
      data: {'type': 'game_invite', 'session_id': sessionId},
    );
  }

  // ── Teacher ───────────────────────────────────────────────────────────────

  /// Notify students when a new assignment is published.
  static Future<void> notifyAssignmentDue({
    required List<String> studentUserIds,
    required String assignmentTitle,
    required String className,
    required DateTime dueDate,
  }) async {
    if (studentUserIds.isEmpty) return;
    final dueDateStr = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    await _sendToUsers(
      userIds: studentUserIds,
      title: 'New Assignment — $className',
      body: '$assignmentTitle due $dueDateStr',
      data: {'type': 'assignment_due', 'class': className},
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// Resolves the Supabase user IDs of all members of a study group by name.
  /// Used to build the recipient list for group-post notifications.
  static Future<List<String>> resolveGroupMemberIds(String groupName) async {
    try {
      final rows =
          await Supabase.instance.client.rpc(
                'get_group_member_ids',
                params: {'p_group_name': groupName},
              )
              as List<dynamic>;
      return rows.map((r) => r.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Dispatches a push notification to [userIds] via the `send-notification`
  /// Supabase Edge Function, which calls the OneSignal REST API server-side.
  /// The OneSignal REST API Key is stored as a Supabase secret and never
  /// exposed in client code.
  static Future<void> _sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (userIds.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'userIds': userIds,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
    } catch (_) {
      // Non-fatal: notification delivery failure must not break app flow.
    }
  }
}
