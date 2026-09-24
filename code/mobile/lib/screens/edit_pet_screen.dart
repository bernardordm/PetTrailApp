import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/data/services/pet_service.dart';

class EditPetScreen extends StatefulWidget {
  final String accessToken;
  final String tutorId;
  final Map pet;

  const EditPetScreen({
    super.key,
    required this.accessToken,
    required this.tutorId,
    required this.pet,
  });

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nomeController;
  late TextEditingController idadeController;
  late TextEditingController obsController;

  String? especieSelecionada;
  String? porteSelecionado;

  bool loading = false;
  late int _photoVersion;
  bool _photoChanged = false;
  String? _bannerMsg;
  bool _bannerError = false;

  late PetService service;

  final especies = [
    'Cachorro',
    'Gato',
    'Coelho',
    'Bode',
    'Alpaca',
    'Cavalo',
    'Outro',
  ];

  final portes = ['Pequeno', 'Médio', 'Grande'];

  @override
  void initState() {
    super.initState();

    service = PetService(widget.accessToken);
    _photoVersion = DateTime.now().millisecondsSinceEpoch;

    final pet = widget.pet;

    nomeController = TextEditingController(text: pet['name'] ?? '');
    idadeController = TextEditingController(text: pet['age']?.toString() ?? '');
    obsController = TextEditingController(text: pet['observations'] ?? '');

    especieSelecionada = _capitalizeFirst(pet['species']?.toString());
    porteSelecionado = _capitalizeFirst(pet['size']?.toString());
  }

  @override
  void dispose() {
    nomeController.dispose();
    idadeController.dispose();
    obsController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await service.updatePet(widget.tutorId, widget.pet['identifier'], {
        "name": nomeController.text,
        "species": especieSelecionada,
        "size": porteSelecionado,
        "age": idadeController.text,
        "observations": obsController.text,
      });

      if (!mounted) return;

      _showBanner('Pet atualizado com sucesso!', false);
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showBanner('Erro ao atualizar pet: $e', true);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _trocarFoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final bytes = await image.readAsBytes();

    try {
      await service.uploadPhoto(
        widget.tutorId,
        widget.pet['identifier'],
        bytes,
        fileName: image.name,
      );

      if (!mounted) return;

      setState(() {
        _photoVersion = DateTime.now().millisecondsSinceEpoch;
        _photoChanged = true;
      });

      _showBanner('Foto atualizada com sucesso!', false);
    } catch (e) {
      if (!mounted) return;

      _showBanner('Erro ao atualizar foto: $e', true);
    }
  }

  String? _capitalizeFirst(String? s) {
    if (s == null || s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
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
    final petId = widget.pet['identifier'];

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Pet")),
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
                          backgroundImage: NetworkImage(
                            '${AppConfig.apiBaseUrl}/tutors/${widget.tutorId}/pets/$petId/photo?v=$_photoVersion',
                            headers: {
                              'Authorization': 'Bearer ${widget.accessToken}',
                            },
                          ),
                          onBackgroundImageError: (_, __) {},
                          child: const SizedBox.shrink(),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: _trocarFoto,
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
                      "Toque na câmera para trocar a foto",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (_photoChanged)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Nova foto pronta. Toque em salvar para voltar à lista atualizada.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: cs.secondary,
                                fontWeight: FontWeight.w600,
                              ),
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
                "Atualize os dados do seu pet abaixo.",
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
              const SizedBox(height: 14),
              campo(
                "Observações",
                obsController,
                obrigatorio: false,
                maxLines: 2,
                tipo: TextInputType.text,
              ),
              const SizedBox(height: 28),
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
                      : const Text("Salvar alterações"),
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
