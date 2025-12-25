import 'discover_tile.dart';

class DiscoverParser {
  static List<DiscoverTile> parseFromFeedResponse(dynamic resData) {
    // Expect {success, data: ...}
    final root = (resData is Map) ? resData : {};
    final data = root['data'];

    List<dynamic> list;
    if (data is Map && data['data'] is List) {
      // Paginate: data.data
      list = data['data'] as List;
    } else if (data is List) {
      list = data;
    } else {
      list = const [];
    }

    final tiles = <DiscoverTile>[];
    for (final item in list) {
      if (item is! Map) continue;

      final postId = _asInt(item['id']) ?? 0;

      final images = _extractImages(item);
      if (images.isEmpty) continue;

      tiles.add(
        DiscoverTile(
          postId: postId,
          imageUrl: images.first,
          hasMultiple: images.length > 1,
        ),
      );
    }
    return tiles;
  }

  static int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v');

  static List<String> _extractImages(Map item) {
    // Try many common keys
    final candidates = <dynamic>[
      item['images'],
      item['post_images'],
      item['media'],
      item['attachments'],
    ];

    for (final c in candidates) {
      final urls = _urlsFromAny(c);
      if (urls.isNotEmpty) return urls;
    }

    // single image fallback
    final singleKeys = [
      'image_url',
      'thumbnail',
      'cover_url',
      'cover',
      'avatar',
      'url',
    ];
    for (final k in singleKeys) {
      final v = item[k];
      if (v is String && v.trim().isNotEmpty) return [v.trim()];
    }

    return const [];
  }

  static List<String> _urlsFromAny(dynamic v) {
    if (v is List) {
      if (v.isNotEmpty && v.first is Map) {
        final items = v
            .whereType<Map>()
            .map(
              (e) => {
                'url':
                    (e['url'] ?? e['image_url'] ?? e['imageUrl'] ?? e['path'])
                        ?.toString(),
                'order': (e['order'] ?? e['order_index'] ?? 0),
              },
            )
            .where((e) => (e['url'] ?? '').toString().trim().isNotEmpty)
            .toList();

        items.sort((a, b) {
          final ao = (a['order'] is num)
              ? (a['order'] as num).toInt()
              : int.tryParse('${a['order']}') ?? 0;
          final bo = (b['order'] is num)
              ? (b['order'] as num).toInt()
              : int.tryParse('${b['order']}') ?? 0;
          return ao.compareTo(bo);
        });

        return items.map((e) => e['url']!.toString().trim()).toList();
      }

      final out = <String>[];
      for (final e in v) {
        if (e is String && e.trim().isNotEmpty) out.add(e.trim());
      }
      return out;
    }
    return const [];
  }
}
