import 'package:flutter/material.dart';
import 'theme_notifier.dart';

class ThemeScope extends InheritedWidget {
  const ThemeScope({
    super.key,
    required this.notifier,
    required super.child,
  });

  final ThemeNotifier notifier;

  static ThemeNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    return scope!.notifier;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) => notifier != oldWidget.notifier;
}
