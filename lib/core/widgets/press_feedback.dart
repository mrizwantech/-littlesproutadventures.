import 'package:flutter/material.dart';

class PressFeedback extends StatefulWidget {
  const PressFeedback({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  final Set<int> _pointers = {};

  void _release(PointerEvent event) {
    if (_pointers.contains(event.pointer)) {
      setState(() => _pointers.remove(event.pointer));
    }
  }

  @override
  void didUpdateWidget(PressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _pointers.clear();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: widget.enabled
            ? (event) => setState(() => _pointers.add(event.pointer))
            : null,
        onPointerUp: _release,
        onPointerCancel: _release,
        child: AnimatedScale(
          scale: widget.enabled && _pointers.isNotEmpty ? 0.94 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 60),
          child: widget.child,
        ),
      );
}

class PressableInkWell extends StatelessWidget {
  const PressableInkWell({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.customBorder,
  });

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;

  @override
  Widget build(BuildContext context) => PressFeedback(
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          customBorder: customBorder,
          splashFactory: InkRipple.splashFactory,
          splashColor: const Color(0x661684E6),
          highlightColor: const Color(0x331684E6),
          child: child,
        ),
      );
}
