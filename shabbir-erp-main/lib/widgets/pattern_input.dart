import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PatternInput extends StatefulWidget {
  final void Function(String pattern) onComplete;
  final int gridSize;
  final Color? activeColor;

  const PatternInput({
    super.key,
    required this.onComplete,
    this.gridSize = 3,
    this.activeColor,
  });

  @override
  State<PatternInput> createState() => _PatternInputState();
}

class _PatternInputState extends State<PatternInput> {
  final List<int> _selected = [];
  final List<Offset> _points = [];
  Offset? _currentPoint;
  bool _complete = false;

  static const double _dotRadius = 12.0;
  static const double _activeDotRadius = 18.0;

  List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.gridSize * widget.gridSize, (_) => GlobalKey());
  }

  Offset? _getCenter(int index) {
    final ctx = _keys[index].currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final pos = box.localToGlobal(Offset.zero);
    return pos + Offset(box.size.width / 2, box.size.height / 2);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _selected.clear();
      _points.clear();
      _complete = false;
      _currentPoint = details.globalPosition;
    });
    _checkHit(details.globalPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_complete) return;
    setState(() => _currentPoint = details.globalPosition);
    _checkHit(details.globalPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_selected.length >= 4) {
      setState(() => _complete = true);
      widget.onComplete(_selected.join('-'));
    } else {
      setState(() {
        _selected.clear();
        _points.clear();
        _complete = false;
        _currentPoint = null;
      });
    }
  }

  void _checkHit(Offset pos) {
    for (int i = 0; i < widget.gridSize * widget.gridSize; i++) {
      if (_selected.contains(i)) continue;
      final center = _getCenter(i);
      if (center == null) continue;
      if ((pos - center).distance < 30) {
        setState(() {
          _selected.add(i);
          _points.add(center);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.activeColor ?? AppColors.accent;
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: _PatternPainter(
          points: _points,
          currentPoint: _complete ? null : _currentPoint,
          color: color,
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.gridSize,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
          ),
          itemCount: widget.gridSize * widget.gridSize,
          itemBuilder: (_, index) {
            final active = _selected.contains(index);
            return Center(
              key: _keys[index],
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: active ? _activeDotRadius * 2 : _dotRadius * 2,
                height: active ? _activeDotRadius * 2 : _dotRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? color.withOpacity(0.2) : Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: active ? color : Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: active
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<Offset> points;
  final Offset? currentPoint;
  final Color color;

  _PatternPainter({required this.points, this.currentPoint, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
    if (currentPoint != null && points.isNotEmpty) {
      canvas.drawLine(points.last, currentPoint!, paint);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.points != points || old.currentPoint != currentPoint;
}
