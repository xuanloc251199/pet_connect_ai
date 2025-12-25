import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class SelectChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const SelectChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.accent, width: 1.4),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.accent,
          ),
        ),
      ),
    );
  }
}
