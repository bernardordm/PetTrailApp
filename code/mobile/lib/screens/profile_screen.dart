import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/data/repositories/profile_repository_impl.dart';
import 'package:pet_trail/data/services/profile_api_service.dart';
import 'package:pet_trail/domain/models/profile_data.dart';
import 'package:pet_trail/presentation/controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.identifier,
    required this.name,
    required this.email,
    required this.role,
    required this.accessToken,
    this.embeddedInShell = false,
  });

  final String identifier;
  final String name;
  final String email;
  final String role; // tutor | walker
  final String accessToken;

  /// Sem [Scaffold] próprio (aba do [MainShellScreen]).
  final bool embeddedInShell;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _profileController;
  String _address = '';
  String _phone = '';
  String _document = '';
  String _walkPrice = '';
  String _averageRideTime = '';
  double? _averageRating;
  bool _available = true;
  String? _photoUrl;

  String get roleLabel => widget.role == 'walker' ? 'Passeador' : 'Tutor';

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController(
      ProfileRepositoryImpl(ProfileApiService()),
    )..addListener(_onControllerChanged);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _profileController.load(
      role: widget.role,
      identifier: widget.identifier,
      accessToken: widget.accessToken,
    );
    if (!mounted || data == null) return;
    _fillForm(data);
  }

  void _fillForm(ProfileData data) {
    _address = data.address ?? '';
    _phone = data.phone ?? '';
    _document = data.document ?? '';
    _walkPrice = data.walkPrice?.toString() ?? '';
    _averageRideTime = data.averageRideTime?.toString() ?? '';
    _averageRating = data.averageRating;
    _available = data.available ?? true;
    if (data.photoUrl != null) _photoUrl = data.photoUrl;
    setState(() {});
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    Navigator.of(context).pop();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    final rawMimeType = picked.mimeType?.trim().toLowerCase();
    final mimeType = (rawMimeType != null && rawMimeType.startsWith('image/'))
        ? rawMimeType
        : 'image/jpeg';

    final newUrl = await _profileController.uploadPhoto(
      role: widget.role,
      identifier: widget.identifier,
      accessToken: widget.accessToken,
      bytes: bytes,
      mimeType: mimeType,
    );
    if (!mounted) return;
    if (newUrl != null) {
      setState(() => _photoUrl = newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto atualizada com sucesso.')),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmera'),
              onTap: () => _pickAndUploadPhoto(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => _pickAndUploadPhoto(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final error = _profileController.consumeError();
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    setState(() {});
  }

  double? _toDouble(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v.replaceAll(',', '.'));
  }

  Future<bool> _savePartial(ProfileData data) async {
    final ok = await _profileController.save(
      role: widget.role,
      identifier: widget.identifier,
      accessToken: widget.accessToken,
      data: data,
    );
    if (!mounted || !ok) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso.')),
    );
    return true;
  }

  Future<void> _editTextField({
    required String title,
    required String initialValue,
    required Future<void> Function(String value) onSave,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final maskFormatter = inputFormatters
        ?.whereType<MaskTextInputFormatter>()
        .cast<MaskTextInputFormatter?>()
        .fold<MaskTextInputFormatter?>(null, (prev, item) => prev ?? item);
    if (maskFormatter != null) {
      controller.text = maskFormatter.maskText(initialValue);
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    if (newValue == null) return;
    await onSave(newValue);
  }

  Widget _editableTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    final display = value.isEmpty ? 'Não informado' : value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(display),
      trailing: IconButton(
        tooltip: 'Editar $label',
        onPressed: _profileController.isSaving ? null : onEdit,
        icon: const Icon(Icons.edit_outlined),
      ),
    );
  }

  @override
  void dispose() {
    _profileController
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final body = SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _profileController.isUploadingPhoto ? null : _showPhotoOptions,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: cs.primaryContainer,
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(
                              '${AppConfig.apiBaseUrl}$_photoUrl',
                              headers: {'Authorization': 'Bearer ${widget.accessToken}'},
                            )
                          : null,
                      child: _photoUrl == null
                          ? Icon(Icons.person, size: 44, color: cs.onPrimaryContainer)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primary,
                      child: _profileController.isUploadingPhoto
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : Icon(Icons.camera_alt, size: 16, color: cs.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (widget.role == 'walker' && _averageRating != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.star_rounded, size: 18, color: cs.tertiary),
                  const SizedBox(width: 2),
                  Text(
                    _averageRating!.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.tertiary,
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Chip(
                label: Text(roleLabel),
                avatar: Icon(
                  widget.role == 'walker' ? Icons.directions_walk : Icons.home_rounded,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_profileController.isLoading || _profileController.isSaving)
              const LinearProgressIndicator(),
            const SizedBox(height: 12),
            _editableTile(
              icon: Icons.phone_outlined,
              label: 'Telefone',
              value: _phone,
              onEdit: () => _editTextField(
                title: 'Telefone',
                initialValue: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  MaskTextInputFormatter(
                    mask: '(##) #####-####',
                    filter: {'#': RegExp(r'[0-9]')},
                  ),
                ],
                onSave: (value) async {
                  final saved = await _savePartial(ProfileData(phone: value));
                  if (!saved) return;
                  _phone = value;
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            if (widget.role == 'tutor') ...[
              _editableTile(
                icon: Icons.home_outlined,
                label: 'Endereço',
                value: _address,
                onEdit: () => _editTextField(
                  title: 'Endereço',
                  initialValue: _address,
                  onSave: (value) async {
                    final saved = await _savePartial(ProfileData(address: value));
                    if (!saved) return;
                    _address = value;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.role == 'walker') ...[
              _editableTile(
                icon: Icons.badge_outlined,
                label: 'Documento',
                value: _document,
                onEdit: () => _editTextField(
                  title: 'CPF',
                  initialValue: _document,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    MaskTextInputFormatter(
                      mask: '###.###.###-##',
                      filter: {'#': RegExp(r'[0-9]')},
                    ),
                  ],
                  onSave: (value) async {
                    final saved = await _savePartial(ProfileData(document: value));
                    if (!saved) return;
                    _document = value;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 12),
              _editableTile(
                icon: Icons.attach_money,
                label: 'Valor por passeio',
                value: _walkPrice.isEmpty ? '' : 'R\$ $_walkPrice',
                onEdit: () => _editTextField(
                  title: 'Valor por passeio',
                  initialValue: _walkPrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSave: (value) async {
                    final parsed = _toDouble(value);
                    if (parsed == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Informe um valor numérico válido.')),
                      );
                      return;
                    }
                    final saved = await _savePartial(ProfileData(walkPrice: parsed));
                    if (!saved) return;
                    _walkPrice = value;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 12),
              _editableTile(
                icon: Icons.timer_outlined,
                label: 'Tempo médio de passeio (min)',
                value: _averageRideTime,
                onEdit: () => _editTextField(
                  title: 'Tempo médio de passeio (min)',
                  initialValue: _averageRideTime,
                  keyboardType: TextInputType.number,
                  onSave: (value) async {
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Informe um valor inteiro válido.')),
                      );
                      return;
                    }
                    final saved = await _savePartial(ProfileData(averageRideTime: parsed));
                    if (!saved) return;
                    _averageRideTime = value;
                    setState(() {});
                  },
                ),
              ),
            ],
          ],
        ),
    );

    if (widget.embeddedInShell) {
      return ColoredBox(color: cs.surface, child: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: body,
    );
  }
}
