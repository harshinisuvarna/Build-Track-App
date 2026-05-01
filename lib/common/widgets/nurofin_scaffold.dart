import 'package:buildtrack_mobile/common/widgets/nurofin_background.dart';
import 'package:flutter/material.dart';

/// Drop-in replacement for [Scaffold] that automatically paints the
/// Nurofin 4-layer background behind the content.
///
/// Usage:
/// ```dart
/// NurofinScaffold(
///   appBar: AppBar(title: const Text('Dashboard')),
///   body: …,
///   bottomNavigationBar: const AppBottomNav(),
/// )
/// ```
class NurofinScaffold extends StatelessWidget {
  const NurofinScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return NurofinBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}
