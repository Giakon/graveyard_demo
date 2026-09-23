import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ThoughtBubble extends PositionComponent {
  ThoughtBubble({required this.fullText})
      : super(anchor: Anchor.bottomCenter);

  final String fullText;

  double _alpha = 0;
  bool _fadingIn = true;
  bool _fadingOut = false;

  double _typewriterTimer = 0;
  int _visibleChars = 0;
  static const double charInterval = 0.04;

  static const double fadeSpeed = 2.0;
  static const double bubbleWidth = 55.0;
  static const double bubblePadding = 3.0;
  static const double fontSize = 3.5;
  static const double lineHeight = 1.4;

  bool get isDone => _fadingOut && _alpha <= 0;
  bool get isFullyVisible => _visibleChars >= fullText.length;
  String get _visibleText => fullText.substring(0, _visibleChars);

  void dismiss() {
    if (_fadingIn || _fadingOut) return;
    if (!isFullyVisible) {
      _visibleChars = fullText.length;
      return;
    }
    _fadingOut = true;
  }

  // always calculate height based on fullText so bubble
  // never grows as text types in
  double _calcBubbleHeight() {
  final painter = TextPainter(
    text: TextSpan(
      text: fullText.isEmpty ? ' ' : fullText,
      style: const TextStyle(
        fontSize: fontSize,
        height: lineHeight,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: bubbleWidth - bubblePadding * 2);

  // add extra padding to prevent vertical overflow
  return painter.height + bubblePadding * 2 + 10.0;
}

  @override
  void update(double dt) {
    super.update(dt);

    if (_fadingIn) {
      _alpha = (_alpha + fadeSpeed * dt).clamp(0, 1);
      if (_alpha >= 1) _fadingIn = false;
      return;
    }

    if (_fadingOut) {
      _alpha = (_alpha - fadeSpeed * dt).clamp(0, 1);
      return;
    }

    if (_visibleChars < fullText.length) {
      _typewriterTimer += dt;
      while (_typewriterTimer >= charInterval &&
          _visibleChars < fullText.length) {
        _typewriterTimer -= charInterval;
        _visibleChars++;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_alpha <= 0) return;

    final parentScaleX = (parent is PositionComponent)
        ? (parent as PositionComponent).scale.x
        : 1.0;

    canvas.save();
    if (parentScaleX < 0) canvas.scale(-1, 1);

    final bubbleHeight = _calcBubbleHeight();
    const dotsHeight = 8.0;
    // bubble sits above the dots, dots sit above the player
    // total offset from player center upward
    final bubbleTop = -(bubbleHeight + dotsHeight);

    // shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -bubbleWidth / 2 + 0.5,
          bubbleTop + 0.5,
          bubbleWidth,
          bubbleHeight,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withOpacity(_alpha * 0.12),
    );

    // bubble background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -bubbleWidth / 2,
          bubbleTop,
          bubbleWidth,
          bubbleHeight,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withOpacity(_alpha * 0.96),
    );

    // bubble border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -bubbleWidth / 2,
          bubbleTop,
          bubbleWidth,
          bubbleHeight,
        ),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.black.withOpacity(_alpha * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // thought dots — bottom of bubble going down to player
    final dotPositions = [
      (Offset(0, -dotsHeight + 6), 1.8),
      (Offset(1, -dotsHeight + 3.5), 1.2),
      (Offset(1.5, -dotsHeight + 1.5), 0.8),
    ];

    for (final dot in dotPositions) {
      canvas.drawCircle(
        dot.$1,
        dot.$2,
        Paint()..color = Colors.white.withOpacity(_alpha * 0.96),
      );
      canvas.drawCircle(
        dot.$1,
        dot.$2,
        Paint()
          ..color = Colors.black.withOpacity(_alpha * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4,
      );
    }

    // text — centered inside bubble
    final textPainter = TextPainter(
      text: TextSpan(
        text: _visibleText,
        style: TextStyle(
          color: Color.fromRGBO(40, 40, 40, _alpha),
          fontSize: fontSize,
          height: lineHeight,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: bubbleWidth - bubblePadding * 2);

    textPainter.paint(
      canvas,
      Offset(
        -textPainter.width / 2,
        bubbleTop + bubblePadding,
      ),
    );

    // dismiss hint pinned to bottom-right corner of bubble
    if (isFullyVisible && !_fadingOut) {
      const hintText = 'Press F to dismiss';
      const hintFontSize = 2.5;
      const hintPaddingH = 2.0;
      const hintPaddingV = 1.5;

      final hintPainter = TextPainter(
        text: TextSpan(
          text: hintText,
          style: TextStyle(
            color: Colors.white.withOpacity(_alpha),
            fontSize: hintFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final hintBoxWidth = hintPainter.width + hintPaddingH * 2;
      final hintBoxHeight = hintPainter.height + hintPaddingV * 2;

      // bottom-right corner of bubble
      final hintLeft = bubbleWidth / 2 - hintBoxWidth;
      final hintTop = bubbleTop + bubbleHeight - hintBoxHeight;

      // shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            hintLeft + 0.4,
            hintTop + 0.4,
            hintBoxWidth,
            hintBoxHeight,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.black.withOpacity(_alpha * 0.25),
      );

      // background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            hintLeft,
            hintTop,
            hintBoxWidth,
            hintBoxHeight,
          ),
          const Radius.circular(2),
        ),
        Paint()
          ..color =
              const Color(0xFF4A3728).withOpacity(_alpha * 0.9),
      );

      // border
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            hintLeft,
            hintTop,
            hintBoxWidth,
            hintBoxHeight,
          ),
          const Radius.circular(2),
        ),
        Paint()
          ..color = Colors.white.withOpacity(_alpha * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.3,
      );

      // text
      hintPainter.paint(
        canvas,
        Offset(
          hintLeft + hintPaddingH,
          hintTop + hintPaddingV,
        ),
      );
    }

    canvas.restore();
  }
}