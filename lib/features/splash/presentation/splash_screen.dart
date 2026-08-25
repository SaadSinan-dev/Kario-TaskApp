import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/startup.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_palette.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/brand_mark.dart';

/// The application entry screen.
///
/// It is a real gate, not decoration: the product cannot render until storage
/// is open, the workspace is loaded and the session is restored, and this is
/// the screen that waits for that work and then routes to wherever the user
/// actually belongs.
///
/// Two rules shape the timing. The splash never adds delay for its own sake —
/// it leaves the moment initialisation resolves. But it also never leaves
/// mid-entrance, because a logo that vanishes halfway through fading in reads
/// as a glitch; so the exit waits for the entrance to finish, and no longer.
/// Under reduced motion there is no entrance to wait for, and it leaves
/// immediately.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// How long the full entrance takes. The exit gate uses the same number so
  /// the two can never drift apart.
  static const Duration entrance = Duration(milliseconds: 900);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// One controller drives the whole composition. Each element reads a
  /// different slice of it through an `Interval`, so a six-part sequence costs
  /// a single ticker rather than six.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashScreen.entrance,
  );

  late final Animation<double> _backgroundFade = _slice(0, 0.35);
  late final Animation<double> _markFade = _slice(0.12, 0.55);
  late final Animation<double> _markScale = Tween<double>(begin: 0.85, end: 1)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.12, 0.62, curve: Motion.emphasized),
        ),
      );
  late final Animation<double> _wordFade = _slice(0.34, 0.72);
  late final Animation<double> _wordSlide = Tween<double>(begin: 10, end: 0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.34, 0.78, curve: Motion.emphasized),
        ),
      );
  late final Animation<double> _tagFade = _slice(0.5, 0.9);

  /// Set once the entrance has played far enough that leaving looks deliberate.
  bool _entranceSettled = false;
  bool _navigated = false;

  Animation<double> _slice(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Motion.entrance),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onEntranceDone);
    // Kick off initialisation on the first frame rather than during build, so
    // the splash paints before any of the startup work competes for the
    // main isolate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(startupProvider);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion means there is no entrance to wait for: the composition
    // is already at its resting state and the gate opens immediately.
    if (context.reducedMotion) {
      _controller.value = 1;
      _entranceSettled = true;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  void _onEntranceDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || _entranceSettled) return;
    setState(() => _entranceSettled = true);
    _leaveIfReady();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onEntranceDone)
      ..dispose();
    super.dispose();
  }

  /// Navigates once both gates are open: initialisation resolved, and the
  /// entrance finished.
  void _leaveIfReady() {
    if (_navigated || !_entranceSettled || !mounted) return;
    final AsyncValue<StartupResult> startup = ref.read(startupProvider);
    // Riverpod 3 exposes a nullable value; null means "still initialising".
    final StartupResult? result = startup.value;
    if (result == null) return;

    _navigated = true;
    GoRouter.of(context).go(result.route);
  }

  @override
  Widget build(BuildContext context) {
    // Watching rather than reading: when initialisation resolves while the
    // entrance is still playing, this rebuild is what re-checks the gate.
    ref.listen<AsyncValue<StartupResult>>(startupProvider, (_, _) {
      _leaveIfReady();
    });

    final bool reducedMotion = context.reducedMotion;
    final Brightness brightness = Theme.of(context).brightness;

    return Scaffold(
      // The splash owns its own colour rather than the theme canvas: it is the
      // brand moment, and it must match the native launch window exactly.
      backgroundColor: brightness == Brightness.dark
          ? AppPalette.blue950
          : AppPalette.blue600,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Opacity(opacity: _backgroundFade.value, child: child);
        },
        child: _SplashBackdrop(
          reducedMotion: reducedMotion,
          brightness: brightness,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    return Opacity(
                      opacity: _markFade.value.clamp(0, 1),
                      child: Transform.scale(
                        scale: _markScale.value,
                        child: child,
                      ),
                    );
                  },
                  // `onDark` because the splash field is brand blue: the
                  // in-app mark is a blue tile with a white glyph, which
                  // would all but vanish here.
                  child: const BrandMark(
                    size: 76,
                    showWordmark: false,
                    onDark: true,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    return Opacity(
                      opacity: _wordFade.value.clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(0, _wordSlide.value),
                        child: child,
                      ),
                    );
                  },
                  child: const Text(
                    'Kairo',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    return Opacity(
                      opacity: _tagFade.value.clamp(0, 1),
                      child: child,
                    );
                  },
                  child: Text(
                    'The command center for focused work',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gradient field and the single moving highlight behind the mark.
///
/// The highlight is the only continuous animation on the screen and it is
/// isolated behind its own [RepaintBoundary], so the glow repaints without
/// touching the logo, the wordmark or the tagline.
class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop({
    required this.reducedMotion,
    required this.brightness,
    required this.child,
  });

  final bool reducedMotion;
  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const <Color>[
                  AppPalette.blue950,
                  Color(0xFF16255E),
                  AppPalette.blue900,
                ]
              : const <Color>[
                  AppPalette.blue700,
                  AppPalette.blue600,
                  AppPalette.indigo,
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (!reducedMotion)
            const RepaintBoundary(child: _DriftingGlow())
          else
            const _StaticGlow(),
          const Positioned.fill(
            child: BrandGridPattern(spacing: 56, opacity: 0.06),
          ),
          child,
        ],
      ),
    );
  }
}

/// A slow, wide highlight that drifts once across the field during startup.
///
/// It runs forward only — an infinite loop would keep a ticker alive behind
/// whatever screen comes next if the splash were ever kept alive, and a single
/// pass is all a startup sequence is long enough to show.
class _DriftingGlow extends StatefulWidget {
  const _DriftingGlow();

  @override
  State<_DriftingGlow> createState() => _DriftingGlowState();
}

class _DriftingGlowState extends State<_DriftingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double t = Curves.easeInOutSine.transform(_controller.value);
        return CustomPaint(
          painter: _GlowPainter(
            center: Alignment(math.cos(t * math.pi) * 0.55, -0.45 + t * 0.28),
          ),
        );
      },
    );
  }
}

class _StaticGlow extends StatelessWidget {
  const _StaticGlow();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _GlowPainter(center: Alignment(0, -0.3)));
  }
}

/// A soft radial highlight. Painted with a gradient shader rather than a
/// blurred layer: `BackdropFilter` would force an expensive save-layer on the
/// very first frames of the app, which is the last place to spend GPU time.
class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.center});

  final Alignment center;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Offset focus = center.withinRect(bounds);
    final double radius = size.longestSide * 0.62;

    canvas.drawCircle(
      focus,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: focus, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.center != center;
}
