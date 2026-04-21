import 'package:buildtrack_mobile/screen/add_entry.dart';
import 'package:buildtrack_mobile/screen/homescreen.dart';
import 'package:buildtrack_mobile/screen/inventory.dart';
import 'package:buildtrack_mobile/screen/projectscreen.dart';
import 'package:buildtrack_mobile/screen/report.dart';
import 'package:flutter/material.dart';

class NavController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;
  void setIndex(int newIndex, BuildContext context) {
    if (_index == newIndex) return;
    _index = newIndex;
    notifyListeners();
    switch (newIndex) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProjectsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEntryScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
        break;
    }
  }
}
