import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';
import '../../core/notification_service.dart';

class RiskHoursScreen extends ConsumerStatefulWidget {
  const RiskHoursScreen({super.key});

  @override
  ConsumerState<RiskHoursScreen> createState() => _RiskHoursScreenState();
}

class _RiskHoursScreenState extends ConsumerState<RiskHoursScreen> {
  late List<String> _riskHours;

  @override
  void initState() {
    super.initState();
    _riskHours = List.from(ref.read(settingsRepositoryProvider).riskHours);
  }

  void _addWindow() async {
    if (_riskHours.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite de 3 janelas atingido')),
      );
      return;
    }

    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: 'Início do Horário de Risco',
    );

    if (start == null) return;

    if (!mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 2) % 24, minute: start.minute),
      helpText: 'Fim do Horário de Risco',
    );

    if (end == null) return;

    final window = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}-${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    
    setState(() {
      _riskHours.add(window);
    });
    _save();
  }

  void _removeWindow(int index) {
    setState(() {
      _riskHours.removeAt(index);
    });
    _save();
  }

  void _save() {
    ref.read(settingsRepositoryProvider.notifier).updateRiskHours(_riskHours);
    NotificationService.scheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horários de Risco'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Defina janelas de tempo onde você se sente mais vulnerável. O app enviará alertas extras para te manter focado.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            if (_riskHours.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Nenhum horário definido.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: _riskHours.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: ForjaColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: ForjaColors.ember),
                      title: Text(_riskHours[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _removeWindow(index),
                      ),
                    ),
                  );
                },
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _riskHours.length < 3 ? _addWindow : null,
              icon: const Icon(Icons.add),
              label: const Text('ADICIONAR JANELA', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ForjaColors.ember,
                foregroundColor: ForjaColors.onEmber,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Máximo 3 janelas',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
