import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class SelectChip extends StatelessWidget {
  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const SelectChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? AppColors.accent : Colors.transparent;
    final textColor = selected ? Colors.white : AppColors.accent;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.accent, width: 1.4),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
