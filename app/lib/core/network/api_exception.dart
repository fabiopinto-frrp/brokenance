import 'package:dio/dio.dart';

/// An error from the API, already decoded. [code] is the stable code the backend sends
/// (`invalid_credentials`, `date_in_future`...) or one of the client-side codes below. Show it
/// to the user with `apiErrorMessage` (translated), never the raw [message].
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.statusCode, this.details});

  /// The server could not be reached.
  static const network = 'network_error';

  /// The server took too long to answer.
  static const timeout = 'timeout';

  /// The answer was not the expected JSON.
  static const unknown = 'unknown_error';

  final String code;
  final String message;
  final int? statusCode;

  /// For `validation_error`: the list of invalid fields sent by the API.
  final Object? details;

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
        return ApiException(code: network, message: error.message ?? 'Connection error');
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(code: timeout, message: error.message ?? 'Timeout');
      default:
        break;
    }

    final response = error.response;
    final body = response?.data;
    if (body is Map && body['error'] is Map) {
      final apiError = body['error'] as Map;
      return ApiException(
        code: apiError['code'] as String? ?? unknown,
        message: apiError['message'] as String? ?? '',
        statusCode: response?.statusCode,
        details: apiError['details'],
      );
    }
    return ApiException(
      code: unknown,
      message: error.message ?? 'Unknown error',
      statusCode: response?.statusCode,
    );
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
