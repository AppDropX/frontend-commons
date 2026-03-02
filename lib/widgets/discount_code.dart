import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/color.dart';

/// Apply discount code block for cart page.
/// Props: enabled, placeholder, buttonLabel, buttonColor, buttonFontColor, borderRadius.
/// Dispatches action { "type": "apply_discount", "code": "<value>" } when Apply is tapped.
Widget buildDiscountCode(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final placeholder = node.s('placeholder', def: 'Discount code');
  final buttonLabel = node.s('buttonLabel', def: 'Apply');
  final buttonColor = parseHexColor(node.s('buttonColor', def: '#111827')) ?? const Color(0xFF111827);
  final buttonFontColor = parseHexColor(node.s('buttonFontColor', def: '#FFFFFF')) ?? Colors.white;
  final radius = node.d('borderRadius', def: 12).clamp(0, 24).toDouble();

  return _DiscountCodeWidget(
    placeholder: placeholder,
    buttonLabel: buttonLabel,
    buttonColor: buttonColor,
    buttonFontColor: buttonFontColor,
    borderRadiusDp: radius,
    r: r,
    onApply: (code) {
      env.dispatchAction(context, {
        'type': 'apply_discount',
        'code': code,
      });
    },
  );
}

class _DiscountCodeWidget extends StatefulWidget {
  const _DiscountCodeWidget({
    required this.placeholder,
    required this.buttonLabel,
    required this.buttonColor,
    required this.buttonFontColor,
    required this.borderRadiusDp,
    required this.r,
    required this.onApply,
  });

  final String placeholder;
  final String buttonLabel;
  final Color buttonColor;
  final Color buttonFontColor;
  final double borderRadiusDp;
  final R r;
  final void Function(String code) onApply;

  @override
  State<_DiscountCodeWidget> createState() => _DiscountCodeWidgetState();
}

class _DiscountCodeWidgetState extends State<_DiscountCodeWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _controller.text.trim();
    if (code.isNotEmpty) {
      widget.onApply(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.r.dp(widget.borderRadiusDp);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: widget.r.dp(16), vertical: widget.r.dp(12)),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.r.dp(14),
                  vertical: widget.r.dp(12),
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _apply(),
            ),
          ),
          SizedBox(width: widget.r.dp(10)),
          Material(
            color: widget.buttonColor,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: _apply,
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.r.dp(18),
                  vertical: widget.r.dp(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.buttonLabel,
                  style: TextStyle(
                    color: widget.buttonFontColor,
                    fontSize: widget.r.sp(14, min: 12, max: 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
