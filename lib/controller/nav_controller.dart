import 'package:flutter/material.dart';

/// Central navigation controller for the 5-tab bottom nav.
///
/// Uses [Navigator.pushNamedAndRemoveUntil] so that switching tabs always
/// clears the entire back-stack — no stale routes pile up.
class NavController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  /// Map from tab index → named route.
  static const _routes = {
    0: '/home',
    1: '/projects',
    2: '/add-entry',
    3: '/inventory',
    4: '/reports',
  };

  /// Call this from [AppBottomNav] whenever the user taps a tab.
  void setIndex(int newIndex, BuildContext context) {
    // Prevent no-op navigation when the user taps the already-active tab.
    if (_index == newIndex) return;

    _index = newIndex;
    notifyListeners();

    final route = _routes[newIndex];
    if (route == null) return;

    // Remove everything below the new screen so the back button never
    // takes the user back to a previously selected tab.
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (r) => false, // remove all previous routes
    );
  }
}
