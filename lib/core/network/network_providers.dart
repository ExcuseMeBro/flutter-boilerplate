import 'package:flutter_boilerplate/core/network/api_client.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    localStorage: ref.watch(localStorageProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
