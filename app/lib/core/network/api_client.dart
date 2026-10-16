import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/session_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// The only place that talks HTTP. Repositories call these methods and get decoded JSON back,
/// or an [ApiException].
class ApiClient {
  ApiClient({required String baseUrl, required this.session, HttpClientAdapter? adapter}) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    _dio = Dio(options);
    final refreshDio = Dio(options);
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
      refreshDio.httpClientAdapter = adapter;
    }
    _dio.interceptors.add(
      AuthInterceptor(
        dio: _dio,
        refreshDio: refreshDio,
        session: session,
        onSessionExpired: () => _sessionExpired.add(null),
      ),
    );
  }

  late final Dio _dio;
  final SessionStorage session;
  final _sessionExpired = StreamController<void>.broadcast();

  /// Fires when the session ends on its own (the refresh token expired or was revoked).
  Stream<void> get sessionExpired => _sessionExpired.stream;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<T>(path, queryParameters: query));

  /// [authenticated] is false for login, register and refresh.
  Future<T> post<T>(String path, {Object? data, bool authenticated = true}) =>
      _send(() => _dio.post<T>(path, data: data, options: _options(authenticated)));

  Future<T> put<T>(String path, {Object? data}) => _send(() => _dio.put<T>(path, data: data));

  Future<void> delete(String path) => _send(() => _dio.delete<void>(path));

  Options _options(bool authenticated) => Options(extra: {AuthInterceptor.authKey: authenticated});

  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return (await request()).data as T;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  void dispose() {
    _sessionExpired.close();
    _dio.close();
  }
}
