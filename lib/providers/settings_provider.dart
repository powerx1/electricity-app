import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// مزود بيانات الإعدادات - Settings Provider
class SettingsProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  AppSettings _settings = AppSettings();
  bool _isLoading = false;
  String? _error;

  // Getters
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // اختصارات للإعدادات الشائعة
  double get defaultKwhPrice => _settings.defaultKwhPrice;
  String get stampText => _settings.stampText;
  bool get showHijriDate => _settings.showHijriDate;
  String get companyName => _settings.companyName;
  String get nextInvoiceNumber => _settings.nextInvoiceNumber;

  /// تحميل الإعدادات
  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _dbService.getSettings();
    } catch (e) {
      _error = 'فشل في تحميل الإعدادات: $e';
      _settings = AppSettings(); // استخدام الإعدادات الافتراضية
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحديث سعر الكيلوواط الافتراضي
  Future<bool> updateDefaultKwhPrice(double price) async {
    try {
      _settings = _settings.copyWith(defaultKwhPrice: price);
      await _dbService.updateSettings(_settings);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في تحديث سعر الكيلوواط: $e';
      notifyListeners();
      return false;
    }
  }

  /// تحديث نص الختم
  Future<bool> updateStampText(String text) async {
    try {
      _settings = _settings.copyWith(stampText: text);
      await _dbService.updateSettings(_settings);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في تحديث نص الختم: $e';
      notifyListeners();
      return false;
    }
  }

  /// تحديث إظهار التاريخ الهجري
  Future<bool> updateShowHijriDate(bool show) async {
    try {
      _settings = _settings.copyWith(showHijriDate: show);
      await _dbService.updateSettings(_settings);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في تحديث إعدادات التاريخ: $e';
      notifyListeners();
      return false;
    }
  }

  /// تحديث اسم الشركة
  Future<bool> updateCompanyName(String name) async {
    try {
      _settings = _settings.copyWith(companyName: name);
      await _dbService.updateSettings(_settings);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في تحديث اسم الشركة: $e';
      notifyListeners();
      return false;
    }
  }

  /// تحديث معلومات الشركة
  Future<bool> updateCompanyInfo({
    String? companyName,
    String? companyPhone,
    String? companyAddress,
  }) async {
    try {
      _settings = _settings.copyWith(
        companyName: companyName ?? _settings.companyName,
        companyPhone: companyPhone,
        companyAddress: companyAddress,
      );
      await _dbService.updateSettings(_settings);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في تحديث معلومات الشركة: $e';
      notifyListeners();
      return false;
    }
  }

  /// تحديث جميع الإعدادات
  Future<bool> updateSettings(AppSettings newSettings) async {
    try {
      _settings = newSettings.copyWith(id: _settings.id);
      await _dbService.updateSettings(_settings);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في تحديث الإعدادات: $e';
      notifyListeners();
      return false;
    }
  }

  /// إعادة الإعدادات للقيم الافتراضية
  Future<bool> resetToDefaults() async {
    try {
      _settings = AppSettings(id: _settings.id);
      await _dbService.updateSettings(_settings);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في إعادة الإعدادات: $e';
      notifyListeners();
      return false;
    }
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
