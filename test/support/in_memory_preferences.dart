import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Installs an in-memory [SharedPreferencesAsync] platform and returns a fresh
/// client. Tests never touch a real preferences channel.
SharedPreferencesAsync installInMemoryPreferences([
  Map<String, Object> data = const <String, Object>{},
]) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(data);
  return SharedPreferencesAsync();
}
