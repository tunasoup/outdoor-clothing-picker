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

// TODO: In interactive, drag and zoom
// TODO: New edit mode, where each category is visualized and movable and deletable
// TODO: Painted text should adjust to device's font size similar to Text
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
    final figureColor = Theme.of(context).colorScheme.onSurfaceVariant;

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
              Center(child: _addSvg(constraints, figureColor, _figureKey)),
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
                        : ClothingPainter(
                            constraints: constraints,
                            clothing: viewModel.filteredClothing,
                            foregroundColor: overlayColor,
                            backgroundColor: circleColor,
                            figureRect: figureRect!,
                          ),
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

/// Draw the selected [clothing] labels on top of the [figureRect].
class ClothingPainter extends CustomPainter {
  final BoxConstraints constraints;
  final List<ValidClothingResult> clothing;
  final Color foregroundColor;
  final Color backgroundColor;
  final Rect figureRect;

  ClothingPainter({
    required this.constraints,
    required this.clothing,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.figureRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (kDebugMode) print('Painting');

    final innerLinePaint = Paint()
      ..color = foregroundColor
      ..strokeWidth = 2;

    final outerLinePaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 4;

    // TODO: convert to interactable widget which allows cycling through valid category clothing
    for (var item in clothing) {
      final startX = figureRect.left + item.normX * figureRect.width;
      final y = figureRect.top + item.normY * figureRect.height;

      // Place label at around 70% or 30% width with a slight gap to the line
      final bool isLeft = item.normX < 0.5;
      final double startMult = isLeft ? 0.3 : 0.7;
      final lineEndX = size.width * startMult;
      final double labelGap = 4.0; // Distance between line and text

      // Draw horizontal line from figure to label
      canvas.drawLine(Offset(startX, y), Offset(lineEndX, y), outerLinePaint);
      canvas.drawLine(Offset(startX, y), Offset(lineEndX, y), innerLinePaint);
      // TODO: draw diagonal starting lines if too close to other visible categories, also
      //  automate the decision for left or right side

      // Draw label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.name,
          style: TextStyle(color: foregroundColor, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '..',
      );

      // Calculate the start position and maximum allowed space for the label so that it fits the
      // screen on both sides
      double maxWidth;
      double labelStartX;
      if (isLeft) {
        final labelEndX = (lineEndX - labelGap);
        maxWidth = labelEndX - constraints.minWidth;
        textPainter.layout(maxWidth: maxWidth);
        labelStartX = labelEndX - textPainter.width;
      } else {
        labelStartX = lineEndX + labelGap;
        maxWidth = constraints.maxWidth - labelStartX;
        textPainter.layout(maxWidth: maxWidth);
      }

      textPainter.paint(canvas, Offset(labelStartX, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant ClothingPainter oldDelegate) {
    // Note that theme change causes an animation with more than just the initial and final color
    return !listEquals(oldDelegate.clothing, clothing) ||
        oldDelegate.foregroundColor != foregroundColor ||
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
  BoxConstraints constraints,
  Color color,
  GlobalKey key, {
  IconData icon = Icons.man,
}) {
  return Icon(
    icon,
    key: key,
    size: constraints.maxWidth < constraints.maxHeight
        ? constraints.maxWidth
        : constraints.maxHeight,
    color: color,
    blendMode: BlendMode.srcIn,
  );
}

Widget _addSvg(
  BoxConstraints constraints,
  Color color,
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
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}
