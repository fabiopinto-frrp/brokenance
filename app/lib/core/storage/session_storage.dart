import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The tokens of the logged-in user.
class Session extends Equatable {
  const Session({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

/// Keeps the session between app launches, so the user stays logged in.
abstract interface class SessionStorage {
  Future<Session?> read();
  Future<void> save(Session session);
  Future<void> clear();
}

/// Stores the tokens in the iOS Keychain / Android Keystore. Values are cached in memory so the
/// secure storage is only read once per launch.
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Session? _cache;
  bool _loaded = false;

  @override
  Future<Session?> read() async {
    if (_loaded) return _cache;
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    _cache = access != null && refresh != null ? Session(accessToken: access, refreshToken: refresh) : null;
    _loaded = true;
    return _cache;
  }

  @override
  Future<void> save(Session session) async {
    _cache = session;
    _loaded = true;
    await _storage.write(key: _accessKey, value: session.accessToken);
    await _storage.write(key: _refreshKey, value: session.refreshToken);
  }

  @override
  Future<void> clear() async {
    _cache = null;
    _loaded = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// In-memory storage, for tests.
class MemorySessionStorage implements SessionStorage {
  MemorySessionStorage([this._session]);

  Session? _session;

  @override
  Future<Session?> read() async => _session;

  @override
  Future<void> save(Session session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
