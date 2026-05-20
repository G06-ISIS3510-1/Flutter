enum HelpFeedbackVote { upvote, downvote }

extension HelpFeedbackVoteX on HelpFeedbackVote {
  String get storageValue => switch (this) {
    HelpFeedbackVote.upvote => 'upvote',
    HelpFeedbackVote.downvote => 'downvote',
  };

  bool get isUpvote => this == HelpFeedbackVote.upvote;
  bool get isDownvote => this == HelpFeedbackVote.downvote;
}

HelpFeedbackVote helpFeedbackVoteFromStorage(String? rawValue) {
  switch (rawValue?.trim().toLowerCase()) {
    case 'downvote':
      return HelpFeedbackVote.downvote;
    case 'upvote':
    default:
      return HelpFeedbackVote.upvote;
  }
}

class HelpFeedback {
  const HelpFeedback({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.vote,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String articleId;
  final String userId;
  final HelpFeedbackVote vote;
  final DateTime createdAt;
  final String? note;
}

class HelpBookmark {
  const HelpBookmark({
    required this.articleId,
    required this.userId,
    required this.savedAt,
    required this.pendingSync,
  });

  final String articleId;
  final String userId;
  final DateTime savedAt;
  final bool pendingSync;
}
