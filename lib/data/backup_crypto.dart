import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

const backupFormat = 'whatseat-backup';
const encryptedBackupFormat = 'whatseat-backup-encrypted';

class WrongBackupPasswordException implements Exception {}

// OWASP's Argon2id baseline: 19 MiB, 2 passes, 1 lane.
const _memory = 19 * 1024;
const _iterations = 2;
const _parallelism = 1;

bool isEncryptedBackup(Map<String, dynamic> json) => json['format'] == encryptedBackupFormat;

/// Key derivation takes a second or two, so it runs off the UI isolate.
Future<Map<String, dynamic>> encryptBackup(Map<String, dynamic> backup, String password) => Isolate.run(() async {
      final random = Random.secure();
      final salt = List.generate(16, (_) => random.nextInt(256));
      final key = await _deriveKey(password, salt, memory: _memory, iterations: _iterations, parallelism: _parallelism);
      final box = await AesGcm.with256bits().encrypt(utf8.encode(jsonEncode(backup)), secretKey: key);
      return {
        'format': encryptedBackupFormat,
        'kdf': {
          'algorithm': 'argon2id',
          'memory': _memory,
          'iterations': _iterations,
          'parallelism': _parallelism,
          'salt': base64Encode(salt),
        },
        'cipher': 'aes-256-gcm',
        'nonce': base64Encode(box.nonce),
        'ciphertext': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      };
    });

Future<Map<String, dynamic>> decryptBackup(Map<String, dynamic> json, String password) {
  final kdf = json['kdf'] as Map<String, dynamic>;
  final memory = kdf['memory'] as int;
  final iterations = kdf['iterations'] as int;
  final parallelism = kdf['parallelism'] as int;
  // The parameters come from the file; unbounded ones would let a crafted file exhaust memory or time.
  if (kdf['algorithm'] != 'argon2id' ||
      json['cipher'] != 'aes-256-gcm' ||
      memory < 8 * parallelism ||
      memory > 256 * 1024 ||
      iterations < 1 ||
      iterations > 16 ||
      parallelism < 1 ||
      parallelism > 8) {
    throw const FormatException('Unsupported backup encryption');
  }
  final salt = base64Decode(kdf['salt'] as String);
  final box = SecretBox(
    base64Decode(json['ciphertext'] as String),
    nonce: base64Decode(json['nonce'] as String),
    mac: Mac(base64Decode(json['mac'] as String)),
  );
  return Isolate.run(() async {
    final key = await _deriveKey(password, salt, memory: memory, iterations: iterations, parallelism: parallelism);
    final List<int> clear;
    try {
      clear = await AesGcm.with256bits().decrypt(box, secretKey: key);
    } on SecretBoxAuthenticationError {
      throw WrongBackupPasswordException();
    }
    return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
  });
}

Future<SecretKey> _deriveKey(String password, List<int> salt,
        {required int memory, required int iterations, required int parallelism}) =>
    Argon2id(memory: memory, iterations: iterations, parallelism: parallelism, hashLength: 32)
        .deriveKeyFromPassword(password: password, nonce: salt);
