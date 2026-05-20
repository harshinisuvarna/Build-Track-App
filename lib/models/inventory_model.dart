class InventoryItem {
  final String id;
  final String name;
  final double totalPurchased;
  final double totalUsed;
  final double closingStock;
  final double threshold;
  final String unit;
  final String category; // 'material' | 'labour' | 'equipment'

  InventoryItem({
    required this.id,
    required this.name,
    required this.totalPurchased,
    required this.totalUsed,
    required this.closingStock,
    required this.threshold,
    this.unit = 'units',
    this.category = 'material',
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final String rawCat = (json['category'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final String rawType = (json['type'] ?? '').toString().trim().toLowerCase();

    String category = 'material';
    if (rawCat == 'labour' ||
        rawCat == 'wages' ||
        rawCat == 'labor' ||
        rawCat.contains('labour') ||
        rawType == 'wages' ||
        rawType == 'labour') {
      category = 'labour';
    } else if (rawCat == 'equipment' ||
        rawCat == 'machinery' ||
        rawCat == 'expense' ||
        rawType == 'expense' ||
        rawType == 'equipment') {
      category = 'equipment';
    }

    return InventoryItem(
      id: json['_id'] ?? '',
      // --- UPDATED: Checking all possible backend keys for the name ---
      name:
          json['materialName'] ??
          json['itemName'] ??
          json['title'] ??
          json['name'] ??
          json['brand'] ??
          'Unknown',
      totalPurchased:
          (json['purchased'] ?? json['totalPurchased'] ?? json['quantity'] ?? 0)
              .toDouble(),
      totalUsed: (json['used'] ?? json['totalUsed'] ?? 0).toDouble(),
      closingStock:
          (json['closingStock'] ?? json['quantity'] ?? json['purchased'] ?? 0)
              .toDouble(),
      threshold: (json['threshold'] ?? 10.0).toDouble(),
      unit: json['unit'] ?? 'units',
      category: category,
    );
  }
}
