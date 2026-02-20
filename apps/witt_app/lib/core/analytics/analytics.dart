/// Centralised analytics event logger for Phase 4 features.
/// Wraps Bootstrap.track() so all events are consistent and easy to audit.
library;

import '../../app/bootstrap.dart';

class Analytics {
  Analytics._();

  // ── Social ─────────────────────────────────────────────────────────────

  static void joinGroup(String groupId, String groupName) =>
      Bootstrap.track('social_group_join', properties: {
        'group_id': groupId,
        'group_name': groupName,
      });

  static void leaveGroup(String groupId) =>
      Bootstrap.track('social_group_leave', properties: {
        'group_id': groupId,
      });

  static void createPost(String postType, List<String> tags) =>
      Bootstrap.track('social_post_create', properties: {
        'post_type': postType,
        'tags': tags.join(','),
      });

  static void likePost(String postId, bool liked) =>
      Bootstrap.track('social_post_like', properties: {
        'post_id': postId,
        'liked': liked,
      });

  static void upvoteQuestion(String questionId, bool upvoted) =>
      Bootstrap.track('social_question_upvote', properties: {
        'question_id': questionId,
        'upvoted': upvoted,
      });

  static void downloadDeck(String deckId, String deckTitle) =>
      Bootstrap.track('marketplace_deck_download', properties: {
        'deck_id': deckId,
        'deck_title': deckTitle,
      });

  // ── Games ──────────────────────────────────────────────────────────────

  static void launchGame(String gameId, String gameTitle, bool isPaid) =>
      Bootstrap.track('game_launch', properties: {
        'game_id': gameId,
        'game_title': gameTitle,
        'is_paid_game': isPaid,
      });

  static void completeGame(String gameId, int score, bool isComplete) =>
      Bootstrap.track('game_complete', properties: {
        'game_id': gameId,
        'score': score,
        'completed': isComplete,
      });

  static void completeChallenge(String challengeId, int xpReward) =>
      Bootstrap.track('brain_challenge_complete', properties: {
        'challenge_id': challengeId,
        'xp_reward': xpReward,
      });

  static void hitGameLimit() =>
      Bootstrap.track('game_limit_hit');

  // ── Translation ────────────────────────────────────────────────────────

  static void translate(String sourceLang, String targetLang, bool isOffline) =>
      Bootstrap.track('translation_performed', properties: {
        'source_lang': sourceLang,
        'target_lang': targetLang,
        'offline': isOffline,
      });

  static void downloadOfflinePack(String langCode) =>
      Bootstrap.track('translation_offline_pack_download', properties: {
        'lang_code': langCode,
      });

  // ── Teacher portal ─────────────────────────────────────────────────────

  static void viewClass(String classId) =>
      Bootstrap.track('teacher_view_class', properties: {
        'class_id': classId,
      });

  static void createAssignment(String classId, String title) =>
      Bootstrap.track('teacher_create_assignment', properties: {
        'class_id': classId,
        'title': title,
      });

  // ── Parent portal ──────────────────────────────────────────────────────

  static void linkChild(String childCode) =>
      Bootstrap.track('parent_link_child', properties: {
        'child_code': childCode,
      });

  static void viewChildProgress(String childId) =>
      Bootstrap.track('parent_view_child_progress', properties: {
        'child_id': childId,
      });

  // ── Content moderation ─────────────────────────────────────────────────

  static void reportContent(String contentType, String contentId, String reason) =>
      Bootstrap.track('content_report', properties: {
        'content_type': contentType,
        'content_id': contentId,
        'reason': reason,
      });
}
