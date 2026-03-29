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

  static const double _barHeight = 31;
  static const double _indicatorHeight = 3.7;
  static const double _gapAboveIndicator = 4;

  @override
  Widget build(BuildContext context) {
    if (config.tabs.isEmpty) return const SizedBox.shrink();

    final baseStyle =
        Theme.of(context).textTheme.labelLarge ?? Theme.of(context).textTheme.bodyMedium!;

    return ColoredBox(
      color: styling.toolbarBg,
      child: SizedBox(
        height: _barHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: config.tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) {
            final selected = i == selectedIndex;

            return SizedBox(
              height: _barHeight,
              child: InkWell(
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              config.tabs[i],
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: baseStyle.copyWith(
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                color: selected
                                    ? styling.toolbarFont
                                    : styling.toolbarFont.withValues(alpha: 0.6),
                              ),
                            ),
                            SizedBox(height: _gapAboveIndicator),
                            SizedBox(
                              height: _indicatorHeight,
                              child: selected
                                  ? DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: styling.toolbarFont,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
