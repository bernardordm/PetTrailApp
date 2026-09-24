import 'package:flutter/material.dart';

/// Hero padrão (login, cadastro e telas de auth).
const String kPetTrailHeroBackgroundAsset = 'assets/images/background1.jpg';

/// Hero da tela inicial (boas-vindas).
const String kPetTrailHomeHeroBackgroundAsset = 'assets/images/background2.jpg';

/// Logo do app (coloque o arquivo em `assets/images/`, ex.: logo.png).
const String kPetTrailLogoAsset = 'assets/images/logo.png';

/// Fundo atrás do hero (tom “mapa / app de corrida”, não azul clínico).
const Color kPetTrailInk = Color(0xFF111827);

InputDecoration petTrailInputDecoration(
  ColorScheme cs, {
  required String label,
  String? hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  final isDark = cs.brightness == Brightness.dark;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: TextStyle(color: cs.onSurfaceVariant),
    labelStyle: TextStyle(color: cs.onSurfaceVariant),
    prefixIcon: Icon(icon, color: cs.onSurfaceVariant),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

/// Layout hero (foto + vinheta escura) + cartão inferior — login, cadastro e abertura.
class PetTrailAuthShell extends StatelessWidget {
  const PetTrailAuthShell({
    super.key,
    required this.cardBody,
    this.showBackButton = true,
    this.heroFlex = 46,
    this.cardFlex = 54,
    this.heroBackgroundAsset = kPetTrailHeroBackgroundAsset,
    this.cardOverlap = 28,
    this.cardBodyTopPadding = 32,
    this.showLogo = true,
  });

  final Widget cardBody;
  final bool showBackButton;
  final int heroFlex;
  final int cardFlex;
  final String heroBackgroundAsset;

  /// Quanto o cartão sobrepõe o hero (valores menores = cartão mais “embaixo”).
  final double cardOverlap;

  /// Espaço acima do conteúdo dentro do cartão.
  final double cardBodyTopPadding;

  /// Logo no canto superior direito do hero (home, login, cadastro).
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: kPetTrailInk,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: heroFlex,
            child: _HeroLayer(
              colorScheme: cs,
              showBackButton: showBackButton,
              showLogo: showLogo,
              backgroundAsset: heroBackgroundAsset,
            ),
          ),
          Expanded(
            flex: cardFlex,
            child: Transform.translate(
              offset: Offset(0, -cardOverlap),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 32,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: DefaultTextStyle(
                    style: TextStyle(color: cs.onSurface),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, cardBodyTopPadding, 24, 24 + bottomInset),
                      child: cardBody,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLayer extends StatelessWidget {
  const _HeroLayer({
    required this.colorScheme,
    required this.showBackButton,
    required this.showLogo,
    required this.backgroundAsset,
  });

  final ColorScheme colorScheme;
  final bool showBackButton;
  final bool showLogo;
  final String backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          backgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: colorScheme.primaryContainer,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.55),
                kPetTrailInk.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        if (showLogo)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  kPetTrailLogoAsset,
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.pets_rounded,
                    size: 36,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        if (showBackButton)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 8,
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Image.asset(
                kPetTrailLogoAsset,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.pets_rounded, color: Colors.white),
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pet Trail',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.05,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Passeadores confiáveis, quando seu pet precisar sair.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botão de voltar com a patinha do logo — use como [AppBar.leading].
class PawBackButton extends StatelessWidget {
  const PawBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: Image.asset(
        kPetTrailLogoAsset,
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.pets_rounded,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
