import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_connect_ai/app/theme/app_images.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/select_chip.dart';
import '../vc/interests_vc.dart';

class InterestsPage extends ConsumerStatefulWidget {
  const InterestsPage({super.key});

  @override
  ConsumerState<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends ConsumerState<InterestsPage> {
  ProviderSubscription<InterestsState>? _sub;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // ✅ listen 1 lần để show error thân thiện
    _sub = ref.listenManual(interestsVCProvider, (prev, next) {
      if (!mounted) return;
      if (next.error != null && next.error != prev?.error) {
        _toast(next.error!);
      }
    });

    Future.microtask(() => ref.read(interestsVCProvider.notifier).load());
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(interestsVCProvider);
    final vc = ref.read(interestsVCProvider.notifier);

    Widget section(String title, List<(int id, String name)> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map(
                  (it) => SelectChip(
                    text: it.$2,
                    selected: st.selectedIds.contains(it.$1),
                    enabled: !st.loading,
                    onTap: () => vc.toggleInterestId(it.$1),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

    final isLoadingFirst = st.categories.isEmpty && st.loading;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Image.asset(AppImages.logoText, height: 24)],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We wanna get to know you!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select your interests for a personalized experience!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Do you have a pet?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Checkbox(
                  value: st.hasPet,
                  onChanged: st.loading
                      ? null
                      : (v) => vc.toggleHasPet(v ?? false),
                ),
              ],
            ),

            if (isLoadingFirst)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (st.categories.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Không tải được danh mục sở thích. Bạn thử lại nhé.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: st.loading ? null : () => vc.load(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...st.categories.map((cat) {
                final catMap = cat as Map<String, dynamic>;

                final catName = (catMap['name'] ?? '').toString();
                final interests = (catMap['interests'] as List? ?? const []);

                final items = interests.map((i) {
                  final m = i as Map<String, dynamic>;
                  final id = (m['id'] as num).toInt();
                  final name = (m['name'] ?? '').toString();
                  return (id, name);
                }).toList();

                return section(catName, items);
              }),

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: st.loading
                    ? null
                    : () async {
                        final ok = await vc.submit();
                        if (!context.mounted) return;

                        if (ok) {
                          _toast('Đã lưu sở thích!');
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (r) => false,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: st.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
