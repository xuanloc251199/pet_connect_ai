import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/vc/auth_providers.dart';
import '../model/feed_api.dart';
import '../model/feed_models.dart';
import '../vc/feed_vc.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId, this.initialPost});

  final int postId;
  final FeedPost? initialPost;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  FeedApi get _api => FeedApi(ref.read(apiClientProvider));

  final _commentCtl = TextEditingController();
  final _scrollCtl = ScrollController();

  FeedPost? _post;
  bool _loadingPost = false;
  String? _postErr;

  List<FeedComment> _comments = [];
  bool _loadingComments = true;
  String? _commentsErr;

  bool _sending = false;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    _commentsCount = widget.initialPost?.comments ?? 0;

    if (_post == null) _loadPost();
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    setState(() {
      _loadingPost = true;
      _postErr = null;
    });

    try {
      final res = await _api.fetchPostDetail(widget.postId);
      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};

      final p = FeedPost.fromApi(data);
      setState(() {
        _post = p;
        _commentsCount = p.comments;
        _loadingPost = false;
      });
    } catch (e) {
      setState(() {
        _loadingPost = false;
        _postErr = e.toString();
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentsErr = null;
    });

    try {
      final res = await _api.fetchComments(
        postId: widget.postId,
        page: 1,
        perPage: 50,
      );

      final data = res['data'];
      final paginator = (data is Map && data['data'] is List)
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};

      final list = (paginator['data'] as List? ?? const []);
      final parsed = list
          .map((e) => FeedComment.fromApi(Map<String, dynamic>.from(e as Map)))
          .toList();

      setState(() {
        _comments = parsed;
        _loadingComments = false;
      });
    } catch (e) {
      setState(() {
        _loadingComments = false;
        _commentsErr = e.toString();
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _commentsErr = null;
    });

    try {
      final res = await _api.addComment(postId: widget.postId, content: text);
      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};

      final cRaw = data['comment'];
      if (cRaw is Map) {
        final c = FeedComment.fromApi(Map<String, dynamic>.from(cRaw));
        setState(() => _comments = [c, ..._comments]);
      }

      final cc = (data['comments_count'] as num?)?.toInt();
      if (cc != null) {
        setState(() => _commentsCount = cc);
        ref
            .read(feedVCProvider.notifier)
            .updateCommentsCount(widget.postId, cc);
      } else {
        setState(() => _commentsCount = _commentsCount + 1);
        ref
            .read(feedVCProvider.notifier)
            .updateCommentsCount(widget.postId, _commentsCount);
      }

      _commentCtl.clear();

      // prepend comment mới lên đầu -> scroll lên top thấy ngay
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() => _commentsErr = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleLike() async {
    await ref.read(feedVCProvider.notifier).toggleLike(widget.postId);

    // sync lại post từ feed state (nếu có)
    final st = ref.read(feedVCProvider);
    final idx = st.posts.indexWhere((p) => p.id == widget.postId);
    if (idx >= 0) {
      setState(() => _post = st.posts[idx]);
    } else {
      _loadPost();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _post;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        title: const Text(
          'Post',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight, // ✅ ép height rõ ràng
              child: Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      controller: _scrollCtl,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: _buildPostSection(p),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                            child: Row(
                              children: [
                                const Text(
                                  'Comments',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$_commentsCount',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_loadingComments)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        else if (_commentsErr != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                _commentsErr!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          )
                        else if (_comments.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: Text(
                                'No comments yet.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList.separated(
                            itemCount: _comments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: _CommentTile(c: _comments[i]),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      ],
                    ),
                  ),

                  // ✅ input ghim dưới (không bottomNavigationBar)
                  _InputBar(
                    controller: _commentCtl,
                    sending: _sending,
                    onSend: _sendComment,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostSection(FeedPost? p) {
    if (p == null) {
      if (_loadingPost) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_postErr != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_postErr!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadPost, child: const Text('Retry')),
          ],
        );
      }
      return const Text(
        'Post not found.',
        style: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PostHeader(p: p),
        const SizedBox(height: 10),
        _PostBody(p: p),
        const SizedBox(height: 10),
        _PostActions(p: p, commentsCount: _commentsCount, onLike: _toggleLike),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity, // ✅ ép width
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, -4),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write a comment…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: sending ? null : onSend,
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.p});
  final FeedPost p;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primarySoft,
          backgroundImage:
              (p.avatarUrl != null && p.avatarUrl!.trim().isNotEmpty)
              ? NetworkImage(p.avatarUrl!)
              : null,
          child: (p.avatarUrl == null || p.avatarUrl!.trim().isEmpty)
              ? const Icon(Icons.person, color: AppColors.primary, size: 18)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            p.userName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({required this.p});
  final FeedPost p;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.content.trim().isNotEmpty)
          Text(
            p.content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (p.images.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: PageView.builder(
                itemCount: p.images.length,
                itemBuilder: (_, i) =>
                    Image.network(p.images[i], fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.p,
    required this.commentsCount,
    required this.onLike,
  });

  final FeedPost p;
  final int commentsCount;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onLike,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: SvgPicture.asset(
              'assets/icons/ic_heart.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                p.isLiked ? Colors.red : AppColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${p.likes} likes • $commentsCount comments',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.c});
  final FeedComment c;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primarySoft,
          backgroundImage:
              (c.avatarUrl != null && c.avatarUrl!.trim().isNotEmpty)
              ? NetworkImage(c.avatarUrl!)
              : null,
          child: (c.avatarUrl == null || c.avatarUrl!.trim().isEmpty)
              ? const Icon(Icons.person, color: AppColors.primary, size: 18)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.content,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
