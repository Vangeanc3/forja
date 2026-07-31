import 'package:flutter/material.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';
import 'package:forja/shared/widgets/formatted_text.dart';

class MetricDetailFormScreen extends StatefulWidget {
  const MetricDetailFormScreen({super.key, this.initialDetail});

  final MetricDetailEntity? initialDetail;

  @override
  State<MetricDetailFormScreen> createState() => _MetricDetailFormScreenState();
}

class _MetricDetailFormScreenState extends State<MetricDetailFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late MetricDetailType _type;
  final List<MetricDetailEntity> _items = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialDetail?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialDetail?.description ?? '',
    );
    _type = widget.initialDetail?.type ?? MetricDetailType.topic;

    if (widget.initialDetail != null) {
      _items.addAll(widget.initialDetail!.items);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addOrEditItem([int? index]) async {
    final initialItem = index != null ? _items[index] : null;

    final result = await Navigator.of(context).push<MetricDetailEntity>(
      MaterialPageRoute(
        builder: (context) =>
            MetricDetailFormScreen(initialDetail: initialItem),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (index != null) {
          _items[index] = result;
        } else {
          _items.add(result);
        }
      });
    }
  }

  Future<void> _removeItem(int index) async {
    final title = _items[index].title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ForjaColors.surface,
        title: const Text('Remover item?'),
        content: Text('Deseja remover o item "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ForjaColors.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  void _onReorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  bool _hasChanges() {
    final initialTitle = widget.initialDetail?.title ?? '';
    final initialDescription = widget.initialDetail?.description ?? '';
    final initialType = widget.initialDetail?.type ?? MetricDetailType.topic;
    final initialItems = widget.initialDetail?.items ?? [];

    if (_titleController.text.trim() != initialTitle) return true;
    if (_descriptionController.text.trim() != initialDescription) return true;
    if (_type != initialType) return true;

    if (_items.length != initialItems.length) return true;
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final initialItem = initialItems[i];
      if (item.id != initialItem.id ||
          item.title != initialItem.title ||
          item.description != initialItem.description ||
          item.type != initialItem.type ||
          item.items.length != initialItem.items.length) {
        return true;
      }
    }

    return false;
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ForjaColors.surface,
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Você tem alterações não salvas. Deseja realmente sair?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ForjaColors.error),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O título do tópico é obrigatório')),
      );
      return;
    }

    final detail = MetricDetailEntity(
      id:
          widget.initialDetail?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: _descriptionController.text.trim(),
      type: _type,
      items: List.from(_items),
    );

    Navigator.of(context).pop(detail);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (!_hasChanges()) {
          Navigator.of(context).pop();
          return;
        }

        final bool shouldPop = await _showDiscardDialog() ?? false;
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initialDetail == null ? 'Novo Tópico' : 'Editar Tópico',
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text(
                'PRONTO',
                style: TextStyle(
                  color: ForjaColors.ember,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'INFORMAÇÕES DO TÓPICO',
              style: text.labelSmall?.copyWith(
                color: ForjaColors.ember,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MetricDetailType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo do Item'),
              items: MetricDetailType.values.map((type) {
                return DropdownMenuItem(value: type, child: Text(type.label));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nome / Título',
                hintText: 'Ex: Prisão Preventiva, Crase, etc.',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            FormattedTextField(
              controller: _descriptionController,
              labelText: 'Breve explicação geral',
              hintText: 'Resumo sobre o que é este tópico',
              minLines: 2,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTEÚDO DETALHADO',
                        style: text.labelSmall?.copyWith(
                          color: ForjaColors.ember,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adicione conceitos, regras ou observações.',
                        style: text.bodySmall?.copyWith(
                          color: ForjaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _addOrEditItem(),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: ForjaColors.ember,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              _EmptyState(onAdd: () => _addOrEditItem())
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                onReorder: _onReorderItems,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _ItemCard(
                    key: ValueKey(item.id),
                    item: item,
                    onTap: () => _addOrEditItem(index),
                    onRemove: () => _removeItem(index),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final MetricDetailEntity item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ForjaColors.divider.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type.label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: ForjaColors.ember,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.items.isNotEmpty)
                        Text(
                          '${item.items.length} sub-itens',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ForjaColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: ForjaColors.error,
                  visualDensity: VisualDensity.compact,
                ),
                const Icon(
                  Icons.drag_indicator_rounded,
                  color: ForjaColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(
              Icons.format_list_bulleted_rounded,
              size: 48,
              color: ForjaColors.divider,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum sub-item ainda.',
              style: TextStyle(color: ForjaColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAdd,
              child: const Text('ADICIONAR SUB-ITEM'),
            ),
          ],
        ),
      ),
    );
  }
}
