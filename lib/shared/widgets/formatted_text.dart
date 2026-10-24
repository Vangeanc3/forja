import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:forja/core/theme.dart';
import 'markdown_code_block.dart';
import 'markdown_math.dart';

class FormattedText extends StatelessWidget {
  const FormattedText({
    super.key,
    required this.data,
    this.style,
    this.selectable = false,
  });

  final String data;
  final TextStyle? style;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle =
        style ??
        theme.textTheme.bodyMedium?.copyWith(
          color: ForjaColors.textPrimary,
          height: 1.6,
        ) ??
        const TextStyle(color: ForjaColors.textSecondary);
    final primaryStyle = baseStyle.copyWith(color: ForjaColors.textPrimary);
    final headingStyle = theme.textTheme.titleMedium?.copyWith(
      color: ForjaColors.textPrimary,
      fontWeight: FontWeight.w700,
    );

    return MarkdownBody(
      data: data.trim(),
      selectable: selectable,
      softLineBreak: true,
      extensionSet: md.ExtensionSet.gitHubWeb,
      blockSyntaxes: const [MarkdownMathBlockSyntax()],
      inlineSyntaxes: [MarkdownMathInlineSyntax()],
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      builders: {
        'pre': MarkdownCodeBlockBuilder(),
        'math-block': MarkdownMathBuilder(display: true, style: baseStyle),
        'math-inline': MarkdownMathBuilder(display: false, style: baseStyle),
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: baseStyle,
        pPadding: EdgeInsets.zero,
        strong: primaryStyle.copyWith(fontWeight: FontWeight.w800),
        em: baseStyle.copyWith(fontStyle: FontStyle.italic),
        h1: theme.textTheme.titleLarge?.copyWith(
          color: ForjaColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        h2: headingStyle?.copyWith(fontSize: 22),
        h3: headingStyle?.copyWith(fontSize: 19),
        h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
        h2Padding: const EdgeInsets.only(top: 12, bottom: 6),
        h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
        h4: primaryStyle.copyWith(fontWeight: FontWeight.w700),
        h5: primaryStyle.copyWith(fontWeight: FontWeight.w700),
        h6: primaryStyle.copyWith(fontWeight: FontWeight.w700),
        blockSpacing: 12,
        listIndent: 28,
        listBullet: baseStyle,
        listBulletPadding: const EdgeInsets.only(right: 8),
        tableHead: primaryStyle.copyWith(fontWeight: FontWeight.w700),
        tableBody: baseStyle,
        tableColumnWidth: const IntrinsicColumnWidth(),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        tableBorder: TableBorder.all(color: ForjaColors.divider),
        tableHeadCellsDecoration: const BoxDecoration(
          color: ForjaColors.surfaceVariant,
        ),
        code: primaryStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: ForjaColors.surfaceVariant,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: ForjaColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ForjaColors.divider),
        ),
        blockquote: baseStyle,
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        blockquoteDecoration: BoxDecoration(
          color: ForjaColors.ember.withValues(alpha: 0.08),
          border: const Border(
            left: BorderSide(color: ForjaColors.ember, width: 3),
          ),
        ),
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(top: BorderSide(color: ForjaColors.divider)),
        ),
      ),
    );
  }
}

class FormattedTextField extends StatefulWidget {
  const FormattedTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.minLines = 3,
    this.textCapitalization = TextCapitalization.sentences,
    this.filled = false,
    this.fillColor,
    this.border,
    this.showPreview = true,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final int minLines;
  final TextCapitalization textCapitalization;
  final bool filled;
  final Color? fillColor;
  final InputBorder? border;
  final bool showPreview;

  @override
  State<FormattedTextField> createState() => _FormattedTextFieldState();
}

class _FormattedTextFieldState extends State<FormattedTextField> {
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.controller.text.trim().isEmpty || !widget.showPreview;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(FormattedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_onTextChanged);
    widget.controller.addListener(_onTextChanged);
    _isEditing = widget.controller.text.trim().isEmpty || !widget.showPreview;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.showPreview && mounted) {
      setState(() {});
    }
  }

  void _showFormatted() {
    if (widget.controller.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isEditing = false);
  }

  void _showEditor() {
    setState(() => _isEditing = true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final previewData = widget.controller.text.trim();

    if (widget.showPreview && previewData.isNotEmpty && !_isEditing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ForjaColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ForjaColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: ForjaColors.ember,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.labelText,
                    style: text.labelSmall?.copyWith(
                      color: ForjaColors.ember,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showEditor,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('EDITAR'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FormattedText(
              data: previewData,
              selectable: true,
              style: text.bodyMedium?.copyWith(
                color: ForjaColors.textPrimary,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          minLines: widget.minLines,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: widget.textCapitalization,
          autocorrect: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          style: text.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            height: 1.5,
          ),
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            alignLabelWithHint: true,
            filled: widget.filled,
            fillColor: widget.fillColor,
            border: widget.border,
          ),
        ),
        if (widget.showPreview) ...[
          const SizedBox(height: 6),
          Text(
            'Markdown: **negrito**, - lista, > citação e ```linguagem para código. '
            'Fórmulas: \$expressão\$ no texto ou \$\$expressão\$\$ em destaque. '
            'Recue os subitens com espaços; use blocos de código para preservar alinhamentos.',
            style: text.bodySmall?.copyWith(color: ForjaColors.textSecondary),
          ),
        ],
        if (widget.showPreview && previewData.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _showFormatted,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('VISUALIZAR FORMATADO'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
