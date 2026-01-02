import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const String _cachePrefix = 'cached_data_';
  static const String _timestampPrefix = 'cached_timestamp_';

  static Future<void> saveData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final dataKey = '$_cachePrefix$key';
    final timestampKey = '$_timestampPrefix$key';
    
    await prefs.setString(dataKey, jsonEncode(data));
    await prefs.setString(timestampKey, DateTime.now().toIso8601String());
  }

  static Future<T?> getData<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final dataKey = '$_cachePrefix$key';
    final timestampKey = '$_timestampPrefix$key';
    
    final data = prefs.getString(dataKey);
    final timestamp = prefs.getString(timestampKey);
    
    if (data == null || timestamp == null) return null;
    
    final cacheTime = DateTime.parse(timestamp);
    if (DateTime.now().difference(cacheTime) > _cacheDuration) {
      await clearCache(key);
      return null;
    }
    
    try {
      if (T == List<Map<String, dynamic>>) {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<Map<String, dynamic>>() as T;
      }
      return jsonDecode(data) as T;
    } catch (e) {
      await clearCache(key);
      return null;
    }
  }

  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$key');
    await prefs.remove('$_timestampPrefix$key');
  }

  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  static Future<bool> isCacheValid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString('$_timestampPrefix$key');
    
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.parse(timestamp);
    return DateTime.now().difference(cacheTime) <= _cacheDuration;
  }

  static Future<void> forceRefresh(String key) async {
    await clearCache(key);
  }
}
