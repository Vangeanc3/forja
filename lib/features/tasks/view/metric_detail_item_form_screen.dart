import 'package:flutter/material.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';

class MetricDetailItemFormScreen extends StatefulWidget {
  const MetricDetailItemFormScreen({
    super.key,
    this.initialItem,
  });

  final MetricDetailItemEntity? initialItem;

  @override
  State<MetricDetailItemFormScreen> createState() => _MetricDetailItemFormScreenState();
}

class _MetricDetailItemFormScreenState extends State<MetricDetailItemFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialItem?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialItem?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    final initialTitle = widget.initialItem?.title ?? '';
    final initialDescription = widget.initialItem?.description ?? '';
    return _titleController.text.trim() != initialTitle ||
        _descriptionController.text.trim() != initialDescription;
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
        const SnackBar(content: Text('O título do item é obrigatório')),
      );
      return;
    }

    final item = MetricDetailItemEntity(
      id: widget.initialItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: _descriptionController.text.trim(),
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(widget.initialItem == null ? 'Novo Item de Conteúdo' : 'Editar Item'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'SALVAR',
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
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Título do Item',
              hintText: 'Ex: Conceito, Requisitos, etc.',
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: widget.initialItem == null,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Explicação / Conteúdo',
              hintText: 'Escreva detalhadamente sobre este item...',
              alignLabelWithHint: true,
            ),
            minLines: 5,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),
          Text(
            'Dica: Use este espaço para colocar a explicação que você quer lembrar sobre este tópico específico.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ForjaColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
}
