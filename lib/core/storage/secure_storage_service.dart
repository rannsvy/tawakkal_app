import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
    ),
  );
});

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _guestKey = 'guest_mode_enabled';

  Future<void> setGuestMode(bool value) async {
    try {
      if (value) {
        await _storage.write(key: _guestKey, value: '1');
        return;
      }
      await _storage.delete(key: _guestKey);
    } on PlatformException {
      await _recoverFromStorageError();
    }
  }

  Future<bool> isGuestModeEnabled() async {
    try {
      final value = await _storage.read(key: _guestKey);
      return value == '1';
    } on PlatformException {
      await _recoverFromStorageError();
      return false;
    }
  }

  Future<void> _recoverFromStorageError() async {
    try {
      await _storage.deleteAll();
    } on PlatformException {
      // Ignore secondary failures; app continues in non-guest default mode.
    }
  }
}
