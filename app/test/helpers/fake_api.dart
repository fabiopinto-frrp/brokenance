import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A fake API server for tests: answers every request with [handler] and records the calls.
class FakeApi implements HttpClientAdapter {
  FakeApi(this.handler);

  final FakeResponse Function(RequestOptions request) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    // Lets concurrent requests overlap, like a real network.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final response = handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  List<RequestOptions> callsTo(String path) => requests.where((request) => request.path == path).toList();

  @override
  void close({bool force = false}) {}
}

class FakeResponse {
  const FakeResponse(this.status, [this.body = const {}]);

  final int status;
  final Object body;

  static FakeResponse error(int status, String code) => FakeResponse(status, {
    'error': {'code': code, 'message': code},
  });
}
