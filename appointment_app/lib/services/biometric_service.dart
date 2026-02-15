import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyBioIdentifier = 'bio_identifier';
  static const _keyBioPassword = 'bio_password';

  /// Check if device supports biometric
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Check if user has enabled biometric login
  static Future<bool> isEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  /// Check if saved credentials exist
  static Future<bool> hasSavedCredentials() async {
    final id = await _storage.read(key: _keyBioIdentifier);
    final pw = await _storage.read(key: _keyBioPassword);
    return id != null && pw != null && id.isNotEmpty && pw.isNotEmpty;
  }

  /// Save credentials after successful login
  static Future<void> saveCredentials(String identifier, String password) async {
    await _storage.write(key: _keyBioIdentifier, value: identifier);
    await _storage.write(key: _keyBioPassword, value: password);
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
  }

  /// Get saved credentials
  static Future<Map<String, String>?> getSavedCredentials() async {
    final id = await _storage.read(key: _keyBioIdentifier);
    final pw = await _storage.read(key: _keyBioPassword);
    if (id == null || pw == null) return null;
    return {'identifier': id, 'password': pw};
  }

  /// Authenticate with biometric
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Sign in to BookNex',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Clear saved credentials (on logout)
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keyBioIdentifier);
    await _storage.delete(key: _keyBioPassword);
    await _storage.delete(key: _keyBiometricEnabled);
  }
}
