import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/clip_item.dart';
import '../services/clipboard_service.dart';
import '../services/ocr_service.dart';
import '../services/startup_service.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

enum FilterType { all, text, images, urls }

class ClipProvider extends ChangeNotifier {
  List<ClipItem> _items = [];
  String _searchQuery = '';
  FilterType _filter = FilterType.all;
  bool _isLoading = true;
  int _maxHistory = 200;
  bool _launchAtStartup = false;
  int _tintThemeIndex = 0;

  List<ClipItem> get allItems => _items;

  List<ClipItem> get filteredItems {
    var list = _items.where((item) {
      if (_filter == FilterType.text && item.type != ClipType.text) return false;
      if (_filter == FilterType.images && item.type != ClipType.image) return false;
      if (_filter == FilterType.urls && item.type != ClipType.url) return false;
      return item.matches(_searchQuery);
    }).toList();
    return list;
  }

  List<ClipItem> get pinnedItems => _items.where((i) => i.isPinned).toList();

  List<ClipItem> get recentItems => _items.take(50).toList();

  Map<String, List<ClipItem>> get taggedItems {
    final map = <String, List<ClipItem>>{};
    for (final item in _items) {
      for (final tag in item.tags) {
        map.putIfAbsent(tag, () => []).add(item);
      }
    }
    return map;
  }

  List<String> get allTags {
    final tags = <String>{};
    for (final item in _items) {
      tags.addAll(item.tags);
    }
    return tags.toList()..sort();
  }

  String get searchQuery => _searchQuery;
  FilterType get filter => _filter;
  bool get isLoading => _isLoading;
  int get maxHistory => _maxHistory;
  bool get launchAtStartup => _launchAtStartup;
  int get tintThemeIndex => _tintThemeIndex;

  int get textCount => _items.where((i) => i.type == ClipType.text).length;
  int get imageCount => _items.where((i) => i.type == ClipType.image).length;
  int get urlCount => _items.where((i) => i.type == ClipType.url).length;

  Future<void> initialize() async {
    _items = await StorageService.loadClips();
    final prefs = await SharedPreferences.getInstance();
    _maxHistory = prefs.getInt('maxHistory') ?? 200;
    _tintThemeIndex = prefs.getInt('tintThemeIndex') ?? 0;
    _launchAtStartup = StartupService.isEnabled();
    _isLoading = false;

    ClipboardService.onClipboardChanged = _onClipboardData;
    ClipboardService.startMonitoring();

    notifyListeners();
  }

  void _onClipboardData(String type, String? text, Uint8List? imageBytes, int? width, int? height) async {
    ClipItem? newItem;

    if (type == 'text' && text != null) {
      // Deduplicate
      if (_items.isNotEmpty && _items.first.textContent == text) return;
      newItem = ClipItem.text(id: _uuid.v4(), content: text, timestamp: DateTime.now());
    } else if (type == 'url' && text != null) {
      if (_items.isNotEmpty && _items.first.textContent == text) return;
      newItem = ClipItem.url(id: _uuid.v4(), url: text, timestamp: DateTime.now());
    } else if (type == 'image' && imageBytes != null) {
      final path = await StorageService.saveImage(imageBytes);
      newItem = ClipItem.image(
        id: _uuid.v4(),
        imagePath: path,
        timestamp: DateTime.now(),
        width: width,
        height: height,
      );
    }

    if (newItem == null) return;

    _items.insert(0, newItem);
    _trimHistory();
    await _save();
    notifyListeners();

    if (newItem.isImage) {
      _runOcr(newItem);
    }
  }

  Future<void> _runOcr(ClipItem item) async {
    if (item.imagePath == null) return;
    final text = await OcrService.recognizeFromFile(item.imagePath!);
    if (text == null || text.isEmpty) return;

    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    _items[index] = item.copyWith(ocrText: text);
    await _save();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(FilterType filter) {
    _filter = filter;
    notifyListeners();
  }

  // Called when the window shows — reset to the default browseable state
  void resetView() {
    _searchQuery = '';
    _filter = FilterType.all;
    notifyListeners();
  }

  Future<void> setLaunchAtStartup(bool enabled) async {
    StartupService.setEnabled(enabled);
    _launchAtStartup = enabled;
    notifyListeners();
  }

  Future<void> setTintTheme(int index) async {
    _tintThemeIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tintThemeIndex', index);
    notifyListeners();
  }

  Future<void> togglePin(ClipItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;
    _items[index] = item.copyWith(isPinned: !item.isPinned);
    await _save();
    notifyListeners();
  }

  Future<void> addTag(ClipItem item, String tag) async {
    if (item.tags.contains(tag)) return;
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;
    final newTags = [...item.tags, tag];
    _items[index] = item.copyWith(tags: newTags);
    await _save();
    notifyListeners();
  }

  Future<void> removeTag(ClipItem item, String tag) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;
    final newTags = item.tags.where((t) => t != tag).toList();
    _items[index] = item.copyWith(tags: newTags);
    await _save();
    notifyListeners();
  }

  Future<void> deleteItem(ClipItem item) async {
    await StorageService.deleteImage(item.imagePath);
    _items.removeWhere((i) => i.id == item.id);
    await _save();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final unpinned = _items.where((i) => !i.isPinned).toList();
    await StorageService.clearAll(unpinned);
    _items.removeWhere((i) => !i.isPinned);
    await _save();
    notifyListeners();
  }

  Future<void> setMaxHistory(int max) async {
    _maxHistory = max;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxHistory', max);
    _trimHistory();
    await _save();
    notifyListeners();
  }

  void _trimHistory() {
    final unpinned = _items.where((i) => !i.isPinned).toList();
    if (unpinned.length > _maxHistory) {
      final toRemove = unpinned.sublist(_maxHistory);
      for (final item in toRemove) {
        StorageService.deleteImage(item.imagePath);
        _items.remove(item);
      }
    }
  }

  // Handler set by MainScreen so any child screen can trigger paste
  Future<void> Function(ClipItem)? _itemTapHandler;

  void setItemTapHandler(Future<void> Function(ClipItem) handler) {
    _itemTapHandler = handler;
  }

  Future<void> tapItem(ClipItem item) async {
    await _itemTapHandler?.call(item);
  }

  Future<void> _save() async {
    await StorageService.saveClips(_items);
  }

  @override
  void dispose() {
    ClipboardService.stopMonitoring();
    super.dispose();
  }
}
