import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:forja/core/theme.dart';

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
          color: ForjaColors.textSecondary,
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
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: baseStyle,
        pPadding: EdgeInsets.zero,
        strong: primaryStyle.copyWith(fontWeight: FontWeight.w800),
        em: baseStyle.copyWith(fontStyle: FontStyle.italic),
        h1: theme.textTheme.titleLarge?.copyWith(
          color: ForjaColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        h2: headingStyle,
        h3: headingStyle,
        h4: primaryStyle.copyWith(fontWeight: FontWeight.w700),
        h5: primaryStyle.copyWith(fontWeight: FontWeight.w700),
        h6: primaryStyle.copyWith(fontWeight: FontWeight.w700),
        blockSpacing: 8,
        listIndent: 24,
        listBullet: baseStyle,
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
        blockquote: baseStyle.copyWith(fontStyle: FontStyle.italic),
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
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            alignLabelWithHint: true,
            filled: widget.filled,
            fillColor: widget.fillColor,
            border: widget.border,
          ),
        ),
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
