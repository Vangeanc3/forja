import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/shared/widgets/formatted_text.dart';

void main() {
  testWidgets('renders markdown lists and emphasis', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forjaDarkTheme,
        home: const Scaffold(
          body: FormattedText(
            data: '''
**Língua Portuguesa**

- Crase
- Concordância
''',
          ),
        ),
      ),
    );

    expect(find.text('Língua Portuguesa'), findsOneWidget);
    expect(find.text('Crase'), findsOneWidget);
    expect(find.text('Concordância'), findsOneWidget);
  });

  testWidgets('renders pasted ChatGPT markdown content', (tester) async {
    const markdown = '''
## Advérbio de tempo

O **advérbio de tempo** indica **quando** uma ação acontece, aconteceu ou acontecerá.

Exemplo:

**João chegou ontem.**

* **chegou** = verbo;
* **ontem** = advérbio de tempo;
* “ontem” informa **quando João chegou**.

### Exemplos comuns

**hoje, ontem, amanhã, agora, cedo, tarde, antes, depois, sempre, nunca, já, ainda, logo, recentemente, antigamente.**

### Em frases

* Estudarei **amanhã**.
* Ela chegou **cedo**.
* Nós **já** terminamos.

```text
Advérbio
└── Tipos de advérbio
    └── Tempo
        ├── Conceito
        └── Locução adverbial de tempo
```
''';

    await tester.pumpWidget(
      MaterialApp(
        theme: forjaDarkTheme,
        home: const Scaffold(body: FormattedText(data: markdown)),
      ),
    );

    expect(find.text('Advérbio de tempo'), findsOneWidget);
    expect(find.text('Exemplos comuns'), findsOneWidget);
    expect(find.text('Em frases'), findsOneWidget);
    expect(find.textContaining('Tipos de advérbio'), findsOneWidget);
  });

  testWidgets('toggles between editing and formatted view', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: forjaDarkTheme,
        home: Scaffold(
          body: FormattedTextField(
            controller: controller,
            labelText: 'Descrição',
            hintText: 'Cole um texto em Markdown',
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '''
## Advérbio de tempo

* Estudarei **amanhã**.
''');
    await tester.pumpAndSettle();

    expect(find.text('VISUALIZAR FORMATADO'), findsOneWidget);

    await tester.tap(find.text('VISUALIZAR FORMATADO'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('EDITAR'), findsOneWidget);
    expect(find.text('Advérbio de tempo'), findsWidgets);

    await tester.tap(find.text('EDITAR'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });
}
