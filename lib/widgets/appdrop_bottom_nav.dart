import 'package:flutter/material.dart';
import '../theme/appdrop_theme_config.dart';
import '../utils/icon_mapper.dart';

class AppDropBottomNav extends StatelessWidget {
  final AppStylingConfig styling;
  final BottomBarConfig config;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppDropBottomNav({
    super.key,
    required this.styling,
    required this.config,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = config.items.where((e) => e.enabled).toList();
    if (!config.enabled || items.isEmpty) return const SizedBox.shrink();

    final withLabels = styling.bottomIconStyle.toLowerCase().contains('label');
    final underline = styling.bottomStyle.toLowerCase() == 'underline';

    return Container(
      color: styling.bottomBg,
      padding: const EdgeInsets.only(top: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == currentIndex;
            final color = selected ? styling.bottomSelected : styling.bottomUnselected;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconFromName(item.icon), color: color, size: 22),
                      if (withLabels) ...[
                        const SizedBox(height: 4),
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      ],
                      if (underline)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          height: 2,
                          width: 28,
                          color: selected ? styling.bottomSelected : Colors.transparent,
                        ),
                    ],
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
