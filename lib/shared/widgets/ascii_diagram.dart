import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forja/core/theme.dart';

class AsciiDiagramNode {
  const AsciiDiagramNode(
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.labels,
  );

  final int left, top, right, bottom;
  final List<String> labels;

  bool contains(int x, int y) =>
      x >= left && x <= right && y >= top && y <= bottom;
}

enum DiagramArrow { none, open, triangle }

class AsciiDiagramConnection {
  const AsciiDiagramConnection(
    this.nodes,
    this.target,
    this.arrow,
    this.diamond,
  );

  final List<int> nodes;
  final int target;
  final DiagramArrow arrow;
  final bool diamond;
}

/// Conservatively recognizes boxed ASCII diagrams. Unrecognized content stays
/// in the original code view rather than being partially converted or dropped.
class AsciiDiagram {
  const AsciiDiagram(this.nodes, this.connections);

  final List<AsciiDiagramNode> nodes;
  final List<AsciiDiagramConnection> connections;

  static AsciiDiagram? tryParse(String source) {
    final lines = source.replaceAll('\t', '    ').split('\n');
    final nodes = <AsciiDiagramNode>[];
    final border = RegExp(r'\+-{3,}\+');
    String at(int x, int y) =>
        y < 0 || y >= lines.length || x < 0 || x >= lines[y].length
        ? ' '
        : lines[y][x];
    int? nodeAt(int x, int y) {
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].contains(x, y)) return i;
      }
      return null;
    }

    for (var y = 0; y < lines.length; y++) {
      for (final match in border.allMatches(lines[y])) {
        final left = match.start, right = match.end - 1;
        if (nodeAt(left, y) != null) continue;
        final labels = <String>[];
        for (var bottom = y + 1; bottom < lines.length; bottom++) {
          if (at(left, bottom) == '+' &&
              lines[bottom].length > right &&
              lines[bottom].substring(left, right + 1) == match[0]) {
            if (labels.isNotEmpty) {
              nodes.add(AsciiDiagramNode(left, y, right, bottom, labels));
            }
            break;
          }
          if (at(left, bottom) != '|' || at(right, bottom) != '|') break;
          final label = lines[bottom].substring(left + 1, right).trim();
          if (label.isNotEmpty) labels.add(label);
        }
      }
    }
    if (nodes.isEmpty) return null;

    const horizontal = '-=+<>◀▶';
    const vertical = '|+^v▲▼';
    final cells = <(int, int)>{};
    for (var y = 0; y < lines.length; y++) {
      for (var x = 0; x < lines[y].length; x++) {
        if (nodeAt(x, y) != null || at(x, y).trim().isEmpty) continue;
        if (!horizontal.contains(at(x, y)) && !vertical.contains(at(x, y))) {
          return null;
        }
        cells.add((x, y));
      }
    }

    const directions = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    final connections = <AsciiDiagramConnection>[];
    while (cells.isNotEmpty) {
      final component = <(int, int)>{};
      final pending = [cells.first];
      cells.remove(pending.first);
      while (pending.isNotEmpty) {
        final point = pending.removeLast();
        component.add(point);
        for (final (dx, dy) in directions) {
          final next = (point.$1 + dx, point.$2 + dy);
          if (cells.remove(next)) pending.add(next);
        }
      }

      int? trace(int x, int y, int dx, int dy) {
        for (var distance = 1; distance <= 6; distance++) {
          final nx = x + dx * distance, ny = y + dy * distance;
          final node = nodeAt(nx, ny);
          if (node != null) return node;
          if (at(nx, ny).trim().isNotEmpty && !component.contains((nx, ny))) {
            break;
          }
        }
        return null;
      }

      final touched = <int>{};
      int? target;
      var arrow = DiagramArrow.none;
      var diamond = false;
      for (final (x, y) in component) {
        final glyph = at(x, y);
        for (final (dx, dy) in directions) {
          if (dx != 0 && !horizontal.contains(glyph)) continue;
          if (dy != 0 && !vertical.contains(glyph)) continue;
          final node = trace(x, y, dx, dy);
          if (node != null) touched.add(node);
        }
        if ((glyph == '<' && at(x + 1, y) == '>') ||
            (glyph == '>' && at(x - 1, y) == '<')) {
          diamond = true;
          continue;
        }
        final direction = switch (glyph) {
          '>' || '▶' => (1, 0),
          '<' || '◀' => (-1, 0),
          '^' || '▲' => (0, -1),
          'v' || '▼' => (0, 1),
          _ => null,
        };
        if (direction != null) {
          final node = trace(x, y, direction.$1, direction.$2);
          if (node != null) {
            // Multiple arrow targets need a richer parser; retain the source.
            if (target != null && target != node) return null;
            target = node;
            arrow = '▲▼◀▶'.contains(glyph)
                ? DiagramArrow.triangle
                : DiagramArrow.open;
          }
        }
      }
      if (touched.length < 2) return null;
      connections.add(
        AsciiDiagramConnection(
          touched.toList(),
          target ?? touched.first,
          arrow,
          diamond,
        ),
      );
    }
    return AsciiDiagram(nodes, connections);
  }
}

class AsciiDiagramView extends StatefulWidget {
  const AsciiDiagramView({super.key, required this.diagram});

  final AsciiDiagram diagram;

  @override
  State<AsciiDiagramView> createState() => _AsciiDiagramViewState();
}

class _AsciiDiagramViewState extends State<AsciiDiagramView> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _controller,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      child: DiagramCanvas(diagram: widget.diagram),
    ),
  );
}

class DiagramCanvas extends StatelessWidget {
  const DiagramCanvas({super.key, required this.diagram});

  final AsciiDiagram diagram;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final minX = diagram.nodes.map((node) => node.left).reduce(math.min);
    final minY = diagram.nodes.map((node) => node.top).reduce(math.min);
    final maxX = diagram.nodes.map((node) => node.right).reduce(math.max);
    final maxY = diagram.nodes.map((node) => node.bottom).reduce(math.max);
    final rects = diagram.nodes
        .map(
          (node) => Rect.fromLTRB(
            (node.left - minX) * 11 * scale,
            (node.top - minY) * 32 * scale,
            (node.right - minX) * 11 * scale,
            (node.bottom - minY) * 32 * scale,
          ),
        )
        .toList();
    return SizedBox(
      width: (maxX - minX) * 11 * scale,
      height: (maxY - minY) * 32 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ConnectionPainter(diagram, rects)),
          ),
          for (var i = 0; i < diagram.nodes.length; i++)
            Positioned.fromRect(
              rect: rects[i],
              child: _DiagramCard(node: diagram.nodes[i]),
            ),
        ],
      ),
    );
  }
}

class _DiagramCard extends StatelessWidget {
  const _DiagramCard({required this.node});
  final AsciiDiagramNode node;

  @override
  Widget build(BuildContext context) {
    final isInterface = node.labels.any((label) => label.startsWith('<<'));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ForjaColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInterface
              ? ForjaColors.ember
              : ForjaColors.textSecondary.withValues(alpha: .45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < node.labels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                node.labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: node.labels[i].startsWith('<<')
                      ? ForjaColors.emberGlow
                      : i == 0 || isInterface
                      ? ForjaColors.textPrimary
                      : ForjaColors.textSecondary,
                  fontSize: node.labels[i].startsWith('<<') ? 11 : 14,
                  fontWeight: i == 0 || isInterface
                      ? FontWeight.w600
                      : FontWeight.w400,
                  height: 1.25,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  _ConnectionPainter(this.diagram, this.rects);
  final AsciiDiagram diagram;
  final List<Rect> rects;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ForjaColors.emberGlow
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    for (final connection in diagram.connections) {
      final target = rects[connection.target];
      for (final index in connection.nodes.where(
        (i) => i != connection.target,
      )) {
        final source = rects[index];
        final vertical =
            source.bottom <= target.top || source.top >= target.bottom;
        final start = vertical
            ? (source.center.dy > target.center.dy
                  ? source.topCenter
                  : source.bottomCenter)
            : (source.center.dx < target.center.dx
                  ? source.centerRight
                  : source.centerLeft);
        final end = vertical
            ? (source.center.dy > target.center.dy
                  ? target.bottomCenter
                  : target.topCenter)
            : (source.center.dx < target.center.dx
                  ? target.centerLeft
                  : target.centerRight);
        final path = Path()..moveTo(start.dx, start.dy);
        if (vertical) {
          final middle = (start.dy + end.dy) / 2;
          path
            ..lineTo(start.dx, middle)
            ..lineTo(end.dx, middle);
        } else {
          final middle = (start.dx + end.dx) / 2;
          path
            ..lineTo(middle, start.dy)
            ..lineTo(middle, end.dy);
        }
        path.lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);
        final direction = vertical
            ? Offset(0, end.dy > start.dy ? 1 : -1)
            : Offset(end.dx > start.dx ? 1 : -1, 0);
        final normal = Offset(-direction.dy, direction.dx);
        if (connection.arrow != DiagramArrow.none) {
          final back = end - direction * 12;
          final arrow = Path()
            ..moveTo((back + normal * 6).dx, (back + normal * 6).dy)
            ..lineTo(end.dx, end.dy)
            ..lineTo((back - normal * 6).dx, (back - normal * 6).dy);
          if (connection.arrow == DiagramArrow.triangle) {
            arrow.close();
            canvas.drawPath(arrow, Paint()..color = ForjaColors.surfaceVariant);
          }
          canvas.drawPath(arrow, paint);
        }
        if (connection.diamond) {
          final diamond = Path()
            ..moveTo(start.dx, start.dy)
            ..lineTo(
              (start + direction * 7 + normal * 5).dx,
              (start + direction * 7 + normal * 5).dy,
            )
            ..lineTo((start + direction * 14).dx, (start + direction * 14).dy)
            ..lineTo(
              (start + direction * 7 - normal * 5).dx,
              (start + direction * 7 - normal * 5).dy,
            )
            ..close();
          canvas.drawPath(diamond, Paint()..color = ForjaColors.surfaceVariant);
          canvas.drawPath(diamond, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectionPainter oldDelegate) =>
      oldDelegate.diagram != diagram || !listEquals(oldDelegate.rects, rects);
}
