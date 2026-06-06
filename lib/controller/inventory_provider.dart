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

  // Filtered getters for each tab in InventoryScreen
  List<InventoryItem> get materialInventory =>
      _inventory.where((item) => item.category == 'material').toList();

  List<InventoryItem> get labourInventory =>
      _inventory.where((item) => item.category == 'labour').toList();

  List<InventoryItem> get equipmentInventory =>
      _inventory.where((item) => item.category == 'equipment').toList();

  // Call this after saving a new entry to push it to the backend & refresh
  Future<void> addToInventory({
    required String materialName,
    required double quantity,
    required String unit,
    required String projectId,
    required String category, // 'material' | 'labour' | 'equipment'
    double threshold = 10,
  }) async {
    try {
      await ApiService.addInventoryItem(
        materialName: materialName,
        purchased: quantity,
        unit: unit,
        projectId: projectId,
        category: category,
        threshold: threshold,
      );
      // Refresh the list so the UI updates
      await loadInventory(projectId);
    } catch (e) {
      _error = 'Could not add to inventory: $e';
      notifyListeners();
    }
  }
  

  Future<void> loadInventory(String projectId) async {
    _isLoading = true;
    _error = '';
    notifyListeners(); 

    try {
      final rawData = await ApiService.fetchInventory(projectId);
      debugPrint('RAW INVENTORY JSON');
      debugPrint(rawData.toString());
      _inventory = rawData.map((json) => InventoryItem.fromJson(json)).toList();
    } catch (e) {
      _error = 'Could not fetch inventory: $e';
    } finally {
      _isLoading = false;
      notifyListeners(); // Tells the UI to rebuild!
    }
  }

  // New method for Server-Side Search
  Future<void> performSearch(String query, String category, {String projectId = ''}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Hits the new backend-connected search method
      final rawData = await ApiService.searchMaterials(
        query: query,
        category: category,
        projectId: projectId,
      );
      debugPrint('RAW INVENTORY JSON');
      debugPrint(rawData.toString());
      _inventory = rawData.map((json) => InventoryItem.fromJson(json)).toList();
    } catch (e) {
      _error = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}