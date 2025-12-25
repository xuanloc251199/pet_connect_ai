import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../model/knowledge_article.dart';

class KnowledgeDetailPage extends StatelessWidget {
  const KnowledgeDetailPage({super.key, required this.article});

  final KnowledgeArticle article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        title: const Text(
          'Chi tiết',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        children: [
          Text(
            article.title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          _InfoBox(
            title: 'Triệu chứng điển hình',
            icon: Icons.sick_outlined,
            items: article.symptoms.isEmpty
                ? const ['(Chưa có dữ liệu)']
                : article.symptoms,
          ),
          const SizedBox(height: 10),
          _InfoBox(
            title: 'Nguyên nhân thường gặp',
            icon: Icons.info_outline,
            items: article.causes.isEmpty
                ? const ['(Chưa có dữ liệu)']
                : article.causes,
          ),
          const SizedBox(height: 10),
          _InfoBox(
            title: 'Mức độ nguy hiểm',
            icon: Icons.warning_amber_rounded,
            items: [
              'Mức ${article.dangerLevel}/5 (tham khảo).',
              'Nếu thú cưng có dấu hiệu nặng, nên đưa đến bác sĩ thú y sớm.',
            ],
          ),
          const SizedBox(height: 10),
          _InfoBox(
            title: 'Sơ cứu tại nhà (nếu có thể)',
            icon: Icons.medical_services_outlined,
            items: article.firstAid.isEmpty
                ? const ['(Chưa có dữ liệu)']
                : article.firstAid,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_outlined, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nội dung mang tính tham khảo, không thay thế chẩn đoán của bác sĩ thú y.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
