class FeedPost {
  final int id;
  final String userName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final String content;
  final List<String> images;

  final int likes;
  final int comments;
  final bool isLiked;

  const FeedPost({
    required this.id,
    required this.userName,
    required this.avatarUrl,
    required this.createdAt,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
    required this.isLiked,
  });

  static FeedPost fromApi(Map<String, dynamic> post) {
    // user
    String userName = 'User';
    String? avatarUrl;

    final u = post['user'];
    if (u is Map) {
      userName = (u['username'] ?? u['name'] ?? 'User').toString();
      final a = u['avatar'] ?? u['avatar_url'] ?? u['photo'];
      avatarUrl = a == null ? null : a.toString();
    } else {
      userName = (post['username'] ?? post['user_name'] ?? 'User').toString();
      final a = post['avatar'] ?? post['avatar_url'];
      avatarUrl = a == null ? null : a.toString();
    }
    if (avatarUrl != null && avatarUrl!.trim().isEmpty) avatarUrl = null;

    // content
    final content = (post['content'] ?? post['caption'] ?? '').toString();

    // created_at
    DateTime? createdAt;
    final ca = post['created_at'] ?? post['createdAt'];
    if (ca != null) {
      try {
        createdAt = DateTime.parse(ca.toString());
      } catch (_) {}
    }

    // images
    final images = <String>[];
    final rawImages = post['images'];
    if (rawImages is List) {
      for (final it in rawImages) {
        if (it is String) {
          final s = it.trim();
          if (s.isNotEmpty) images.add(s);
        } else if (it is Map) {
          final url = (it['url'] ?? it['image_url'] ?? it['path'] ?? '')
              .toString()
              .trim();
          if (url.isNotEmpty) images.add(url);
        }
      }
    }

    final likes =
        (post['likes_count'] as num?)?.toInt() ??
        (post['likes'] as num?)?.toInt() ??
        0;

    final comments =
        (post['comments_count'] as num?)?.toInt() ??
        (post['comments'] as num?)?.toInt() ??
        0;

    final isLikedRaw = post['is_liked'] ?? post['liked'] ?? false;
    final isLiked = isLikedRaw == true || isLikedRaw == 1 || isLikedRaw == '1';

    return FeedPost(
      id: (post['id'] as num?)?.toInt() ?? 0,
      userName: userName,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      content: content,
      images: images,
      likes: likes,
      comments: comments,
      isLiked: isLiked,
    );
  }

  FeedPost copyWith({int? likes, int? comments, bool? isLiked}) {
    return FeedPost(
      id: id,
      userName: userName,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      content: content,
      images: images,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class FeedComment {
  final int id;
  final String userName;
  final String? avatarUrl;
  final String content;
  final DateTime? createdAt;

  const FeedComment({
    required this.id,
    required this.userName,
    required this.avatarUrl,
    required this.content,
    required this.createdAt,
  });

  static FeedComment fromApi(Map<String, dynamic> raw) {
    final u = raw['user'];
    String userName = 'User';
    String? avatar;
    if (u is Map) {
      userName = (u['username'] ?? u['name'] ?? 'User').toString();
      final a = u['avatar'] ?? u['avatar_url'];
      avatar = a == null ? null : a.toString();
    }

    DateTime? createdAt;
    final ca = raw['created_at'] ?? raw['createdAt'];
    if (ca != null) {
      try {
        createdAt = DateTime.parse(ca.toString());
      } catch (_) {}
    }

    return FeedComment(
      id: (raw['id'] as num?)?.toInt() ?? 0,
      userName: userName,
      avatarUrl: (avatar != null && avatar.trim().isEmpty) ? null : avatar,
      content: (raw['content'] ?? '').toString(),
      createdAt: createdAt,
    );
  }
}
