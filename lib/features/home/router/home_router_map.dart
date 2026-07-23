import 'package:forja/features/home/router/home_router.dart';
import 'package:forja/features/home/bloc/home_bloc.dart';
import 'package:forja/features/home/view/home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: HomeRouter.initial,
    name: HomeRouter.name,
    builder: (context, state) =>
        BlocProvider(create: (_) => HomeBloc(), child: const HomeScreen()),
  ),
];
