import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/shared/widgets/formatted_text.dart';

const _channel = MethodChannel('plugins.flutter.io/url_launcher');

Future<void> _render(WidgetTester tester, String data) => tester.pumpWidget(
  MaterialApp(
    theme: forjaDarkTheme,
    home: Scaffold(
      body: SingleChildScrollView(child: FormattedText(data: data)),
    ),
  ),
);

void main() {
  final launches = <Map<Object?, Object?>>[];

  setUp(() {
    launches.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          if (call.method == 'launch') {
            launches.add(Map<Object?, Object?>.from(call.arguments as Map));
            return true;
          }
          return false;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  testWidgets('opens named Markdown links externally and preserves the URL', (
    tester,
  ) async {
    const url = 'https://example.com/docs?tema=solid&lang=pt#strategy';
    await _render(tester, '[Documentação]($url)');
    await tester.tapOnText(find.textRange.ofSubstring('Documentação'));
    await tester.pumpAndSettle();
    expect(launches.single['url'], url);
    expect(launches.single['useWebView'], false);
    expect(launches.single['useSafariVC'], false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens bare URLs, www addresses, emails and table links', (
    tester,
  ) async {
    await _render(tester, '''Consulte https://example.com/guia.

- www.example.com
- suporte@example.com

| Material | Link |
| --- | --- |
| Strategy | [Abrir referência](https://example.com/strategy) |
''');
    for (final label in [
      'https://example.com/guia',
      'www.example.com',
      'suporte@example.com',
      'Abrir referência',
    ]) {
      await tester.tapOnText(find.textRange.ofSubstring(label));
      await tester.pumpAndSettle();
    }
    expect(launches.map((call) => call['url']), [
      'https://example.com/guia',
      'http://www.example.com',
      'mailto:suporte@example.com',
      'https://example.com/strategy',
    ]);
  });

  testWidgets('links also open in the selectable editor preview', (
    tester,
  ) async {
    final controller = TextEditingController(
      text: '[Documentação](https://example.com/preview)',
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: forjaDarkTheme,
        home: Scaffold(
          body: FormattedTextField(
            controller: controller,
            labelText: 'Descrição',
            hintText: 'Markdown',
          ),
        ),
      ),
    );
    final position = tester.getTopLeft(find.byType(SelectableText));
    await tester.tapAt(position + const Offset(12, 10));
    await tester.pumpAndSettle();
    expect(launches.single['url'], 'https://example.com/preview');
    expect(controller.text, '[Documentação](https://example.com/preview)');
  });

  testWidgets('shows a message if opening fails or the platform throws', (
    tester,
  ) async {
    for (final throws in [false, true]) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
        call,
      ) async {
        if (throws) throw PlatformException(code: 'unavailable');
        return false;
      });
      await _render(tester, '[Referência](https://example.com)');
      await tester.tapOnText(find.textRange.ofSubstring('Referência'));
      await tester.pump();
      expect(find.text('Não foi possível abrir este link.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Remove the previous snackbar before testing the next platform response.
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
    'URLs in code stay literal and unsupported actions do not launch',
    (tester) async {
      await _render(tester, '''`https://example.com/code`

[Ação](javascript:alert(1))
''');
      await tester.tapOnText(
        find.textRange.ofSubstring('https://example.com/code'),
      );
      await tester.pump();
      expect(launches, isEmpty);
      await tester.tapOnText(find.textRange.ofSubstring('Ação'));
      await tester.pump();
      expect(launches, isEmpty);
      expect(find.text('Não foi possível abrir este link.'), findsOneWidget);
    },
  );
}
