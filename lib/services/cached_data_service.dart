import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class CachedDataService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getSites({bool forceRefresh = false}) async {
    const cacheKey = 'sites';
    
    if (forceRefresh) {
      await CacheService.forceRefresh(cacheKey);
    }
    
    // Try to get from cache first
    final cachedData = await CacheService.getData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }
    
    // Fetch from database
    try {
      final data = await _supabase
          .from('sites')
          .select('id, name, location, created_at')
          .order('created_at');
      
      // Cache the data
      await CacheService.saveData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching sites: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getDocuments(String siteId, String type, {bool forceRefresh = false}) async {
    final cacheKey = 'documents_${siteId}_$type';
    
    if (forceRefresh) {
      await CacheService.forceRefresh(cacheKey);
    }
    
    // Try to get from cache first
    final cachedData = await CacheService.getData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }
    
    // Fetch from database
    try {
      final data = await _supabase
          .from('documents')
          .select('id, content, created_at, type')
          .eq('site_id', siteId)
          .eq('type', type)
          .order('created_at');
      
      // Cache the data
      await CacheService.saveData(cacheKey, data);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching documents: $e');
      return [];
    }
  }

  static Future<void> invalidateSitesCache() async {
    await CacheService.clearCache('sites');
  }

  static Future<void> invalidateDocumentsCache(String siteId, String type) async {
    await CacheService.clearCache('documents_${siteId}_$type');
  }

  static Future<void> invalidateAllCache() async {
    await CacheService.clearAllCache();
  }
}
