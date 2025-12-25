// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../app/theme/app_colors.dart';
// import '../model/post_item.dart';
// import '../vc/posts_providers.dart';

// class PostDetailPage extends ConsumerStatefulWidget {
//   const PostDetailPage({super.key, required this.postId});

//   final int postId;

//   @override
//   ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
// }

// class _PostDetailPageState extends ConsumerState<PostDetailPage> {
//   PostItem? _post;
//   String? _error;
//   bool _loading = true;
//   int _index = 0;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(_load);
//   }

//   Future<void> _load() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       final api = ref.read(postsApiProvider);
//       final p = await api.getPostDetail(widget.postId);
//       if (!mounted) return;
//       setState(() {
//         _post = p;
//         _loading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _error = e.toString();
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(title: const Text('Post')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : (_error != null)
//           ? _errorView()
//           : _content(),
//     );
//   }

//   Widget _errorView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(_error!, style: const TextStyle(color: Colors.red)),
//             const SizedBox(height: 12),
//             ElevatedButton(onPressed: _load, child: const Text('Retry')),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _content() {
//     final p = _post!;
//     return SingleChildScrollView(
//       child: Column(children: [_header(p), _carousel(p), _text(p), _actions()]),
//     );
//   }

//   Widget _header(PostItem p) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 18,
//             backgroundColor: AppColors.border,
//             backgroundImage:
//                 (p.user.avatar != null && p.user.avatar!.isNotEmpty)
//                 ? NetworkImage(p.user.avatar!)
//                 : null,
//             child: (p.user.avatar == null || p.user.avatar!.isEmpty)
//                 ? const Icon(Icons.person, color: AppColors.textMuted)
//                 : null,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   p.user.name,
//                   style: const TextStyle(fontWeight: FontWeight.w800),
//                 ),
//                 if ((p.user.username ?? '').isNotEmpty)
//                   Text(
//                     '@${p.user.username}',
//                     style: const TextStyle(color: AppColors.textSecondary),
//                   ),
//               ],
//             ),
//           ),
//           const Icon(Icons.more_horiz, color: AppColors.textMuted),
//         ],
//       ),
//     );
//   }

//   Widget _carousel(PostItem p) {
//     if (p.images.isEmpty) return const SizedBox.shrink();

//     return Column(
//       children: [
//         SizedBox(
//           height: 360,
//           child: PageView.builder(
//             itemCount: p.images.length,
//             onPageChanged: (i) => setState(() => _index = i),
//             itemBuilder: (_, i) => Image.network(
//               p.images[i].url,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//         if (p.images.length > 1)
//           Padding(
//             padding: const EdgeInsets.only(top: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(p.images.length, (i) {
//                 final active = i == _index;
//                 return AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   margin: const EdgeInsets.symmetric(horizontal: 3),
//                   width: active ? 18 : 7,
//                   height: 7,
//                   decoration: BoxDecoration(
//                     color: active ? AppColors.primary : AppColors.border,
//                     borderRadius: BorderRadius.circular(99),
//                   ),
//                 );
//               }),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _text(PostItem p) {
//     final text = (p.content ?? '').trim();
//     if (text.isEmpty) return const SizedBox.shrink();

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
//       child: Align(
//         alignment: Alignment.centerLeft,
//         child: Text(text, style: const TextStyle(fontSize: 15)),
//       ),
//     );
//   }

//   Widget _actions() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
//       child: Row(
//         children: [
//           _iconBtn(Icons.favorite_border, 'Like', () {}),
//           const SizedBox(width: 10),
//           _iconBtn(Icons.mode_comment_outlined, 'Comment', () {}),
//           const Spacer(),
//           _iconBtn(Icons.bookmark_border, 'Save', () {}),
//         ],
//       ),
//     );
//   }

//   Widget _iconBtn(IconData icon, String label, VoidCallback onTap) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(12),
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         child: Row(
//           children: [
//             Icon(icon, color: AppColors.textPrimary),
//             const SizedBox(width: 6),
//             Text(label),
//           ],
//         ),
//       ),
//     );
//   }
// }
