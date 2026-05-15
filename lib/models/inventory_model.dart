class InventoryItem {
  final String id;
  final String name;
  final double totalPurchased;
  final double totalUsed;
  final double closingStock;
  final double threshold;

  InventoryItem({
    required this.id,
    required this.name,
    required this.totalPurchased,
    required this.totalUsed,
    required this.closingStock,
    required this.threshold,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['_id'] ?? '',
      // --- UPDATED: Checking all possible backend keys for the name ---
      name: json['materialName'] ?? json['itemName'] ?? json['title'] ?? json['name'] ?? json['brand'] ?? 'Unknown Material',
      totalPurchased: (json['totalPurchased'] ?? 0).toDouble(),
      totalUsed: (json['totalUsed'] ?? 0).toDouble(),
      closingStock: (json['closingStock'] ?? 0).toDouble(),
      threshold: (json['threshold'] ?? 0).toDouble(),
    );
  }
}