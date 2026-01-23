import 'package:flutter/material.dart';
import '../theme/appdrop_theme_config.dart';

class AppDropTopTabs extends StatelessWidget {
  final AppStylingConfig styling;
  final TopNavigationConfig config;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AppDropTopTabs({
    super.key,
    required this.styling,
    required this.config,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (config.tabs.isEmpty) return const SizedBox.shrink();

    // ✅ height + paddings aligned so nothing clips
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: config.tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;

          return Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? styling.bottomSelected : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  config.tabs[i],
                  // ✅ use Theme so font-family works globally
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
