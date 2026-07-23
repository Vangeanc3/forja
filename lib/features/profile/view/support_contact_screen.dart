import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/features/settings/bloc/settings_bloc.dart';
import 'package:forja/features/settings/bloc/settings_event.dart';

class SupportContactScreen extends StatefulWidget {
  const SupportContactScreen({super.key});

  @override
  State<SupportContactScreen> createState() => _SupportContactScreenState();
}

class _SupportContactScreenState extends State<SupportContactScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsBloc>().state;
    _nameController = TextEditingController(
      text: settings.supportContactName ?? '',
    );
    _phoneController = TextEditingController(
      text: settings.supportContactPhone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }
    context.read<SettingsBloc>().add(
      SettingsSupportContactUpdated(
        name: _nameController.text,
        phone: _phoneController.text,
      ),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contato salvo com sucesso')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contato de Apoio')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escolha uma pessoa de confiança para ligar em momentos de crise.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Contato',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone / WhatsApp',
                hintText: 'Ex: 11999999999',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: ForjaColors.ember,
                foregroundColor: ForjaColors.onEmber,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'SALVAR CONTATO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
