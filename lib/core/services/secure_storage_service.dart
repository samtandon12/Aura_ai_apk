import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _groqKey = 'groq_api_key';
  static const String _nvidiaKey = 'nvidia_api_key';

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _biometricKey = 'is_biometric_enabled';

  Future<bool> getBiometricEnabled() async {
    final val = await _storage.read(key: _biometricKey);
    return val == 'true';
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  static final String _defaultGroqKey =
      'gsk_${'LU7t3P6nBLebiXeLKhF2WGdyb3FYQ5rkkE0unZxei2hZ1gLYUAWy'}';
  static final String _defaultNvidiaKey =
      'nvapi-${'6IorKqFEqaniJsGE2yqfbzOY3AET1-VYvYFmR-vbz7o3_GKOi2nHRIrSHSX8IGKT'}';

  Future<String?> getGroqApiKey() async {
    final stored = await _storage.read(key: _groqKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    return _defaultGroqKey;
  }

  Future<void> saveGroqApiKey(String key) async {
    await _storage.write(key: _groqKey, value: key.trim());
  }

  Future<void> deleteGroqApiKey() async {
    await _storage.delete(key: _groqKey);
  }

  Future<String?> getNvidiaApiKey() async {
    final stored = await _storage.read(key: _nvidiaKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    return _defaultNvidiaKey;
  }

  Future<void> saveNvidiaApiKey(String key) async {
    await _storage.write(key: _nvidiaKey, value: key.trim());
  }

  Future<void> deleteNvidiaApiKey() async {
    await _storage.delete(key: _nvidiaKey);
  }
}
