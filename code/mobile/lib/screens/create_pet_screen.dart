import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_trail/data/services/pet_service.dart';

class CreatePetScreen extends StatefulWidget {
  final String accessToken;
  final String tutorId;

  const CreatePetScreen({
    super.key,
    required this.accessToken,
    required this.tutorId,
  });

  @override
  State<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends State<CreatePetScreen> {
  final _formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final idadeController = TextEditingController();
  final obsController = TextEditingController();

  String? especieSelecionada;
  String? porteSelecionado;

  bool loading = false;
  String? _bannerMsg;
  bool _bannerError = false;

  late PetService service;

  Uint8List? _fotoBytes;
  String? _fotoNome;

  final especies = [
    'cachorro',
    'gato',
    'coelho',
    'bode',
    'alpaca',
    'cavalo',
    'outro',
  ];

  final portes = ['pequeno', 'médio', 'grande'];

  @override
  void initState() {
    super.initState();
    service = PetService(widget.accessToken);
  }

  @override
  void dispose() {
    nomeController.dispose();
    idadeController.dispose();
    obsController.dispose();
    super.dispose();
  }

  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      _fotoBytes = bytes;
      _fotoNome = image.name;
    });
  }

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      // 1) cria o pet
      final createdPet = await service.createPet(widget.tutorId, {
        "name": nomeController.text,
        "species": especieSelecionada,
        "size": porteSelecionado,
        "age": idadeController.text,
        "observations": obsController.text,
      });

      // 2) tenta descobrir o identifier do pet criado
      final petId =
          createdPet['identifier']?.toString() ?? createdPet['id']?.toString();

      // 3) se tiver foto selecionada e tiver petId, faz upload
      if (_fotoBytes != null && petId != null && petId.isNotEmpty) {
        await service.uploadPhoto(
          widget.tutorId,
          petId,
          _fotoBytes!,
          fileName: _fotoNome ?? 'pet.jpg',
        );
      }

      if (!mounted) return;

      _showBanner('Pet cadastrado com sucesso!', false);
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showBanner('Erro ao cadastrar pet: $e', true);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showBanner(String msg, bool isError) {
    setState(() {
      _bannerMsg = msg;
      _bannerError = isError;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _bannerMsg = null);
    });
  }

  Widget campo(
    String label,
    TextEditingController controller, {
    TextInputType? tipo,
    bool obrigatorio = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipo,
      maxLines: maxLines,
      textCapitalization: tipo == TextInputType.text
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      decoration: InputDecoration(labelText: label),
      validator: obrigatorio
          ? (v) => v == null || v.isEmpty ? 'Obrigatório' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Cadastrar Pet")),
      body: Stack(
        children: [
          SafeArea(
            child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: cs.primaryContainer,
                          backgroundImage: _fotoBytes != null
                              ? MemoryImage(_fotoBytes!)
                              : null,
                          child: _fotoBytes == null
                              ? Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: cs.onPrimaryContainer,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: _selecionarFoto,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: cs.onSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Adicione uma foto do pet (opcional)",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "Informações do pet",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                "Preencha os dados abaixo para cadastrar seu pet.",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              campo("Nome", nomeController),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: especieSelecionada,
                decoration: const InputDecoration(labelText: "Espécie"),
                items: especies
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() => especieSelecionada = value);
                },
                validator: (v) => v == null ? 'Selecione uma espécie' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: porteSelecionado,
                decoration: const InputDecoration(labelText: "Porte"),
                items: portes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() => porteSelecionado = value);
                },
                validator: (v) => v == null ? 'Selecione um porte' : null,
              ),
              const SizedBox(height: 14),
              campo("Idade", idadeController, tipo: TextInputType.number),
              const SizedBox(height: 12),
              campo(
                "Observações",
                obsController,
                obrigatorio: false,
                maxLines: 2,
                tipo: TextInputType.text,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: loading ? null : salvar,
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Cadastrar Pet"),
                ),
              ),
            ],
          ),
        ),
          ),
          AnimatedSlide(
            offset: _bannerMsg != null ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _bannerMsg != null ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    color: _bannerError ? cs.errorContainer : const Color(0xFF2E7D32),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            _bannerError ? Icons.error_outline : Icons.check_circle_outline,
                            color: _bannerError ? cs.onErrorContainer : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _bannerMsg ?? '',
                              style: TextStyle(
                                color: _bannerError ? cs.onErrorContainer : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
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
