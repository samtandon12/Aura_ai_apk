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

  Future<String?> getGroqApiKey() async {
    return await _storage.read(key: _groqKey);
  }

  Future<void> saveGroqApiKey(String key) async {
    await _storage.write(key: _groqKey, value: key.trim());
  }

  Future<void> deleteGroqApiKey() async {
    await _storage.delete(key: _groqKey);
  }

  Future<String?> getNvidiaApiKey() async {
    return await _storage.read(key: _nvidiaKey);
  }

  Future<void> saveNvidiaApiKey(String key) async {
    await _storage.write(key: _nvidiaKey, value: key.trim());
  }

  Future<void> deleteNvidiaApiKey() async {
    await _storage.delete(key: _nvidiaKey);
  }
}
