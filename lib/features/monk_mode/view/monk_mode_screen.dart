import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/monk_mode_entity.dart';
import 'package:forja/features/monk_mode/bloc/monk_mode_bloc.dart';
import 'package:forja/features/monk_mode/bloc/monk_mode_event.dart';

class MonkModeScreen extends StatefulWidget {
  const MonkModeScreen({super.key});

  @override
  State<MonkModeScreen> createState() => _MonkModeScreenState();
}

class _MonkModeScreenState extends State<MonkModeScreen> {
  late List<String> _selectedRestrictions;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<MonkModeBloc>().state;
    _isActive = state.active;
    _selectedRestrictions = List.from(state.restrictions);
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
    context.read<MonkModeBloc>().add(
      MonkModeSaved(
        active: _isActive,
        restrictions: List.of(_selectedRestrictions),
      ),
    );
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
                  activeThumbColor: ForjaColors.ember,
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
                onChanged: _isActive
                    ? (_) => _toggleRestriction(restriction)
                    : null,
                activeColor: ForjaColors.ember,
                contentPadding: EdgeInsets.zero,
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
