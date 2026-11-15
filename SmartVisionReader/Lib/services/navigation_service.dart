
import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final NavigationService instance =
      NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  NavigatorState? get _navigator =>
      navigatorKey.currentState;

  // Navigate to a new screen
  Future<T?> navigateTo<T extends Object?>(
    Widget screen,
  ) {
    final navigator = _navigator;

    if (navigator == null) {
      return Future<T?>.value(null);
    }

    return navigator.push<T>(
      MaterialPageRoute<T>(
        builder: (_) => screen,
      ),
    );
  }

  // Replace the current screen
  Future<T?> replaceWith<T extends Object?>(
    Widget screen,
  ) {
    final navigator = _navigator;

    if (navigator == null) {
      return Future<T?>.value(null);
    }

    return navigator.pushReplacement<T, Object?>(
      MaterialPageRoute<T>(
        builder: (_) => screen,
      ),
    );
  }

  // Go back to the previous screen
  void goBack<T extends Object?>([T? result]) {
    final navigator = _navigator;

    if (navigator != null && navigator.canPop()) {
      navigator.pop<T>(result);
    }
  }

  // Check whether the previous screen exists
  bool get canGoBack =>
      _navigator?.canPop() ?? false;
}
