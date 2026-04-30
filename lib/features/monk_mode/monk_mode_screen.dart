import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';
import 'monk_mode_repository.dart';

class MonkModeScreen extends ConsumerStatefulWidget {
  const MonkModeScreen({super.key});

  @override
  ConsumerState<MonkModeScreen> createState() => _MonkModeScreenState();
}

class _MonkModeScreenState extends ConsumerState<MonkModeScreen> {
  late List<String> _selectedRestrictions;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(monkModeRepositoryProvider);
    _isActive = repo.isActive;
    _selectedRestrictions = List.from(repo.activeRestrictions);
  }

  void _toggleRestriction(String restriction) {
    setState(() {
      if (_selectedRestrictions.contains(restriction)) {
        _selectedRestrictions.remove(restriction);
      } else {
        _selectedRestrictions.add(restriction);
      }
    });
  }

  Future<void> _save() async {
    await ref.read(monkModeProvider.notifier).toggle(_isActive, _selectedRestrictions);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações do Modo Monge salvas.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Modo Monge')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ativar Modo Monge', style: text.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Restrições extremas para resultados extremos.',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: ForjaColors.ember,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('RESTRIÇÕES EXTRAS', style: text.labelLarge),
            const SizedBox(height: 16),
            ...kMonkRestrictions.map((restriction) {
              final isSelected = _selectedRestrictions.contains(restriction);
              return CheckboxListTile(
                title: Text(restriction),
                value: isSelected,
                onChanged: _isActive ? (_) => _toggleRestriction(restriction) : null,
                activeColor: ForjaColors.ember,
                contentPadding: EdgeInsets.zero,
                controlType: ListTileControlType.leading,
              );
            }),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: _save,
              child: const Text('SALVAR CONFIGURAÇÕES'),
            ),
          ],
        ),
      ),
    );
  }
}
