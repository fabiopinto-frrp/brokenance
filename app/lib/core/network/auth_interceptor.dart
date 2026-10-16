import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/session_storage.dart';

/// Adds the access token to every request and keeps the user logged in:
///
/// When a request fails with 401 (the 15-minute access token expired), it calls
/// `POST /auth/refresh` once, saves the new tokens and retries the request. If several requests
/// fail at the same time, they all wait for that one refresh: the API rotates refresh tokens
/// and treats a reused one as stolen, so refreshing twice would log the user out everywhere.
///
/// When the refresh itself is rejected, the session is over: it is cleared and
/// [onSessionExpired] is called (the app then shows the login screen).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.refreshDio,
    required this.session,
    required this.onSessionExpired,
  });

  /// The client that sent the request, used to retry it.
  final Dio dio;

  /// A client without this interceptor, used for the refresh call.
  final Dio refreshDio;
  final SessionStorage session;
  final void Function() onSessionExpired;

  /// Requests with `extra: {'auth': false}` (login, register, refresh) get no token.
  static const authKey = 'auth';
  static const _retriedKey = 'auth_retried';

  Future<Session?>? _refreshing;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[authKey] != false) {
      final current = await session.read();
      if (current != null) {
        options.headers['Authorization'] = 'Bearer ${current.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final canRetry =
        err.response?.statusCode == 401 &&
        options.extra[authKey] != false &&
        options.extra[_retriedKey] != true;
    if (!canRetry) return handler.next(err);

    final current = await session.read();
    if (current == null) return handler.next(err);

    // Another request may have refreshed the tokens while this one was in flight.
    final sentToken = (options.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');
    Session? fresh = current.accessToken != sentToken ? current : null;

    if (fresh == null) {
      try {
        fresh = await _refreshOnce(current.refreshToken);
      } on DioException {
        // Network problem during the refresh: keep the session, report the original err.
        return handler.next(err);
      }
    }

    if (fresh == null) {
      await session.clear();
      onSessionExpired();
      return handler.next(err);
    }

    try {
      final retry = options.copyWith(
        headers: {...options.headers, 'Authorization': 'Bearer ${fresh.accessToken}'},
        extra: {...options.extra, _retriedKey: true},
      );
      handler.resolve(await dio.fetch(retry));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Runs at most one refresh at a time. Returns null when the API rejects the refresh token.
  Future<Session?> _refreshOnce(String refreshToken) {
    return _refreshing ??= _refresh(refreshToken).whenComplete(() => _refreshing = null);
  }

  Future<Session?> _refresh(String refreshToken) async {
    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final body = response.data!;
      final fresh = Session(
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String,
      );
      await session.save(fresh);
      return fresh;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 400) return null;
      rethrow;
    }
  }
}
