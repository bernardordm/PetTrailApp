import 'package:flutter/material.dart';
import 'package:pet_trail/config/app_config.dart';
import 'package:pet_trail/data/services/pet_service.dart';

import 'create_pet_screen.dart';
import 'edit_pet_screen.dart';

class PetsScreen extends StatefulWidget {
  final String accessToken;
  final String tutorId;

  /// Sem [Scaffold] próprio (aba do [MainShellScreen]).
  final bool embeddedInShell;

  const PetsScreen({
    super.key,
    required this.accessToken,
    required this.tutorId,
    this.embeddedInShell = false,
  });

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  late PetService service;
  List pets = [];
  bool loading = true;
  String? _bannerMsg;
  bool _bannerError = false;

  int _listPhotoVersion = 0;

  @override
  void initState() {
    super.initState();
    service = PetService(widget.accessToken);
    loadPets();
  }

  Future<void> loadPets() async {
    setState(() => loading = true);

    try {
      final data = await service.getPets(widget.tutorId);

      setState(() {
        pets = data;
        loading = false;
        _listPhotoVersion = DateTime.now().millisecondsSinceEpoch;
      });
    } catch (e) {
      debugPrint("ERRO AO CARREGAR PETS: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _deletePet(String petId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir pet"),
        content: const Text("Tem certeza que deseja excluir este pet?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await service.deletePet(widget.tutorId, petId);

        if (!mounted) return;
        loadPets();
        _showBanner('Pet excluído com sucesso!', false);
      } catch (e) {
        if (!mounted) return;
        _showBanner('Erro ao excluir pet: $e', true);
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

  Future<void> _goToCreatePet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePetScreen(
          accessToken: widget.accessToken,
          tutorId: widget.tutorId,
        ),
      ),
    );

    if (result == true) {
      loadPets();
    }
  }

  Future<void> _goToEditPet(Map pet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPetScreen(
          accessToken: widget.accessToken,
          tutorId: widget.tutorId,
          pet: pet,
        ),
      ),
    );

    if (result == true) {
      loadPets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final stackBody = Stack(
        children: [
          loading
          ? const Center(child: CircularProgressIndicator())
          : pets.isEmpty
          ? _emptyState(cs)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Meus Pets",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Gerencie os pets cadastrados",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _petList(cs)),
              ],
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
    );

    if (widget.embeddedInShell) {
      return ColoredBox(
        color: cs.surface,
        child: Stack(
          children: [
            stackBody,
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: _goToCreatePet,
                icon: const Icon(Icons.add),
                label: const Text("Novo Pet"),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Meus Pets")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreatePet,
        icon: const Icon(Icons.add),
        label: const Text("Novo Pet"),
      ),
      body: stackBody,
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets_rounded, size: 56, color: cs.secondary),
              const SizedBox(height: 16),
              Text(
                "Você ainda não cadastrou nenhum pet",
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _goToCreatePet,
                icon: const Icon(Icons.add),
                label: const Text("Cadastrar primeiro pet"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _petList(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        final petId = pet['identifier'];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: cs.primaryContainer,
              backgroundImage: NetworkImage(
                '${AppConfig.apiBaseUrl}/tutors/${widget.tutorId}/pets/$petId/photo?v=$_listPhotoVersion',
                headers: {'Authorization': 'Bearer ${widget.accessToken}'},
              ),
              onBackgroundImageError: (_, __) {},
              child: const SizedBox.shrink(),
            ),
            title: Text(
              pet['name'] ?? 'Sem nome',
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text("${pet['species'] ?? ''}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Editar pet",
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _goToEditPet(pet),
                ),
                IconButton(
                  tooltip: "Excluir pet",
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePet(petId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
