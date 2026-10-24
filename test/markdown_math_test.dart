import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/shared/widgets/formatted_text.dart';
import 'package:forja/shared/widgets/markdown_code_block.dart';

const _expression =
    r'\text{Identificar Code Smell} \longrightarrow \text{Aplicar Técnica de Refatoração}';

Future<void> _render(WidgetTester tester, String data) => tester.pumpWidget(
  MaterialApp(
    theme: forjaDarkTheme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(width: 320, child: FormattedText(data: data)),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders the reported text and arrow as display LaTeX', (
    tester,
  ) async {
    await _render(tester, '\$\$$_expression\$\$');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final math = tester.widget<Math>(find.byType(Math));
    expect(math.parseError, isNull);
    expect(math.ast, isNotNull);
    expect(math.mathStyle, MathStyle.display);
    final horizontal = tester
        .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .where((scroll) => scroll.scrollDirection == Axis.horizontal);
    expect(horizontal, hasLength(1));
    final position = Scrollable.of(tester.element(find.byType(Math))).position;
    expect(position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('supports multiline dollars and bracket display delimiters', (
    tester,
  ) async {
    for (final data in ['\$\$\n$_expression\n\$\$', '\\[\n$_expression\n\\]']) {
      await _render(tester, 'Antes\n\n$data\n\nDepois');
      expect(tester.takeException(), isNull);
      expect(find.text('Antes'), findsOneWidget);
      expect(find.text('Depois'), findsOneWidget);
      final math = tester.widget<Math>(find.byType(Math));
      expect(math.parseError, isNull);
      expect(math.mathStyle, MathStyle.display);
    }
  });

  testWidgets('supports inline math within lists and formatted paragraphs', (
    tester,
  ) async {
    await _render(tester, r'''
**Fórmulas:** $x_1^2$ e \(\frac{a}{b}\).

- Resultado: $\sqrt{4}=2$
''');
    expect(tester.takeException(), isNull);
    final formulas = tester.widgetList<Math>(find.byType(Math)).toList();
    expect(formulas, hasLength(3));
    for (final formula in formulas) {
      expect(formula.parseError, isNull);
      expect(formula.mathStyle, MathStyle.text);
    }
  });

  testWidgets('keeps LaTeX inside fenced and inline code literal', (
    tester,
  ) async {
    await _render(tester, '''```text
\$\$$_expression\$\$
```

`\$x^2\$`
''');
    expect(tester.takeException(), isNull);
    expect(find.byType(Math), findsNothing);
    final code = tester.widget<MarkdownCodeBlock>(
      find.byType(MarkdownCodeBlock),
    );
    expect(code.source, '\$\$$_expression\$\$');
    expect(find.text(r'$x^2$'), findsOneWidget);
  });

  testWidgets('preserves currency, escaped dollars and unclosed delimiters', (
    tester,
  ) async {
    await _render(tester, r'''
Preço: R$ 10 e R$ 20. Literal: \$x\$.

$$sem fechamento

```text
continua visível
```
''');
    expect(tester.takeException(), isNull);
    expect(find.byType(Math), findsNothing);
    expect(find.byType(MarkdownCodeBlock), findsOneWidget);
    expect(find.textContaining('sem fechamento'), findsOneWidget);
  });

  testWidgets('shows original expression when LaTeX is invalid', (
    tester,
  ) async {
    await _render(tester, r'$$\comandoInexistente{teste}$$');
    expect(tester.takeException(), isNull);
    expect(find.text(r'\comandoInexistente{teste}'), findsOneWidget);
  });

  testWidgets('previews formulas and preserves the original editor text', (
    tester,
  ) async {
    final original = '\$\$$_expression\$\$';
    final controller = TextEditingController(text: original);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: forjaDarkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FormattedTextField(
              controller: controller,
              labelText: 'Descrição',
              hintText: 'Markdown',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Math), findsOneWidget);
    await tester.tap(find.text('EDITAR'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(controller.text, original);
  });
}
