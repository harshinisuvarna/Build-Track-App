class ChecklistItem {
  final String id;
  final String label;

  ChecklistItem({required this.id, required this.label});

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        id: j['id'] as String,
        label: j['label'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
      };
}
