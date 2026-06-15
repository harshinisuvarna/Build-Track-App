double? parseAmount(String input) {
  final cleaned = input
      .replaceAll('₹', '')
      .replaceAll(',', '')
      .trim();
  return double.tryParse(cleaned);
}

String formatCurrency(num amount) {
  if (amount == 0) return '₹0.00';
  if (amount >= 10000000) {
    return '₹${(amount / 10000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}Cr';
  }
  if (amount >= 100000) {
    return '₹${(amount / 100000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}L';
  }
  if (amount >= 1000) {
    return '₹${(amount / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
  }
  if (amount == amount.toInt()) {
    return '₹${amount.toInt()}';
  } else {
    return '₹${amount.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}';
  }
}
