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

/// When the backup was made, from inside it, so encryption vouches for it.
DateTime backupCreated(Map<String, dynamic> backup) {
  final created = backup['created'];
  final parsed = created is String ? DateTime.tryParse(created) : null;
  if (parsed == null) throw const FormatException('Backup without creation time');
  return parsed;
}

/// Unambiguous when read aloud or handwritten: no 0/O, 1/I/L.
const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const _codeLength = 24;

/// 24 symbols from 31 give ~119 bits, so the code holds up against offline guessing by whoever stores the file.
String generateRecoveryCode() {
  final random = Random.secure();
  return List.generate(_codeLength, (_) => _codeAlphabet[random.nextInt(_codeAlphabet.length)]).join();
}

String formatRecoveryCode(String code) =>
    [for (var i = 0; i < code.length; i += 4) code.substring(i, min(i + 4, code.length))].join('-');

/// Accepts the code as typed: any case, with or without separators.
String normalizeRecoveryCode(String input) => input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// Login for the own server, so a new device needs nothing but the code.
/// Independent of the backup key: the server learns neither the code nor anything that decrypts.
Future<({String account, String token})> serverCredentials(String code) async {
  final secret = SecretKey(utf8.encode(normalizeRecoveryCode(code)));
  Future<List<int>> derive(String info, int length) async =>
      (await Hkdf(hmac: Hmac.sha256(), outputLength: length).deriveKey(
        secretKey: secret,
        nonce: utf8.encode('whatseat-server-v1'),
        info: utf8.encode(info),
      ))
          .extractBytes();
  final account = await derive('account', 16);
  return (
    account: account.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    token: base64UrlEncode(await derive('token', 32)).replaceAll('=', ''),
  );
}

const minAutoBackupPasswordLength = 16;

/// A user-chosen secret guards files stored by third parties, who can guess offline at leisure.
bool isStrongBackupPassword(String password) {
  final classes = [RegExp('[a-z]'), RegExp('[A-Z]'), RegExp('[0-9]'), RegExp('[^a-zA-Z0-9]')]
      .where((c) => c.hasMatch(password))
      .length;
  return password.length >= minAutoBackupPasswordLength &&
      password.runes.toSet().length >= 8 &&
      (classes >= 3 || password.length >= 24);
}

/// A derived backup key, kept so automatic backups don't pay for Argon2 each time.
class BackupKey {
  const BackupKey({
    required this.key,
    required this.salt,
    required this.recoveryCode,
    this.memory = _memory,
    this.iterations = _iterations,
    this.parallelism = _parallelism,
  });

  final List<int> key;
  final List<int> salt;

  /// Restoring then normalizes the typed secret like a recovery code.
  final bool recoveryCode;
  final int memory;
  final int iterations;
  final int parallelism;

  /// Names the backup series in file names, so setups sharing a location don't overwrite or prune each other.
  /// Taken from the salt, which every file of the series carries in the clear anyway.
  String get series => salt.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Map<String, dynamic> toJson() => {
        'key': base64Encode(key),
        'salt': base64Encode(salt),
        'recoveryCode': recoveryCode,
        'memory': memory,
        'iterations': iterations,
        'parallelism': parallelism,
      };

  factory BackupKey.fromJson(Map<String, dynamic> json) => BackupKey(
        key: base64Decode(json['key'] as String),
        salt: base64Decode(json['salt'] as String),
        recoveryCode: json['recoveryCode'] as bool,
        memory: json['memory'] as int,
        iterations: json['iterations'] as int,
        parallelism: json['parallelism'] as int,
      );
}

/// Key derivation takes a second or two, so it runs off the UI isolate.
Future<BackupKey> deriveBackupKey(String secret, {required bool recoveryCode}) {
  final random = Random.secure();
  final salt = List.generate(16, (_) => random.nextInt(256));
  return _derive(recoveryCode ? normalizeRecoveryCode(secret) : secret, salt, recoveryCode: recoveryCode);
}

Future<BackupKey> _derive(String secret, List<int> salt,
        {required bool recoveryCode,
        int memory = _memory,
        int iterations = _iterations,
        int parallelism = _parallelism}) =>
    Isolate.run(() async {
      final key = await Argon2id(memory: memory, iterations: iterations, parallelism: parallelism, hashLength: 32)
          .deriveKeyFromPassword(password: secret, nonce: salt);
      return BackupKey(
        key: await key.extractBytes(),
        salt: salt,
        recoveryCode: recoveryCode,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
    });

Future<Map<String, dynamic>> encryptBackup(Map<String, dynamic> backup, String password) async =>
    encryptBackupWithKey(backup, await deriveBackupKey(password, recoveryCode: false));

Future<Map<String, dynamic>> encryptBackupWithKey(Map<String, dynamic> backup, BackupKey key) =>
    Isolate.run(() async {
      final box = await AesGcm.with256bits().encrypt(utf8.encode(jsonEncode(backup)), secretKey: SecretKey(key.key));
      return {
        'format': encryptedBackupFormat,
        'kdf': {
          'algorithm': 'argon2id',
          'memory': key.memory,
          'iterations': key.iterations,
          'parallelism': key.parallelism,
          'salt': base64Encode(key.salt),
          if (key.recoveryCode) 'secret': 'recovery-code',
        },
        'cipher': 'aes-256-gcm',
        'nonce': base64Encode(box.nonce),
        'ciphertext': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      };
    });

bool usesRecoveryCode(Map<String, dynamic> json) => (json['kdf'] as Map<String, dynamic>)['secret'] == 'recovery-code';

Future<Map<String, dynamic>> decryptBackup(Map<String, dynamic> json, String password) async =>
    decryptBackupWithKey(json, await backupKeyFor(json, password));

/// Derives the key with the file's own parameters, so it can be kept for further backups to the same place.
Future<BackupKey> backupKeyFor(Map<String, dynamic> json, String secret) {
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
  final recoveryCode = usesRecoveryCode(json);
  return _derive(recoveryCode ? normalizeRecoveryCode(secret) : secret, base64Decode(kdf['salt'] as String),
      recoveryCode: recoveryCode, memory: memory, iterations: iterations, parallelism: parallelism);
}

Future<Map<String, dynamic>> decryptBackupWithKey(Map<String, dynamic> json, BackupKey key) {
  final box = SecretBox(
    base64Decode(json['ciphertext'] as String),
    nonce: base64Decode(json['nonce'] as String),
    mac: Mac(base64Decode(json['mac'] as String)),
  );
  return Isolate.run(() async {
    final List<int> clear;
    try {
      clear = await AesGcm.with256bits().decrypt(box, secretKey: SecretKey(key.key));
    } on SecretBoxAuthenticationError {
      throw WrongBackupPasswordException();
    }
    return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
  });
}
