import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:outdoor_clothing_picker/backend/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/database/database.dart';
import 'package:provider/provider.dart';

/// Widget with a figure with has a toggleable [isInteractiveMode], which causes either
/// (false, default) current filtered clothing labels to be drawn on it,
/// (true) allow the user to tap it to select a point, returnable via [onTap] callback.
/// Interactive mode is meant to be used for selecting points that can be visualized later
/// at the some points by a different uninteractive figure. [initialCirclePosition] can be
/// provided as normalized coordinates for the first selected point, in interactive mode.
class Mannequin extends StatefulWidget {
  final ValueChanged<Offset>? onTap;
  final bool isInteractiveMode;
  final Offset? initialCirclePosition;

  const Mannequin({
    super.key,
    this.onTap,
    this.isInteractiveMode = false,
    this.initialCirclePosition,
  });

  @override
  State<Mannequin> createState() => _MannequinState();
}

class _MannequinState extends State<Mannequin> with WidgetsBindingObserver {
  final GlobalKey _figureKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  Rect? figureRect;
  Offset? _circlePosition;

  @override
  void initState() {
    super.initState();
    // The overlay on the figure redraws whenever the size of the figure changes
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateFigureRect());
    _circlePosition = widget.initialCirclePosition;
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateFigureRect());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateFigureRect());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The bounding rectangle needs to be calculated and tracked in order to place the overlay
  /// points at the exact normalized coordinates.
  void _calculateFigureRect() {
    final RenderBox? figureBox = _figureKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;

    if (figureBox != null && stackBox != null) {
      final figurePositionGlobal = figureBox.localToGlobal(Offset.zero);
      final stackPositionGlobal = stackBox.localToGlobal(Offset.zero);
      final figurePositionLocal = figurePositionGlobal - stackPositionGlobal;
      final newRect = figurePositionLocal & figureBox.size;

      if (figureRect != newRect) {
        setState(() {
          figureRect = newRect;
        });
      }
    }
  }

  void _handleInteractiveTap(Offset normalized) {
    setState(() {
      _circlePosition = normalized;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ClothingViewModel>();
    final overlayColor = Theme.of(context).colorScheme.onPrimaryContainer;
    final circleColor = Theme.of(context).colorScheme.primaryContainer;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          // Detect and calculate normalized coordinates within the figure
          behavior: HitTestBehavior.translucent,
          onTapDown: (TapDownDetails details) {
            if (figureRect != null) {
              final localPos = details.localPosition;
              if (figureRect!.contains(localPos)) {
                final normalizedX = (localPos.dx - figureRect!.left) / figureRect!.width;
                final normalizedY = (localPos.dy - figureRect!.top) / figureRect!.height;
                final normalizedOffset = Offset(normalizedX, normalizedY);

                if (kDebugMode) {
                  debugPrint('Tapped at normalized coordinate: ($normalizedOffset)');
                }

                if (widget.isInteractiveMode) _handleInteractiveTap(normalizedOffset);

                widget.onTap?.call(normalizedOffset);
              }
            }
          },
          child: Stack(
            key: _stackKey,
            children: [
              Center(
                // child: _addIcon(context, constraints, _figureKey)
                child: _addSvg(context, constraints, _figureKey),
              ),
              if (figureRect != null)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: widget.isInteractiveMode
                        ? CirclePainter(
                            normalizedPosition: _circlePosition,
                            figureRect: figureRect!,
                            foregroundColor: overlayColor,
                            backgroundColor: circleColor,
                          )
                        : ClothingPainter(viewModel.filteredClothing, overlayColor, figureRect!),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Draw the selected clothing labels on top of the figure.
class ClothingPainter extends CustomPainter {
  final List<ValidClothingResult> clothing;
  final Color color;
  final Rect figureRect;

  ClothingPainter(this.clothing, this.color, this.figureRect);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2;
    if (kDebugMode) print('Painting');

    for (var item in clothing) {
      final startX = figureRect.left + item.normX * figureRect.width;
      final y = figureRect.top + item.normY * figureRect.height;
      final labelX = size.width * 0.7; // Place label at 70% width

      // Draw horizontal line from figure to label
      canvas.drawLine(Offset(startX, y), Offset(labelX - 10, y), linePaint);

      // Draw label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.name,
          style: TextStyle(color: color, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(labelX, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant ClothingPainter oldDelegate) {
    // Note that theme change causes an animation with more than just the initial and final color
    return !listEquals(oldDelegate.clothing, clothing) ||
        oldDelegate.color != color ||
        oldDelegate.figureRect != figureRect;
  }
}

/// Draw a circle at the given [normalizedPosition} of the [figureRect].
class CirclePainter extends CustomPainter {
  final Offset? normalizedPosition;
  final Rect figureRect;
  final Color foregroundColor;
  final Color backgroundColor;

  CirclePainter({
    required this.normalizedPosition,
    required this.figureRect,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedPosition == null) {
      return;
    }

    final actual = Offset(
      figureRect.left + normalizedPosition!.dx * figureRect.width,
      figureRect.top + normalizedPosition!.dy * figureRect.height,
    );

    const radius = 5.0;

    final fillPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(actual, radius, fillPaint);
    canvas.drawCircle(actual, radius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) {
    return normalizedPosition != oldDelegate.normalizedPosition ||
        figureRect != oldDelegate.figureRect ||
        foregroundColor != oldDelegate.foregroundColor;
  }
}

Widget _addIcon(
  BuildContext context,
  BoxConstraints constraints,
  GlobalKey key, {
  IconData icon = Icons.man,
}) {
  return Icon(
    icon,
    key: key,
    size: constraints.maxWidth < constraints.maxHeight
        ? constraints.maxWidth
        : constraints.maxHeight,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    blendMode: BlendMode.srcIn,
  );
}

Widget _addSvg(
  BuildContext context,
  BoxConstraints constraints,
  GlobalKey key, {
  String assetName = 'assets/images/silhouette.svg',
}) {
  return SvgPicture.asset(
    assetName,
    key: key,
    width: constraints.maxWidth < constraints.maxHeight
        ? constraints.maxWidth
        : constraints.maxHeight,
    height: constraints.maxWidth < constraints.maxHeight
        ? constraints.maxWidth
        : constraints.maxHeight,
    fit: BoxFit.contain,
    colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
  );
}
