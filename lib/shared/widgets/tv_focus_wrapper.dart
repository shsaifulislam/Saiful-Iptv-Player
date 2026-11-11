import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Wraps any widget with TV D-Pad and keyboard focus affordance.
///
/// Features animated slight scale-up (1.03x), high-contrast glowing border,
/// and smooth elevation on focus, adhering to 10-foot TV UI ergonomics.
class TvFocusWrapper extends StatefulWidget {
  const TvFocusWrapper({
    required this.child,
    required this.onTap,
    super.key,
    this.borderRadius,
    this.autofocus = false,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        widget.borderRadius ?? BorderRadius.circular(AppSpacing.cardRadius);
    final isHighlighted = _isFocused || _isHovered;

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final logical = event.logicalKey;
          if (logical == LogicalKeyboardKey.select ||
              logical == LogicalKeyboardKey.enter ||
              logical == LogicalKeyboardKey.space ||
              logical == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: isHighlighted ? 1.035 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: effectiveRadius,
                border: Border.all(
                  color: isHighlighted
                      ? AppColors.primary
                      : Colors.transparent,
                  width: isHighlighted ? 2.5 : 0.0,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: effectiveRadius,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

