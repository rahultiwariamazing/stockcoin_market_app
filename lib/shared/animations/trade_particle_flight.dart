import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Reusable overlay animation utility:
// source widget (buy/sell button) -> target widget (badge) particle flight.
class TradeParticleFlight {
  const TradeParticleFlight();

  Future<void> triggerBuyAnimation(
    BuildContext context, {
    required GlobalKey sourceKey,
    required GlobalKey targetKey,
    VoidCallback? onReached,
  }) {
    return _trigger(
      context,
      sourceKey: sourceKey,
      targetKey: targetKey,
      color: const Color(0xFF16A34A),
      onReached: onReached,
    );
  }

  Future<void> triggerSellAnimation(
    BuildContext context, {
    required GlobalKey sourceKey,
    required GlobalKey targetKey,
    VoidCallback? onReached,
  }) {
    return _trigger(
      context,
      sourceKey: sourceKey,
      targetKey: targetKey,
      color: const Color(0xFFDC2626),
      onReached: onReached,
    );
  }

  Future<void> _trigger(
    BuildContext context, {
    required GlobalKey sourceKey,
    required GlobalKey targetKey,
    required Color color,
    VoidCallback? onReached,
  }) async {
    // Resolve current global positions from widget keys.
    final overlay = Overlay.of(context, rootOverlay: true);
    final sourceCenter = _globalCenter(sourceKey);
    final targetCenter = _globalCenter(targetKey);

    if (sourceCenter == null || targetCenter == null) {
      return;
    }

    HapticFeedback.lightImpact();

    final random = Random();
    // Natural look: random particle count and duration in configured range.
    final particleCount = 3 + random.nextInt(4); // 3 to 6
    final durationMs = 600 + random.nextInt(301); // 600 to 900

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TradeParticleLayer(
        source: sourceCenter,
        target: targetCenter,
        color: color,
        particleCount: particleCount,
        duration: Duration(milliseconds: durationMs),
        onFinished: () {
          onReached?.call();
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }

  Offset? _globalCenter(GlobalKey key) {
    // Convert widget-local position to screen coordinates for overlay animation.
    final context = key.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }

    final origin = renderObject.localToGlobal(Offset.zero);
    return origin + Offset(renderObject.size.width / 2, renderObject.size.height / 2);
  }
}

class _TradeParticleLayer extends StatefulWidget {
  final Offset source;
  final Offset target;
  final Color color;
  final int particleCount;
  final Duration duration;
  final VoidCallback onFinished;

  const _TradeParticleLayer({
    required this.source,
    required this.target,
    required this.color,
    required this.particleCount,
    required this.duration,
    required this.onFinished,
  });

  @override
  State<_TradeParticleLayer> createState() => _TradeParticleLayerState();
}

class _TradeParticleLayerState extends State<_TradeParticleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ParticleConfig> _particles;

  @override
  void initState() {
    super.initState();
    final random = Random();
    // Each particle has slightly different path and timing.
    _particles = List.generate(
      widget.particleCount,
      (_) => _ParticleConfig.random(random),
    );

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: _particles
                .map(
                  (particle) => _ParticleDot(
                    source: widget.source,
                    target: widget.target,
                    color: widget.color,
                    animationValue: _controller.value,
                    config: particle,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _ParticleDot extends StatelessWidget {
  final Offset source;
  final Offset target;
  final Color color;
  final double animationValue;
  final _ParticleConfig config;

  const _ParticleDot({
    required this.source,
    required this.target,
    required this.color,
    required this.animationValue,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Start delay per particle creates staggered emission effect.
    final startDelay = config.startDelay;
    final localProgress = ((animationValue - startDelay) / (1 - startDelay))
        .clamp(0.0, 1.0)
        .toDouble();
    if (localProgress <= 0) {
      return const SizedBox.shrink();
    }

    final eased = Curves.easeInOutCubic.transform(localProgress);
    final midPoint = Offset(
      // Curved path control point for bezier-like motion.
      (source.dx + target.dx) / 2 + config.curveOffsetX,
      (source.dy + target.dy) / 2 + config.curveOffsetY,
    );

    final position = _quadraticBezier(source, midPoint, target, eased);
    final fadeOut = (1 - (localProgress * 0.9)).clamp(0.0, 1.0);
    final scale = 0.8 + (0.4 * (1 - localProgress));

    return Positioned(
      left: position.dx - (config.size / 2),
      top: position.dy - (config.size / 2),
      child: Opacity(
        opacity: fadeOut,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: config.size,
            height: config.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.36),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    // Standard quadratic bezier interpolation.
    final oneMinusT = 1 - t;
    final x =
        (oneMinusT * oneMinusT * p0.dx) + (2 * oneMinusT * t * p1.dx) + (t * t * p2.dx);
    final y =
        (oneMinusT * oneMinusT * p0.dy) + (2 * oneMinusT * t * p1.dy) + (t * t * p2.dy);
    return Offset(x, y);
  }
}

class _ParticleConfig {
  final double size;
  final double curveOffsetX;
  final double curveOffsetY;
  final double startDelay;

  const _ParticleConfig({
    required this.size,
    required this.curveOffsetX,
    required this.curveOffsetY,
    required this.startDelay,
  });

  factory _ParticleConfig.random(Random random) {
    // Random config keeps movement organic and less robotic.
    return _ParticleConfig(
      size: 7 + random.nextDouble() * 4,
      curveOffsetX: -55 + random.nextDouble() * 110,
      curveOffsetY: -100 + random.nextDouble() * 30,
      startDelay: random.nextDouble() * 0.25,
    );
  }
}
