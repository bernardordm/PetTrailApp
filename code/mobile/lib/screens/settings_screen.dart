import 'package:flutter/material.dart';
import 'package:pet_trail/theme/theme_notifier.dart';
import 'package:pet_trail/theme/theme_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.embeddedInShell = false});

  /// Quando true, exibe só o corpo (usado dentro de [MainShellScreen]).
  final bool embeddedInShell;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeNotifier = ThemeScope.of(context);

    final body = ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Aparência',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          _ThemeOption(
            label: 'Claro',
            icon: Icons.light_mode_rounded,
            mode: ThemeMode.light,
            notifier: themeNotifier,
          ),
          _ThemeOption(
            label: 'Escuro',
            icon: Icons.dark_mode_rounded,
            mode: ThemeMode.dark,
            notifier: themeNotifier,
          ),
        ],
    );

    if (embeddedInShell) {
      return ColoredBox(color: cs.surface, child: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: body,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.mode,
    required this.notifier,
  });

  final String label;
  final IconData icon;
  final ThemeMode mode;
  final ThemeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = notifier.mode == mode;

    return ListTile(
      leading: Icon(icon, color: selected ? cs.secondary : cs.onSurfaceVariant),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? cs.secondary : cs.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: cs.secondary)
          : null,
      onTap: () => notifier.setMode(mode),
    );
  }
}
