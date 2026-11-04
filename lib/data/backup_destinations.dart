import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class BackupDestinationException implements Exception {
  const BackupDestinationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Where automatic backups go. Holds only already encrypted files.
sealed class BackupDestination {
  const BackupDestination();

  String get label;

  /// Checks access and creates the target folder if needed.
  Future<void> connect();
  Future<List<String>> list();
  Future<List<int>> read(String name);
  Future<void> write(String name, List<int> bytes);
  Future<void> delete(String name);

  Map<String, dynamic> toJson();

  factory BackupDestination.fromJson(Map<String, dynamic> json) => switch (json['type']) {
        'webdav' => WebDavDestination(
            url: json['url'] as String,
            user: json['user'] as String,
            password: json['password'] as String,
          ),
        'folder' => FolderDestination(uri: json['uri'] as String, name: json['name'] as String),
        'server' => ServerDestination(
            url: json['url'] as String,
            account: json['account'] as String,
            token: json['token'] as String,
          ),
        final type => throw FormatException('Unknown backup destination $type'),
      };
}

/// Normalized to end in a slash, so relative paths resolve inside it.
/// Credentials go with every request, hence https only.
String httpsBaseUrl(String url) {
  final normalized = url.endsWith('/') ? url : '$url/';
  final uri = Uri.tryParse(normalized);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    throw const FormatException('Needs an https:// address');
  }
  return normalized;
}

/// Far above any real backup; stops a hostile location from exhausting memory.
const maxResponseBytes = 64 << 20;

/// Responses come from storage the app doesn't trust, so anything malformed becomes a destination error.
T _parse<T>(List<int> body, T Function(Object? json) read) {
  try {
    return read(jsonDecode(utf8.decode(body)));
  } on Object {
    throw const BackupDestinationException('Unexpected response from the server');
  }
}

Future<(int, List<int>)> _send(String method, Uri uri, String? authorization,
    {List<int>? body, Map<String, String> headers = const {}}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    return await () async {
      final request = await client.openUrl(method, uri);
      request.followRedirects = false;
      if (authorization != null) request.headers.set(HttpHeaders.authorizationHeader, authorization);
      headers.forEach(request.headers.set);
      if (body != null) {
        request.contentLength = body.length;
        request.add(body);
      }
      final response = await request.close();
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        bytes.add(chunk);
        if (bytes.length > maxResponseBytes) throw const BackupDestinationException('Response too large');
      }
      return (response.statusCode, bytes.takeBytes() as List<int>);
    }()
        .timeout(const Duration(seconds: 60));
  } on SocketException catch (e) {
    throw BackupDestinationException(e.message);
  } on HandshakeException catch (e) {
    throw BackupDestinationException(e.message);
  } on HttpException catch (e) {
    throw BackupDestinationException(e.message);
  } on TimeoutException {
    throw const BackupDestinationException('Server not responding');
  } finally {
    client.close(force: true);
  }
}

void _expect(String method, int status, Set<int> ok) {
  if (ok.contains(status)) return;
  throw BackupDestinationException(switch (status) {
    401 || 403 => 'Login rejected (HTTP $status)',
    404 => 'Not found (HTTP 404)',
    507 => 'Storage full (HTTP 507)',
    _ => '$method failed (HTTP $status)',
  });
}

class ServerInfo {
  const ServerInfo({required this.inactiveDays, required this.inviteOnly});

  /// Zero means accounts are kept forever.
  final int inactiveDays;
  final bool inviteOnly;

  factory ServerInfo.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return ServerInfo(inactiveDays: map['inactiveDays'] as int, inviteOnly: map['inviteOnly'] as bool);
  }
}

/// An invite link is the server address with `#invite=<code>`, so one paste fills in both.
({String url, String? invite}) parseServerAddress(String input) {
  final hash = input.indexOf('#');
  if (hash < 0) return (url: input.trim(), invite: null);
  final fragment = input.substring(hash + 1).trim();
  return (
    url: input.substring(0, hash).trim(),
    invite: fragment.startsWith('invite=') ? fragment.substring('invite='.length) : null,
  );
}

/// The own WhatsEat server. Login is derived from the recovery code.
final class ServerDestination extends BackupDestination {
  ServerDestination({required String url, required this.account, required this.token}) : url = httpsBaseUrl(url);

  final String url;
  final String account;
  final String token;

  Uri _api(String path) => Uri.parse(url).resolve('v1/$path');
  String get _auth => 'Bearer $account.$token';

  @override
  String get label => Uri.parse(url).host;

  /// What the server tells before login: when it deletes inactive accounts, and whether it needs an invite.
  static Future<ServerInfo> info(String url) async {
    final (status, body) = await _send('GET', Uri.parse(httpsBaseUrl(url)).resolve('v1/info'), null);
    _expect('Info', status, {200});
    return _parse(body, ServerInfo.fromJson);
  }

  /// Creates the account on first use, using up [invite]; with an existing account it just checks the login.
  Future<void> register({String? invite}) async {
    final (status, body) = await _send('POST', _api('register'), _auth,
        body: invite == null ? null : utf8.encode(jsonEncode({'invite': invite})),
        headers: {'Content-Type': 'application/json'});
    // The server says why: invite missing, invalid or expired, or registration closed.
    if (status == 403) throw BackupDestinationException(utf8.decode(body).trim());
    _expect('Register', status, {201, 204});
  }

  /// Counts as activity, so the account isn't deleted while the app is in use without changes.
  Future<ServerInfo> ping() async {
    final (status, body) = await _send('POST', _api('ping'), _auth);
    _expect('Ping', status, {200});
    return _parse(body, ServerInfo.fromJson);
  }

  /// Deletes the account with all its backups. An account the server already deleted counts as done.
  Future<void> deleteAccount() async {
    final (status, _) = await _send('DELETE', _api('account'), _auth);
    _expect('Delete account', status, {204, 401});
  }

  @override
  Future<void> connect() async {
    final (status, _) = await _send('GET', _api('backups'), _auth);
    if (status == 401) throw const BackupDestinationException('No backups for this recovery code on the server');
    _expect('List', status, {200});
  }

  @override
  Future<List<String>> list() async {
    final (status, body) = await _send('GET', _api('backups'), _auth);
    _expect('List', status, {200});
    return _parse(body, (json) => [for (final b in json as List) (b as Map<String, dynamic>)['name'] as String]);
  }

  @override
  Future<List<int>> read(String name) async {
    final (status, body) = await _send('GET', _api('backups/${Uri.encodeComponent(name)}'), _auth);
    _expect('GET', status, {200});
    return body;
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    Future<int> put() async => (await _send('PUT', _api('backups/${Uri.encodeComponent(name)}'), _auth,
            body: bytes, headers: {'Content-Type': 'application/json'}))
        .$1;
    var status = await put();
    // The login only fails once the server deleted the account, e.g. after inactivity: it is created anew.
    if (status == 401) {
      try {
        await register();
      } on BackupDestinationException catch (e) {
        throw BackupDestinationException('The server deleted this account and can\'t recreate it ($e). '
            'Turn automatic backup off and set it up again.');
      }
      status = await put();
    }
    _expect('PUT', status, {204});
  }

  @override
  Future<void> delete(String name) async {
    final (status, _) = await _send('DELETE', _api('backups/${Uri.encodeComponent(name)}'), _auth);
    _expect('DELETE', status, {204, 404});
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'server', 'url': url, 'account': account, 'token': token};
}

/// Null for a malformed percent-encoding, which can't be one of our file names anyway.
String? _decodeOrNull(String encoded) {
  try {
    return Uri.decodeComponent(encoded);
  } on ArgumentError {
    return null;
  }
}

/// Nextcloud, ownCloud and most NAS systems.
final class WebDavDestination extends BackupDestination {
  WebDavDestination({required String url, required this.user, required this.password}) : url = httpsBaseUrl(url);

  final String url;
  final String user;
  final String password;

  Uri get _folder => Uri.parse(url);
  Uri _file(String name) => _folder.resolve(Uri.encodeComponent(name));

  @override
  String get label => '${_folder.host}${Uri.decodeComponent(_folder.path)}';

  String get _authorization => 'Basic ${base64Encode(utf8.encode('$user:$password'))}';

  Future<(int, List<int>)> _request(String method, Uri uri, {List<int>? body, Map<String, String> headers = const {}}) =>
      _send(method, uri, _authorization, body: body, headers: headers);

  /// Null when the folder doesn't exist.
  Future<List<String>?> _propfind() async {
    final (status, body) = await _request('PROPFIND', _folder, headers: {'Depth': '1'});
    if (status == 404) return null;
    _expect('PROPFIND', status, {207});
    final String xml;
    try {
      xml = utf8.decode(body);
    } on FormatException {
      throw const BackupDestinationException('Unexpected response from the server');
    }
    // Only the hrefs matter; the namespace prefix varies between servers.
    return [
      for (final m in RegExp(r'<(?:\w+:)?href>([^<]*)</(?:\w+:)?href>').allMatches(xml))
        ?_decodeOrNull(m.group(1)!.split('/').lastWhere((s) => s.isNotEmpty, orElse: () => '')),
    ];
  }

  @override
  Future<void> connect() async {
    if (await _propfind() != null) return;
    final (status, _) = await _request('MKCOL', _folder);
    _expect('MKCOL', status, {201});
  }

  @override
  Future<List<String>> list() async => await _propfind() ?? const [];

  @override
  Future<List<int>> read(String name) async {
    final (status, body) = await _request('GET', _file(name));
    _expect('GET', status, {200});
    return body;
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    final (status, _) = await _request('PUT', _file(name), body: bytes, headers: {'Content-Type': 'application/json'});
    _expect('PUT', status, {200, 201, 204});
  }

  @override
  Future<void> delete(String name) async {
    final (status, _) = await _request('DELETE', _file(name));
    _expect('DELETE', status, {200, 204, 404});
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'webdav', 'url': url, 'user': user, 'password': password};
}

const _folderChannel = MethodChannel('whatseat/folder');

/// A folder picked through the system: local storage or any provider app (Google Drive, Nextcloud, iCloud Drive, …).
final class FolderDestination extends BackupDestination {
  const FolderDestination({required this.uri, required this.name});

  /// Android tree URI or iOS security-scoped bookmark; opaque to Dart.
  final String uri;
  final String name;

  /// Null when cancelled.
  static Future<FolderDestination?> pick() async {
    final picked = await _call<Map<Object?, Object?>>('pick', null);
    return picked == null ? null : FolderDestination(uri: picked['uri'] as String, name: picked['name'] as String);
  }

  static Future<T?> _call<T>(String method, Object? args) async {
    try {
      return await _folderChannel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw BackupDestinationException(e.message ?? e.code);
    }
  }

  @override
  String get label => name;

  @override
  Future<void> connect() => list();

  @override
  Future<List<String>> list() async => [...?await _call<List<Object?>>('list', {'uri': uri})].cast<String>();

  @override
  Future<List<int>> read(String name) async =>
      (await _call<Uint8List>('read', {'uri': uri, 'name': name}))!;

  @override
  Future<void> write(String name, List<int> bytes) =>
      _call<void>('write', {'uri': uri, 'name': name, 'bytes': Uint8List.fromList(bytes)});

  @override
  Future<void> delete(String name) => _call<void>('delete', {'uri': uri, 'name': name});

  /// Gives back the lasting access granted when the folder was picked; Android caps how many an app may hold.
  Future<void> release() => _call<void>('release', {'uri': uri});

  @override
  Map<String, dynamic> toJson() => {'type': 'folder', 'uri': uri, 'name': name};
}
