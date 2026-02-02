// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// خدمة التخزين على الويب باستخدام localStorage مباشرة
class WebStorageService {
  static String? getString(String key) {
    return html.window.localStorage[key];
  }

  static void setString(String key, String value) {
    html.window.localStorage[key] = value;
  }

  static void remove(String key) {
    html.window.localStorage.remove(key);
  }

  static Set<String> getKeys() {
    return html.window.localStorage.keys.toSet();
  }

  static void clear() {
    html.window.localStorage.clear();
  }
}
