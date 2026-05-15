import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/inventory_model.dart';

class InventoryProvider extends ChangeNotifier {
  List<InventoryItem> _inventory = [];
  bool _isLoading = false;
  String _error = '';

  List<InventoryItem> get inventory => _inventory;
  bool get isLoading => _isLoading;
  String get error => _error;

  // TASK 2 LOGIC: Dynamically filters items below their threshold!
  List<InventoryItem> get lowStockAlerts {
    return _inventory.where((item) => item.closingStock < item.threshold).toList();
  }
  

  Future<void> loadInventory(String projectId) async {
    _isLoading = true;
    _error = '';
    notifyListeners(); 

    try {
      final rawData = await ApiService.fetchInventory(projectId);
      _inventory = rawData.map((json) => InventoryItem.fromJson(json)).toList();
    } catch (e) {
      _error = 'Could not fetch inventory: $e';
    } finally {
      _isLoading = false;
      notifyListeners(); // Tells the UI to rebuild!
    }
  }
}