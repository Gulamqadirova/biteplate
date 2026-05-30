import 'dart:convert';
import 'dart:io';

import '../domain/errors.dart';
import '../domain/restaurant_service.dart';

class ApiServer {
  final RestaurantService _service;
  final int port;

  ApiServer(this._service, {this.port = 8080});

  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    stdout.writeln('BitePlate API listening on http://localhost:$port/api');
    await for (final request in server) {
      _handle(request);
    }
  }

  Future<void> _handle(HttpRequest request) async {
    _setCors(request.response);
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    final path = request.uri.path;
    try {
      final result = await _route(request, path);
      _writeJson(request.response, HttpStatus.ok, result);
    } on DomainException catch (e) {
      _writeJson(request.response, HttpStatus.badRequest,
          {'success': false, 'error': e.message});
    } catch (e) {
      stderr.writeln('Unhandled error on $path: $e');
      _writeJson(request.response, HttpStatus.internalServerError,
          {'success': false, 'error': 'An unexpected server error occurred.'});
    }
  }

  Future<dynamic> _route(HttpRequest request, String path) async {
    final method = request.method;
    final segments =
        path.split('/').where((s) => s.isNotEmpty).toList(); // e.g. [api, tables, 3, seat]

    if (segments.isEmpty || segments.first != 'api') {
      throw const DomainException('Unknown endpoint.');
    }
    final route = segments.sublist(1);

    // ── GET read models ──
    if (method == 'GET') {
      return switch (route) {
        ['tables'] => _service.tablesJson(),
        ['menu'] => _service.menuJson(),
        ['orders'] => _service.ordersJson(),
        ['staff'] => _service.staffJson(),
        ['notifications'] => _service.notificationsJson(),
        ['dashboard'] => _service.dashboardJson(),
        ['history'] => _service.historyJson(),
        ['kitchen', 'queue'] => _service.kitchenQueueJson(),
        ['billing', 'strategies'] => _service.billingStrategiesJson(),
        _ => throw const DomainException('Unknown endpoint.'),
      };
    }

    // ── POST commands ──
    if (method == 'POST') {
      final body = await _readJson(request);
      return switch (route) {
        ['tables', final n, 'seat'] => _service.seatTable(_int(n)),
        ['tables', final n, 'reserve'] => _service.reserveTable(_int(n)),
        ['tables', final n, 'clear'] => _service.clearTable(_int(n)),
        ['orders'] => _service.placeOrder(body),
        ['kitchen', 'process'] => _service.processKitchen(),
        ['kitchen', 'undo'] => _service.undoKitchen(),
        ['billing', 'generate'] => _service.generateBill(body),
        ['billing', 'split'] => _service.splitBill(body),
        ['billing', 'strategy'] => _service.setStrategy(body),
        _ => throw const DomainException('Unknown endpoint.'),
      };
    }

    throw const DomainException('Unsupported method.');
  }

  int _int(String raw) {
    final value = int.tryParse(raw);
    if (value == null) throw DomainException('"$raw" is not a valid number.');
    return value;
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final raw = await utf8.decoder.bind(request).join();
    if (raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const DomainException('Request body must be a JSON object.');
    } on FormatException {
      throw const DomainException('Request body is not valid JSON.');
    }
  }

  void _setCors(HttpResponse response) {
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type');
  }

  void _writeJson(HttpResponse response, int status, dynamic body) {
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    response.close();
  }
}
