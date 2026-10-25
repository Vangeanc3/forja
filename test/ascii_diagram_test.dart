import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/shared/widgets/ascii_diagram.dart';
import 'package:forja/shared/widgets/formatted_text.dart';
import 'package:forja/shared/widgets/markdown_code_block.dart';

final _source = File('test/fixtures/strategy_diagram.txt').readAsStringSync();

Future<void> _render(
  WidgetTester tester,
  String markdown, {
  double width = 320,
}) => tester.pumpWidget(
  MaterialApp(
    theme: forjaDarkTheme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: width,
          child: FormattedText(data: markdown),
        ),
      ),
    ),
  ),
);

void main() {
  test('recognizes the four Strategy nodes and both relationships', () {
    final diagram = AsciiDiagram.tryParse(_source)!;
    expect(diagram.nodes, hasLength(4));
    expect(diagram.nodes.map((node) => node.labels), [
      ['Context', '(PedidoService)'],
      ['<<Interface>>', 'IStrategy'],
      ['ConcreteStrategyA', '(FreteSedex)'],
      ['ConcreteStrategyB', '(FretePac)'],
    ]);
    expect(diagram.connections, hasLength(2));
    final association = diagram.connections.singleWhere((edge) => edge.diamond);
    expect(association.nodes.toSet(), {0, 1});
    expect(association.target, 1);
    expect(association.arrow, DiagramArrow.open);
    final inheritance = diagram.connections.singleWhere(
      (edge) => !edge.diamond,
    );
    expect(inheritance.nodes.toSet(), {1, 2, 3});
    expect(inheritance.target, 1);
    expect(inheritance.arrow, DiagramArrow.triangle);
  });

  test(
    'recognition uses the structure rather than Strategy-specific labels',
    () {
      final renamed = _source
          .replaceAll('Context', 'Cliente')
          .replaceAll('IStrategy', 'IContrato');
      final diagram = AsciiDiagram.tryParse(renamed)!;
      expect(diagram.nodes.first.labels.first, 'Cliente');
      expect(diagram.nodes[1].labels.last, 'IContrato');
      expect(diagram.connections, hasLength(2));
    },
  );

  test(
    'leaves ordinary text and incomplete or unsupported diagrams intact',
    () {
      for (final source in [
        'Árvore\n├── SRP\n│   └── Um ator\n└── SOLID',
        '+-----+\n| Foo |',
        '+-----+\n| Foo |\n+-----+\nEste texto não deve desaparecer.',
        '+-----+ --> destino sem caixa\n| Foo |\n+-----+',
      ]) {
        expect(AsciiDiagram.tryParse(source), isNull);
      }
    },
  );

  testWidgets(
    'shows visual cards on mobile and toggles back to the exact text',
    (tester) async {
      await _render(tester, '```text\n$_source```');
      expect(tester.takeException(), isNull);
      expect(find.byType(AsciiDiagramView), findsOneWidget);
      expect(find.text('Context'), findsOneWidget);
      expect(find.text('IStrategy'), findsOneWidget);
      expect(find.text('(FreteSedex)'), findsOneWidget);
      expect(find.text('(FretePac)'), findsOneWidget);
      await tester.tap(find.byTooltip('Ver texto original'));
      await tester.pumpAndSettle();
      expect(find.byType(AsciiDiagramView), findsNothing);
      final text = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(text.textSpan!.toPlainText(), _source.trimRight());
      await tester.tap(find.byTooltip('Ver diagrama'));
      await tester.pumpAndSettle();
      expect(find.byType(AsciiDiagramView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('expands the diagram with pan and zoom and closes it', (
    tester,
  ) async {
    await _render(tester, '```text\n$_source```');
    await tester.tap(find.byTooltip('Ampliar diagrama'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.byType(AsciiDiagramView), findsOneWidget);
  });

  testWidgets('copy preserves ASCII and code languages are never converted', (
    tester,
  ) async {
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
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _render(tester, '```text\n$_source```');
    await tester.tap(find.text('Copiar'));
    await tester.pump();
    expect(copied, _source.trimRight());
    await _render(tester, '```csharp\n$_source```');
    expect(find.byType(AsciiDiagramView), findsNothing);
    expect(find.byType(MarkdownCodeBlock), findsOneWidget);
  });

  testWidgets('supports accessibility text scaling without overflowing cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: forjaDarkTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: FormattedText(data: '```text\n$_source```'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(AsciiDiagramView), findsOneWidget);
  });
}
