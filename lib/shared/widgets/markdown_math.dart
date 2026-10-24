import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Parses display math before Markdown can interpret LaTeX underscores or slashes.
class MarkdownMathBlockSyntax extends md.BlockSyntax {
  const MarkdownMathBlockSyntax();

  @override
  RegExp get pattern => RegExp(r'^ {0,3}(\$\$|\\\[)');

  (int, String)? _read(md.BlockParser parser) {
    final opening = pattern.firstMatch(parser.current.content);
    if (opening == null) return null;
    final closing = opening[1] == r'$$' ? r'$$' : r'\]';
    final lines = <String>[];
    for (var offset = 0; ; offset++) {
      final line = parser.peek(offset);
      if (line == null) return null;
      final content = offset == 0
          ? line.content.substring(opening.end)
          : line.content;
      final end = content.indexOf(closing);
      if (end >= 0) {
        if (content.substring(end + closing.length).trim().isNotEmpty) {
          return null;
        }
        lines.add(content.substring(0, end));
        return (offset + 1, lines.join('\n').trim());
      }
      // An unclosed formula must not swallow a following code block.
      if (RegExp(r'^\s*(```|~~~)').hasMatch(content)) return null;
      lines.add(content);
    }
  }

  @override
  bool canParse(md.BlockParser parser) => _read(parser) != null;

  @override
  md.Node parse(md.BlockParser parser) {
    final (lineCount, expression) = _read(parser)!;
    for (var i = 0; i < lineCount; i++) {
      parser.advance();
    }
    return md.Element.text('math-block', expression);
  }
}

class MarkdownMathInlineSyntax extends md.InlineSyntax {
  MarkdownMathInlineSyntax()
    : super(
        r'\$\$([^\n]+?)\$\$|'
        r'\$(?![\s\$])((?:\\.|[^\$\n\\])+?)(?<!\s)\$(?!\d)|'
        r'\\\(([^\n]+?)\\\)',
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element.text('math-inline', match[1] ?? match[2] ?? match[3]!),
    );
    return true;
  }
}

class MarkdownMathBuilder extends MarkdownElementBuilder {
  MarkdownMathBuilder({required this.display, required this.style});

  final bool display;
  final TextStyle style;

  @override
  bool isBlockElement() => display;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final expression = element.textContent;
    final effectiveStyle = style.merge(parentStyle);
    final formula = Math.tex(
      expression,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: effectiveStyle,
      onErrorFallback: (_) => SelectableText(
        expression,
        style: effectiveStyle.copyWith(fontFamily: 'monospace'),
      ),
    );
    if (!display) return formula;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        primary: false,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.hasBoundedWidth ? constraints.maxWidth : 0,
          ),
          child: Center(child: formula),
        ),
      ),
    );
  }
}
