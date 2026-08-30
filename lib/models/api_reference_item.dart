class ApiReferenceItem {
  const ApiReferenceItem({required this.id, required this.name});

  final int id;
  final String name;

  factory ApiReferenceItem.fromJson(Map<String, dynamic> json) {
    return ApiReferenceItem(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}
