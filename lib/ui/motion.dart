import 'package:flutter/material.dart';

/// Shrinks its child a little while pressed, then springs back. It listens to the
/// raw pointer, so the child's own InkWell or button still receives the tap.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.96});
  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  Offset _start = Offset.zero;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return Listener(
      onPointerDown: (e) {
        _start = e.position;
        _set(true);
      },
      // A scroll is not a press: let go once the finger travels.
      onPointerMove: (e) {
        if ((e.position - _start).distance > 12) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 260),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// A light band that sweeps across the child every few seconds, for the main call to action.
class Shine extends StatefulWidget {
  const Shine({super.key, required this.child, this.radius = 100});
  final Widget child;
  final double radius;

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                // The sweep takes the first third of each cycle; the rest is a pause.
                final t = (_c.value * 3).clamp(0.0, 1.0);
                if (t >= 1) return const SizedBox.shrink();
                final x = -2.0 + 4.0 * Curves.easeInOut.transform(t);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(x - 0.8, -1),
                      end: Alignment(x + 0.8, 1),
                      colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0)],
                      stops: const [0.35, 0.5, 0.65],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ]);
  }
}

/// Swaps two icons with a small pop, for toggles such as save / unsave.
class PopSwitcher extends StatelessWidget {
  const PopSwitcher({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: child,
      );
}
