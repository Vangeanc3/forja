import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Complements PopScope: browser history changes are handled by GoRoute.onExit.
class BrowserBackProtection extends StatefulWidget {
  const BrowserBackProtection({super.key, required this.child});

  final Widget child;

  static bool onExit(BuildContext context, GoRouterState state) {
    final scope = context
        .getInheritedWidgetOfExactType<_BrowserBackScope>()
        ?.state;
    return scope?.canExit(state.pageKey) ?? true;
  }

  @override
  State<BrowserBackProtection> createState() => _BrowserBackProtectionState();
}

class _BrowserBackProtectionState extends State<BrowserBackProtection> {
  final _editors = <_BrowserBackGuardState>{};

  bool canExit(ValueKey<String> pageKey) {
    final dirty = _editors.where(
      (editor) =>
          editor.mounted &&
          editor._pageKey == pageKey &&
          editor.widget.hasChanges(),
    );
    if (dirty.isEmpty) return true;

    final messenger = ScaffoldMessenger.maybeOf(dirty.last.context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Você tem alterações não salvas. Salve ou cancele a edição antes de voltar.',
          ),
        ),
      );
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      _BrowserBackScope(state: this, child: widget.child);
}

class _BrowserBackScope extends InheritedWidget {
  const _BrowserBackScope({required this.state, required super.child});
  final _BrowserBackProtectionState state;

  @override
  bool updateShouldNotify(_BrowserBackScope oldWidget) =>
      oldWidget.state != state;
}

class BrowserBackGuard extends StatefulWidget {
  const BrowserBackGuard({
    super.key,
    required this.hasChanges,
    required this.child,
    this.canPop = true,
    this.onPopInvokedWithResult,
  });

  /// Read at navigation time, including edits that have not rebuilt the page.
  final bool Function() hasChanges;
  final Widget child;
  final bool canPop;
  final PopInvokedWithResultCallback<Object?>? onPopInvokedWithResult;

  @override
  State<BrowserBackGuard> createState() => _BrowserBackGuardState();
}

class _BrowserBackGuardState extends State<BrowserBackGuard> {
  _BrowserBackProtectionState? _scope;
  ValueKey<String>? _pageKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context
        .dependOnInheritedWidgetOfExactType<_BrowserBackScope>()
        ?.state;
    if (_scope != scope) {
      _scope?._editors.remove(this);
      _scope = scope;
      _scope?._editors.add(this);
    }
    final settings = ModalRoute.of(context)?.settings;
    // Pageless topic editors and sheets belong to the routed form underneath.
    _pageKey = settings is Page && settings.key is ValueKey<String>
        ? settings.key as ValueKey<String>
        : GoRouter.maybeOf(
            context,
          )?.routerDelegate.currentConfiguration.last.pageKey;
  }

  @override
  void dispose() {
    _scope?._editors.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: widget.canPop,
    onPopInvokedWithResult: widget.onPopInvokedWithResult,
    child: widget.child,
  );
}
