import 'package:flutter/material.dart';
import 'package:pet_trail/data/repositories/auth_repository_impl.dart';
import 'package:pet_trail/data/services/auth_api_service.dart';
import 'package:pet_trail/presentation/controllers/auth_controller.dart';
import 'package:pet_trail/screens/login_screen.dart';
import 'package:pet_trail/widgets/pet_trail_auth_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialRole = 'tutor'});

  final String initialRole;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final AuthController _authController;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late String _userType;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _userType = widget.initialRole == 'walker' ? 'walker' : 'tutor';
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

  Future<void> _submitRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await _authController.register(
      name: name,
      email: email,
      password: password,
      role: _userType, // tutor | walker
    );
    if (!mounted || !success) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada. Agora faça login.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _authController
      ..removeListener(_onControllerChanged)
      ..dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PetTrailAuthShell(
      heroFlex: 36,
      cardFlex: 54,
      cardBody: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Criar conta',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione seu perfil: dono ou passeador.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<String>(value: 'tutor', label: Text('Tutor')),
              ButtonSegment<String>(value: 'walker', label: Text('Passeador')),
            ],
            selected: {_userType},
            onSelectionChanged: _authController.isSubmitting
                ? null
                : (selection) {
                    setState(() => _userType = selection.first);
                  },
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: petTrailInputDecoration(
              cs,
              label: 'Nome completo',
              hint: 'Qual o seu nome?',
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),
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
            textInputAction: TextInputAction.next,
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
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _authController.isSubmitting ? null : _submitRegister,
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
                : const Text('Criar conta'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Já possui uma conta? ',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Entrar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
