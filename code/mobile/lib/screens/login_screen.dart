import 'package:flutter/material.dart';
import 'package:pet_trail/data/repositories/auth_repository_impl.dart';
import 'package:pet_trail/data/services/auth_api_service.dart';
import 'package:pet_trail/presentation/controllers/auth_controller.dart';
import 'package:pet_trail/screens/main_shell_screen.dart';
import 'package:pet_trail/screens/register_screen.dart';
import 'package:pet_trail/widgets/pet_trail_auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _authController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      AuthRepositoryImpl(AuthApiService()),
    )..addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final error = _authController.consumeError();
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
    setState(() {});
  }

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final user = await _authController.login(email: email, password: password);
    if (!mounted || user == null) return;

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       user.name.isNotEmpty
    //           ? 'Bem-vindo, ${user.name} (${user.role == 'walker' ? 'passeador' : 'dono'})!'
    //           : 'Login realizado com sucesso.',
    //     ),
    //   ),
    // );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => MainShellScreen(
          identifier: user.identifier,
          name: user.name.isNotEmpty ? user.name : 'Usuário',
          email: user.email,
          role: user.role,
          accessToken: user.accessToken,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authController
      ..removeListener(_onControllerChanged)
      ..dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PetTrailAuthShell(
      cardBody: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Entrar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entre para pedir ou oferecer passeios.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: petTrailInputDecoration(
              cs,
              label: 'E-mail',
              hint: 'seu@email.com',
              icon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: petTrailInputDecoration(
              cs,
              label: 'Senha',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Esqueci minha senha'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _authController.isSubmitting ? null : _submitLogin,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _authController.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Entrar'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Não tem uma conta? ',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text('Cadastre-se'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
