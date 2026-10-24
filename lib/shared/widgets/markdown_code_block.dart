import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:highlight/highlight.dart' as syntax;
import 'package:markdown/markdown.dart' as md;

import 'package:forja/core/theme.dart';

/// Handles only block code, leaving inline backticks to the Markdown renderer.
class MarkdownCodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) =>
      const SizedBox.shrink();

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.children?.whereType<md.Element>().firstOrNull;
    final languageClass = code?.attributes['class'] ?? '';
    final language = languageClass.startsWith('language-')
        ? languageClass.substring(9).split(RegExp(r'\s+')).first.toLowerCase()
        : '';
    // Markdown appends a newline to fenced code; retain all other whitespace.
    final source = element.textContent;
    return MarkdownCodeBlock(
      source: source.endsWith('\n')
          ? source.substring(0, source.length - 1)
          : source,
      language: language,
    );
  }
}

class MarkdownCodeBlock extends StatefulWidget {
  const MarkdownCodeBlock({
    super.key,
    required this.source,
    required this.language,
  });

  final String source;
  final String language;

  @override
  State<MarkdownCodeBlock> createState() => _MarkdownCodeBlockState();
}

class _MarkdownCodeBlockState extends State<MarkdownCodeBlock> {
  final _scrollController = ScrollController();
  late TextSpan _highlighted;

  static const _colors = <String, Color>{
    'keyword': Color(0xFFC792EA),
    'built_in': Color(0xFF82AAFF),
    'type': Color(0xFFFFCB6B),
    'literal': Color(0xFFF78C6C),
    'number': Color(0xFFF78C6C),
    'string': Color(0xFFC3E88D),
    'comment': Color(0xFF8B9BAD),
    'doctag': Color(0xFF8B9BAD),
    'title': Color(0xFF82AAFF),
    'function': Color(0xFF82AAFF),
    'attr': Color(0xFFFFCB6B),
    'attribute': Color(0xFFFFCB6B),
    'tag': Color(0xFFF07178),
    'name': Color(0xFFF07178),
    'variable': Color(0xFFF07178),
    'meta': Color(0xFF89DDFF),
    'symbol': Color(0xFF89DDFF),
    'selector-class': Color(0xFFFFCB6B),
    'addition': Color(0xFFC3E88D),
    'deletion': Color(0xFFF07178),
  };

  @override
  void initState() {
    super.initState();
    _highlight();
  }

  @override
  void didUpdateWidget(MarkdownCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.language != widget.language) {
      _highlight();
    }
  }

  void _highlight() {
    final language = switch (widget.language) {
      'c#' || 'cs' => 'csharp',
      'js' => 'javascript',
      'ts' => 'typescript',
      'py' => 'python',
      'sh' || 'shell' => 'bash',
      'html' => 'xml',
      'yml' => 'yaml',
      _ => widget.language,
    };
    // Unknown languages and plain text safely retain their original content.
    try {
      final result = syntax.highlight.parse(widget.source, language: language);
      _highlighted = TextSpan(children: result.nodes?.map(_span).toList());
    } catch (_) {
      _highlighted = TextSpan(text: widget.source);
    }
  }

  TextSpan _span(syntax.Node node) => TextSpan(
    text: node.value,
    style: _colors.containsKey(node.className)
        ? TextStyle(color: _colors[node.className])
        : null,
    children: node.children?.map(_span).toList(),
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.source));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Código copiado')));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.only(left: 14, right: 6),
        decoration: const BoxDecoration(
          color: ForjaColors.surface,
          border: Border(bottom: BorderSide(color: ForjaColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.language.isEmpty ? 'texto' : widget.language,
                style: const TextStyle(
                  color: ForjaColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: const Text('Copiar'),
            ),
          ],
        ),
      ),
      Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(14),
          child: SelectableText.rich(
            _highlighted,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.6,
              color: ForjaColors.textPrimary,
            ),
            textScaler: MediaQuery.textScalerOf(context),
          ),
        ),
      ),
    ],
  );
}
