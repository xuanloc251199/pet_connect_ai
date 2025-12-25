class PostUser {
  final int id;
  final String name;
  final String? username;
  final String? avatar;

  PostUser({required this.id, required this.name, this.username, this.avatar});

  factory PostUser.fromJson(Map<String, dynamic> json) => PostUser(
    id: (json['id'] as num).toInt(),
    name: (json['name'] ?? '').toString(),
    username: json['username']?.toString(),
    avatar: json['avatar']?.toString(),
  );
}

class PostImageItem {
  final String url;
  final int order;

  PostImageItem({required this.url, required this.order});

  factory PostImageItem.fromJson(Map<String, dynamic> json) => PostImageItem(
    url: (json['url'] ?? '').toString(),
    order: (json['order'] as num?)?.toInt() ?? 0,
  );
}

class PostItem {
  final int id;
  final PostUser user;
  final String? content;
  final List<PostImageItem> images;
  final int imagesCount;
  final String? createdAt;

  PostItem({
    required this.id,
    required this.user,
    this.content,
    required this.images,
    required this.imagesCount,
    this.createdAt,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) {
    final imgs =
        (json['images'] as List? ?? const [])
            .map(
              (e) => PostImageItem.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return PostItem(
      id: (json['id'] as num).toInt(),
      user: PostUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
      content: json['content']?.toString(),
      images: imgs,
      imagesCount: (json['images_count'] as num?)?.toInt() ?? imgs.length,
      createdAt: json['created_at']?.toString(),
    );
  }
}
