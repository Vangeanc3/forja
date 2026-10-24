import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/shared/widgets/formatted_text.dart';
import 'package:forja/shared/widgets/markdown_code_block.dart';

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
        home: const Scaffold(
          body: SingleChildScrollView(child: FormattedText(data: markdown)),
        ),
      ),
    );

    expect(find.text('Advérbio de tempo'), findsOneWidget);
    expect(find.text('Exemplos comuns'), findsOneWidget);
    expect(find.text('Em frases'), findsOneWidget);
    expect(find.textContaining('Tipos de advérbio'), findsOneWidget);
  });

  testWidgets('highlights C# and copies code without losing indentation', (
    tester,
  ) async {
    const source = '''public class Funcionario
{
    // Atende ao Financeiro / Contabilidade
    public decimal CalcularSalario() { return 100m; }
}''';
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: forjaDarkTheme,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: FormattedText(data: '```csharp\n$source\n```'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('csharp'), findsOneWidget);
    final code = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(code.textSpan!.toPlainText(), source);
    final colors = <Color>{};
    bool collectColors(InlineSpan span) {
      if (span.style?.color case final color?) colors.add(color);
      span.visitDirectChildren(collectColors);
      return true;
    }

    collectColors(code.textSpan!);
    expect(colors.length, greaterThanOrEqualTo(3));
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView).first,
    );
    expect(scroll.scrollDirection, Axis.horizontal);
    expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));
    await tester.tap(find.text('Copiar'));
    await tester.pump();
    expect(copied, source);
    expect(find.text('Código copiado'), findsOneWidget);
  });

  testWidgets('renders nested lists, quotes, inline code and GFM tables', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forjaDarkTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: FormattedText(
              data: '''### Resumo para Concursos

> **Uma classe deve ter um motivo para mudar.**

* **Sintomas de Violação:**
  * **God Class / Blob:** Classes gigantescas.
  * **Baixa Coesão:** Assuntos desconexos.

1. Financeiro muda a regra em `Funcionario`.
2. RH altera horas extras.

---

| Ator | Responsabilidade |
| :--- | ---: |
| Financeiro | Calcular salário |
| RH | Registrar horas |
''',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Resumo para Concursos'), findsOneWidget);
    expect(
      find.textContaining('Classes gigantescas.', findRichText: true),
      findsWidgets,
    );
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('•'), findsNWidgets(3));
    expect(find.byType(Table), findsOneWidget);
    final parent = tester.getTopLeft(find.text('•').first);
    final nested = tester.getTopLeft(find.text('•').at(1));
    expect(nested.dx, greaterThan(parent.dx));
    expect(find.byType(MarkdownCodeBlock), findsNothing);
  });

  testWidgets('preserves aligned plain text and unknown code languages', (
    tester,
  ) async {
    const aligned = 'Árvore\n├── SRP\n│   └── Um ator\n└── SOLID';
    for (final language in ['', 'text', 'linguagem-desconhecida']) {
      await tester.pumpWidget(
        MaterialApp(
          theme: forjaDarkTheme,
          home: Scaffold(
            body: FormattedText(data: '```$language\n$aligned\n```'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final code = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(code.textSpan!.toPlainText(), aligned);
    }
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

    const pasted = '''
## Advérbio de tempo

* Estudarei **amanhã**.

```csharp
public class Funcionario
{
    public string Nome = "João";
}
```
''';
    await tester.enterText(find.byType(TextField), pasted);
    await tester.pumpAndSettle();

    expect(find.text('VISUALIZAR FORMATADO'), findsOneWidget);

    await tester.tap(find.text('VISUALIZAR FORMATADO'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('EDITAR'), findsOneWidget);
    expect(find.text('Advérbio de tempo'), findsWidgets);
    expect(find.byType(MarkdownCodeBlock), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);

    await tester.tap(find.text('EDITAR'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(controller.text, pasted);
  });
}
