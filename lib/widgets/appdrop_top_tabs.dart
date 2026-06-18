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
    final items = config.items.take(5).toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();

    final baseStyle = Theme.of(context).textTheme.labelLarge ??
        Theme.of(context).textTheme.bodyMedium!;

    return ColoredBox(
      color: styling.toolbarBg,
      child: SizedBox(
        height: _barHeight,
        width: double.infinity,
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == selectedIndex;

            return Expanded(
              child: SizedBox(
                height: _barHeight,
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Spacer(),
                              Text(
                                items[i].title,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: baseStyle.copyWith(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? styling.toolbarFont
                                      : styling.toolbarFont
                                          .withValues(alpha: 0.6),
                                ),
                              ),
                              SizedBox(height: _gapAboveIndicator),
                              SizedBox(
                                height: _indicatorHeight,
                                width: double.infinity,
                                child: selected
                                    ? DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: styling.toolbarFont,
                                          borderRadius:
                                              const BorderRadius.vertical(
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
              ),
            );
          }),
        ),
      ),
    );
  }
}
