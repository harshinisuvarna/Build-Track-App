import 'package:flutter/material.dart';
class NavController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  static const _routes = {
    0: '/home',
    1: '/projects',
    2: '/add-entry',
    3: '/inventory',
    4: '/reports',
  };
  void setIndex(int newIndex, BuildContext context) {
    if (_index == newIndex) return;
    _index = newIndex;
    notifyListeners();
    final route = _routes[newIndex];
    if (route == null) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (r) => false,
    );
  }
}
