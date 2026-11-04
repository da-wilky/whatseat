import 'package:flutter_test/flutter_test.dart';
import 'package:whatseat/data/auto_backup.dart';
import 'package:whatseat/data/backup_crypto.dart';
import 'package:whatseat/data/backup_destinations.dart';

void main() {
  test('recovery codes are typed back in any case and grouping', () {
    final code = generateRecoveryCode();
    expect(code, matches(RegExp(r'^[A-HJKMNP-Z2-9]{24}$')));
    final formatted = formatRecoveryCode(code);
    expect(formatted.split('-'), hasLength(6));
    expect(normalizeRecoveryCode(' ${formatted.toLowerCase().replaceAll('-', ' ')} '), code);
  });

  test('automatic backup passwords must be strong', () {
    expect(isStrongBackupPassword('Short1!'), isFalse);
    expect(isStrongBackupPassword('alllowercaseletters'), isFalse);
    expect(isStrongBackupPassword('aaaaaaaaAAAAAAAA1111'), isFalse);
    expect(isStrongBackupPassword('Kaffee mit 3 Stück Zucker'), isTrue);
    expect(isStrongBackupPassword('morgens gibt es immer haferbrei'), isTrue);
  });

  test('a backup made with a stored key opens with the recovery code as typed', () async {
    final code = generateRecoveryCode();
    final key = await deriveBackupKey(formatRecoveryCode(code), recoveryCode: true);
    final restored = BackupKey.fromJson(key.toJson());
    final encrypted = await encryptBackupWithKey({'format': backupFormat, 'entries': []}, restored);
    expect(usesRecoveryCode(encrypted), isTrue);

    final backup = await decryptBackup(encrypted, formatRecoveryCode(code).toLowerCase());
    expect(backup['format'], backupFormat);
    await expectLater(decryptBackup(encrypted, generateRecoveryCode()), throwsA(isA<WrongBackupPasswordException>()));
  });

  test('password backups keep the password exactly as typed', () async {
    final encrypted = await encryptBackup({'format': backupFormat}, 'Secret pass 1234');
    expect(usesRecoveryCode(encrypted), isFalse);
    await expectLater(decryptBackup(encrypted, 'SECRET PASS 1234'), throwsA(isA<WrongBackupPasswordException>()));
  });

  test('config round-trips and WebDAV insists on https', () {
    final config = AutoBackupConfig(
      destination: WebDavDestination(url: 'https://cloud.example.com/dav/WhatsEat', user: 'u', password: 'p'),
      key: const BackupKey(key: [1, 2], salt: [3], recoveryCode: true),
    );
    final copy = AutoBackupConfig.fromJson(config.toJson());
    expect((copy.destination as WebDavDestination).url, 'https://cloud.example.com/dav/WhatsEat/');
    expect(copy.destination.label, 'cloud.example.com/dav/WhatsEat/');
    expect(() => WebDavDestination(url: 'http://nas.local/dav', user: 'u', password: 'p'), throwsFormatException);
  });

  // Reference values from `openssl kdf … HKDF`; changing the derivation would lock users out of their accounts.
  test('server login derives from the recovery code as typed', () async {
    final login = await serverCredentials('abcd-efgh-jkmn-pqrs-tuvw-xyz2');
    expect(login.account, 'f83ce4128076ce45325cb8b4b0d3af7a');
    expect(login.token, 'CgbXcJrZq2uQJb-dN_NNzJaPQxGVtuo6bxuPVpy3NDk');

    final destination = BackupDestination.fromJson(
        ServerDestination(url: 'https://backup.example.com', account: login.account, token: login.token).toJson());
    expect(destination, isA<ServerDestination>().having((d) => d.url, 'url', 'https://backup.example.com/'));
  });

  test('an invite link fills in server and invite', () {
    expect(parseServerAddress(' https://backup.example.org/#invite=ABCD2345 '),
        (url: 'https://backup.example.org/', invite: 'ABCD2345'));
    expect(parseServerAddress('https://backup.example.org'), (url: 'https://backup.example.org', invite: null));
  });

  test('backup names carry day and series', () {
    const key = BackupKey(key: [], salt: [0x0a, 0x1b, 0x2c, 0x3d, 0xff], recoveryCode: true);
    expect(key.series, '0a1b2c3d');
    expect(backupDay('whatseat-backup-2026-11-04-0a1b2c3d.json'), DateTime(2026, 11, 4));
    expect(backupSeries('whatseat-backup-2026-11-04-0a1b2c3d.json'), '0a1b2c3d');
    expect(backupSeries('whatseat-backup-2026-11-04.json'), isNull);
  });
}
