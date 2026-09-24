import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/firebase_options.dart';
import 'package:pet_trail/screens/home_screen.dart';
import 'package:pet_trail/theme/pet_trail_theme.dart';
import 'package:pet_trail/theme/theme_notifier.dart';
import 'package:pet_trail/theme/theme_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (AppConfig.hasMapboxAccessToken) {
    MapboxOptions.setAccessToken(AppConfig.mapboxAccessToken);
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(PetTrailApp(themeNotifier: ThemeNotifier()));
}

class PetTrailApp extends StatefulWidget {
  const PetTrailApp({super.key, required this.themeNotifier});

  final ThemeNotifier themeNotifier;

  @override
  State<PetTrailApp> createState() => _PetTrailAppState();
}

class _PetTrailAppState extends State<PetTrailApp> {
  @override
  void initState() {
    super.initState();
    widget.themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() => setState(() {});

  @override
  void dispose() {
    widget.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      notifier: widget.themeNotifier,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pet Trail',
        theme: petTrailTheme(),
        darkTheme: petTrailDarkTheme(),
        themeMode: widget.themeNotifier.mode,
        home: const HomeScreen(),
      ),
    );
  }
}
