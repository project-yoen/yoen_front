import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final imageCacheManager = CacheManager(
  Config(
    'imgCacheV1', // ← 이 키 이름이 폴더명이 됩니다.
    stalePeriod: const Duration(days: 7), // 만료 기간
    maxNrOfCacheObjects: 500, // 개수 제한(보조)
  ),
);
