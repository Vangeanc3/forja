import 'package:flutter/material.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';
import 'package:forja/shared/widgets/formatted_text.dart';

class GroupTopicsResult {
  const GroupTopicsResult({
    required this.title,
    required this.description,
    required this.detailIds,
  });

  final String title;
  final String description;
  final Set<String> detailIds;
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    this.color = ForjaColors.ember,
    this.size = 40,
    this.iconSize = 20,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class GroupTopicsSheet extends StatefulWidget {
  const GroupTopicsSheet({
    required this.details,
    this.initialSelectedIds = const <String>{},
    super.key,
  });

  final List<MetricDetailEntity> details;
  final Set<String> initialSelectedIds;

  @override
  State<GroupTopicsSheet> createState() => _GroupTopicsSheetState();
}

class _GroupTopicsSheetState extends State<GroupTopicsSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    final detailIds = widget.details.map((detail) => detail.id).toSet();
    _selectedIds.addAll(widget.initialSelectedIds.intersection(detailIds));
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleAll() {
    setState(() {
      if (_selectedIds.length == widget.details.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(widget.details.map((detail) => detail.id));
      }
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedIds.length < 2) return;

    Navigator.of(context).pop(
      GroupTopicsResult(
        title: title,
        description: _descriptionController.text.trim(),
        detailIds: Set.of(_selectedIds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    final canSubmit =
        _titleController.text.trim().isNotEmpty && _selectedIds.length >= 2;
    final allSelected = _selectedIds.length == widget.details.length;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBadge(icon: Icons.account_tree_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Agrupar tópicos',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome do grupo',
                  hintText: 'Classes de palavras',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              FormattedTextField(
                controller: _descriptionController,
                labelText: 'Descrição',
                hintText: 'Resumo opcional',
                minLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedIds.length} selecionados',
                      style: text.bodySmall?.copyWith(
                        color: ForjaColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAll,
                    child: Text(allSelected ? 'LIMPAR' : 'SELECIONAR TODOS'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.details.length,
                  itemBuilder: (context, index) {
                    final detail = widget.details[index];
                    final checked = _selectedIds.contains(detail.id);

                    return CheckboxListTile(
                      value: checked,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        detail.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: detail.items.isEmpty
                          ? null
                          : Text('${detail.items.length} sub-itens'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedIds.add(detail.id);
                          } else {
                            _selectedIds.remove(detail.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCELAR'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canSubmit ? _submit : null,
                      icon: const Icon(Icons.account_tree_rounded),
                      label: const Text('AGRUPAR'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
