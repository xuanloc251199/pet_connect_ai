class DiscoverTile {
  final int postId;
  final String imageUrl;
  final bool hasMultiple;

  DiscoverTile({
    required this.postId,
    required this.imageUrl,
    this.hasMultiple = false,
  });
}
