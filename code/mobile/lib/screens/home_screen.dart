import 'package:flutter/material.dart';
import 'package:pet_trail/screens/login_screen.dart';
import 'package:pet_trail/screens/register_screen.dart';
import 'package:pet_trail/widgets/pet_trail_auth_shell.dart';

/// Abertura do app — linguagem de marketplace (tutor ↔ passeador).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PetTrailAuthShell(
      showBackButton: false,
      heroBackgroundAsset: kPetTrailHomeHeroBackgroundAsset,
      heroFlex: 54,
      cardFlex: 46,
      cardOverlap: 12,
      cardBodyTopPadding: 20,
      cardBody: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.near_me_rounded, size: 18, color: cs.secondary),
              const SizedBox(width: 6),
              Text(
                'Passeios perto de você',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Peça um passeio em minutos',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Conecte tutores a passeadores verificados — simples, rápido e com rastreio do passeio.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Entrar na minha conta'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const RegisterScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Quero me cadastrar'),
          ),
          const SizedBox(height: 20),
          Text(
            'Termos · Privacidade',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
