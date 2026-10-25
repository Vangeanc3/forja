import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/data/repositories/progress_repository.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';
import 'package:forja/features/tasks/bloc/progress_bloc.dart';
import 'package:forja/features/tasks/router/tasks_router.dart';
import 'package:forja/features/tasks/router/tasks_router_map.dart' as tasks;
import 'package:forja/features/tasks/view/metric_detail_form_screen.dart';
import 'package:forja/features/tasks/view/tasks_screen.dart';
import 'package:forja/features/tasks/view/widgets/group_topics_sheet.dart';
import 'package:forja/shared/widgets/browser_back_protection.dart';

const _draft =
    '## Strategy\n\nConteúdo ainda não salvo.\n\n```csharp\nclass Pedido {}\n```';

class _MemoryRepository extends ProgressRepository {
  final areas = <ProgressAreaEntity>[
    ProgressAreaEntity(
      id: 'area',
      title: 'Estudos',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      metrics: [
        ProgressMetricEntity(
          id: 'metric',
          title: 'Engenharia',
          percent: 50,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ],
    ),
  ];

  @override
  List<ProgressAreaEntity> getAll() => List.of(areas);

  @override
  Future<void> addArea({required String title, String description = ''}) async {
    areas.add(
      ProgressAreaEntity(
        id: 'new',
        title: title,
        description: description,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  }
}

Future<(GoRouter, _MemoryRepository)> _mount(WidgetTester tester) async {
  final repository = _MemoryRepository();
  final bloc = ProgressBloc(repository);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Início')),
      ),
      ...tasks.routes,
    ],
  );
  addTearDown(router.dispose);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: BrowserBackProtection(
        child: MaterialApp.router(theme: forjaDarkTheme, routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router, repository);
}

Future<void> _browserBack(WidgetTester tester, GoRouter router) async {
  // The platform history event bypasses Navigator.maybePop / PopScope.
  await router.routeInformationProvider.didPushRouteInformation(
    RouteInformation(uri: Uri.parse('/home')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'browser back preserves description-only edits and repeated back attempts',
    (tester) async {
      final (router, _) = await _mount(tester);
      router.push(TasksRouter.newArea);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), _draft);
      for (var i = 0; i < 3; i++) {
        await _browserBack(tester, router);
        expect(find.byType(ProgressAreaFormScreen), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byType(TextField).at(1))
              .controller!
              .text,
          _draft,
        );
      }
      expect(
        find.textContaining('Você tem alterações não salvas.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('clean forms can navigate back through browser history', (
    tester,
  ) async {
    final (router, _) = await _mount(tester);
    router.push(TasksRouter.newArea);
    await tester.pumpAndSettle();
    await _browserBack(tester, router);
    expect(find.text('Início'), findsOneWidget);
    expect(find.byType(ProgressAreaFormScreen), findsNothing);
  });

  testWidgets(
    'saving after a blocked back keeps the data and closes the form',
    (tester) async {
      final (router, repository) = await _mount(tester);
      router.push(TasksRouter.newArea);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'SOLID');
      await tester.enterText(find.byType(TextField).at(1), _draft);
      await _browserBack(tester, router);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SALVAR ÁREA'));
      await tester.tap(find.text('SALVAR ÁREA'));
      await tester.pumpAndSettle();
      expect(find.text('Início'), findsOneWidget);
      expect(repository.areas.last.title, 'SOLID');
      expect(repository.areas.last.description, _draft);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the app back button still asks before discarding', (
    tester,
  ) async {
    final (router, _) = await _mount(tester);
    router.push(TasksRouter.newArea);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Não perder');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressAreaFormScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair sem salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Início'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a nested topic draft blocks browser removal of its clean parent form',
    (tester) async {
      final (router, _) = await _mount(tester);
      router.push(TasksRouter.editMetricLocation('area', 'metric'));
      await tester.pumpAndSettle();
      final navigator = Navigator.of(
        tester.element(find.byType(ProgressMetricFormScreen)),
      );
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const MetricDetailFormScreen()),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), _draft);
      await _browserBack(tester, router);
      expect(find.byType(MetricDetailFormScreen), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        _draft,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('grouping-sheet text also blocks browser navigation', (
    tester,
  ) async {
    final (router, _) = await _mount(tester);
    router.push(TasksRouter.editMetricLocation('area', 'metric'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ProgressMetricFormScreen));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const GroupTopicsSheet(details: []),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Grupo em edição');
    await _browserBack(tester, router);
    expect(find.byType(GroupTopicsSheet), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Grupo em edição',
    );
    expect(tester.takeException(), isNull);
  });
}
