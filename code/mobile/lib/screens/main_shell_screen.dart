import 'package:flutter/material.dart';
import 'package:pet_trail/screens/dashboard_screen.dart';
import 'package:pet_trail/screens/home_screen.dart';
import 'package:pet_trail/screens/pets_screen.dart';
import 'package:pet_trail/screens/profile_screen.dart';
import 'package:pet_trail/screens/settings_screen.dart';
import 'package:pet_trail/screens/tours_screen.dart';
import 'package:pet_trail/widgets/pet_trail_auth_shell.dart';
import 'package:pet_trail/screens/reports_screen.dart';

/// Shell principal após login: mapa e demais áreas com [NavigationBar] fixo no rodapé.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.identifier,
    required this.name,
    required this.email,
    required this.role,
    required this.accessToken,
  });

  final String identifier;
  final String name;
  final String email;
  final String role;
  final String accessToken;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

  bool get _isWalker => widget.role == 'walker';

  String get _appBarTitle {
    if (_isWalker) {
      return switch (_index) {
        0 => 'Pet Trail',
        1 => 'Dashboard',
        2 => 'Meus Passeios',
        3 => 'Meu Perfil',
        _ => 'Ajustes',
      };
    }
    return switch (_index) {
      0 => 'Pet Trail',
      1 => 'Meus Pets',
      2 => 'Meus Passeios',
      3 => 'Meu Perfil',
      _ => 'Ajustes',
    };
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final destinations = _isWalker
        ? <({IconData icon, String label})>[
            (icon: Icons.explore_rounded, label: 'Início'),
            (icon: Icons.bar_chart_rounded, label: 'Dashboard'),
            (icon: Icons.route_rounded, label: 'Passeios'),
            (icon: Icons.person_outline_rounded, label: 'Perfil'),
            (icon: Icons.settings_outlined, label: 'Ajustes'),
          ]
        : <({IconData icon, String label})>[
            (icon: Icons.explore_rounded, label: 'Início'),
            (icon: Icons.pets_rounded, label: 'Pets'),
            (icon: Icons.route_rounded, label: 'Passeios'),
            (icon: Icons.person_outline_rounded, label: 'Perfil'),
            (icon: Icons.settings_outlined, label: 'Ajustes'),
          ];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            kPetTrailLogoAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.pets_rounded, color: cs.secondary),
          ),
        ),
        title: Text(
          _appBarTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: cs.secondary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _isWalker ? _walkerPages : _tutorPages,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: cs.secondary.withValues(alpha: 0.28),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? cs.secondary : cs.onSurfaceVariant,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? cs.secondary : cs.onSurfaceVariant,
              size: selected ? 28 : 24,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          height: 72,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          elevation: 8,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      ),
    );
  }

  List<Widget> get _walkerPages => [
    DashboardScreen(
      identifier: widget.identifier,
      name: widget.name,
      email: widget.email,
      role: widget.role,
      accessToken: widget.accessToken,
    ),

    ReportsScreen(accessToken: widget.accessToken),

    ToursScreen(
      identifier: widget.identifier,
      role: widget.role,
      accessToken: widget.accessToken,
      embeddedInShell: true,
    ),

    ProfileScreen(
      identifier: widget.identifier,
      name: widget.name,
      email: widget.email,
      role: widget.role,
      accessToken: widget.accessToken,
      embeddedInShell: true,
    ),

    const SettingsScreen(embeddedInShell: true),
  ];

  List<Widget> get _tutorPages => [
    DashboardScreen(
      identifier: widget.identifier,
      name: widget.name,
      email: widget.email,
      role: widget.role,
      accessToken: widget.accessToken,
    ),
    PetsScreen(
      accessToken: widget.accessToken,
      tutorId: widget.identifier,
      embeddedInShell: true,
    ),
    ToursScreen(
      identifier: widget.identifier,
      role: widget.role,
      accessToken: widget.accessToken,
      embeddedInShell: true,
    ),
    ProfileScreen(
      identifier: widget.identifier,
      name: widget.name,
      email: widget.email,
      role: widget.role,
      accessToken: widget.accessToken,
      embeddedInShell: true,
    ),
    const SettingsScreen(embeddedInShell: true),
  ];
}
