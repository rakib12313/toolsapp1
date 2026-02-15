import 'package:flutter/material.dart';
import '../core/services/history_service.dart';
import '../models/history_item.dart';

class HistoryProvider with ChangeNotifier {
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _items = [];
  bool _isLoading = false;
  
  List<HistoryItem> get items => _items;
  bool get isLoading => _isLoading;
  
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    
    _items = await _historyService.getHistory();
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> addEntry(HistoryItem item) async {
    await _historyService.saveHistory(item);
    await loadHistory();
  }
  
  Future<void> clearHistory() async {
    await _historyService.clearHistory();
    _items = [];
    notifyListeners();
  }
  
  Future<void> deleteEntry(String id) async {
    await _historyService.deleteHistory(id);
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
