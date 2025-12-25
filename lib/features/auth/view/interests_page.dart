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
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(interestsVCProvider.notifier).load();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Load interests failed')));
      }
    });
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
                    onTap: () => vc.toggleInterestId(it.$1),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

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
                  onChanged: (v) => vc.toggleHasPet(v ?? true),
                ),
              ],
            ),

            if (st.categories.isEmpty && st.loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...st.categories.map((cat) {
                final items = cat.interests.map((i) => (i.id, i.name)).toList();
                return section(cat.name, items);
              }),

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: st.loading
                    ? null
                    : () async {
                        try {
                          await vc.submit();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved interests!')),
                          );
                          // TODO: Navigator.pushReplacementNamed(context, '/home');
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Save interests failed: $e'),
                            ),
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
