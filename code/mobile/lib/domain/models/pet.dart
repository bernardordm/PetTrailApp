class Pet {
  const Pet({
    required this.identifier,
    required this.name,
    required this.species,
    required this.size,
    this.age,
  });

  final String identifier;
  final String name;
  final String species;
  final String size;
  final String? age;

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        identifier: json['identifier'] as String,
        name: json['name'] as String,
        species: json['species'] as String,
        size: json['size'] as String,
        age: json['age'] as String?,
      );
}
