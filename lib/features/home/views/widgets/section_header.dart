import 'package:flutter/material.dart';
import 'package:quran_pro/core/theme/app_colors.dart';

final class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.icon, required this.title, this.trailing, super.key});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
    child: Row(
      spacing: 6,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF131B2E),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
