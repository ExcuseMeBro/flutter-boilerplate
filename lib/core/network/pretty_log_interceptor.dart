import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Receives one fully rendered log block (may contain newlines).
typedef LogPrinter = void Function(String block);

/// Emoji-tagged, boxed Dio logger meant for debug builds.
///
/// Renders each request / response / error as a single block so concurrent
/// requests do not interleave line by line. Sensitive headers and body fields
/// are redacted, JSON is pretty printed, `FormData` is summarised, and each
/// exchange carries a short correlation id plus its round-trip duration.
class PrettyLogInterceptor extends Interceptor {
  PrettyLogInterceptor({
    this.requestHeaders = true,
    this.requestBody = true,
    this.responseHeaders = false,
    this.responseBody = true,
    this.errorBody = true,
    this.maxBodyChars = 4000,
    this.width = 64,
    LogPrinter? printer,
  }) : _print = printer ?? debugPrint;

  final bool requestHeaders;
  final bool requestBody;
  final bool responseHeaders;
  final bool responseBody;
  final bool errorBody;

  /// Bodies longer than this are cut off with a `truncated` marker.
  final int maxBodyChars;

  /// Target width of the box borders.
  final int width;

  final LogPrinter _print;

  /// `extra` key holding the short correlation id of a request.
  static const requestIdKey = '__pretty_log_id__';

  /// `extra` key holding the request start time in milliseconds since epoch.
  static const startedAtKey = '__pretty_log_started_at__';

  static const _redactedHeaders = <String>{
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
  };

  static const _redactedFields = <String>{
    'password',
    'password1',
    'password2',
    'new_password',
    'old_password',
    'confirm_password',
    'token',
    'access',
    'refresh',
    'access_token',
    'refresh_token',
    'secret',
    'client_secret',
    'api_key',
  };

  static const _encoder = JsonEncoder.withIndent('  ');

  static int _counter = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = _nextId();
    options.extra[requestIdKey] = id;
    options.extra[startedAtKey] = DateTime.now().millisecondsSinceEpoch;

    final method = options.method.toUpperCase();
    final lines = <String>[
      _top('🚀 REQUEST', id),
      _row('${_methodEmoji(method)} $method  ${options.path}'),
      _row('🌐 ${options.uri}'),
    ];

    if (options.queryParameters.isNotEmpty) {
      lines.add(_row('🔎 Query'));
      options.queryParameters.forEach((key, value) {
        lines.add(_row('   $key: ${_redactValue(key, value)}'));
      });
    }

    if (requestHeaders && options.headers.isNotEmpty) {
      lines.add(_row('📋 Headers'));
      options.headers.forEach((key, value) {
        lines.add(_row('   $key: ${_redactHeader(key, value)}'));
      });
    }

    if (requestBody && options.data != null) {
      lines.addAll(_bodyRows('📦 Body', options.data));
    }

    lines.add(_bottom());
    _emit(lines);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final status = response.statusCode ?? 0;
    final method = options.method.toUpperCase();

    final lines = <String>[
      _top('${_statusEmoji(status)} RESPONSE', _idOf(options)),
      _row('📥 $method  ${options.path}'),
      _row('🏷️ $status ${response.statusMessage ?? ''}'.trimRight()),
      _row('⏱️ ${_elapsed(options)}'),
    ];

    if (responseHeaders) {
      final headers = response.headers.map;
      if (headers.isNotEmpty) {
        lines.add(_row('📋 Headers'));
        headers.forEach((key, values) {
          lines.add(_row('   $key: ${_redactHeader(key, values.join('; '))}'));
        });
      }
    }

    if (responseBody && response.data != null) {
      lines.addAll(_bodyRows('📦 Body', response.data));
    }

    lines.add(_bottom());
    _emit(lines);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final status = err.response?.statusCode;
    final method = options.method.toUpperCase();

    final lines = <String>[
      _top('❌ ERROR', _idOf(options)),
      _row('📥 $method  ${options.path}'),
      if (status != null)
        _row('🏷️ $status ${err.response?.statusMessage ?? ''}'.trimRight()),
      _row('🧨 ${err.type.name}'),
      if (err.message != null && err.message!.isNotEmpty)
        _row('💬 ${err.message}'),
      _row('⏱️ ${_elapsed(options)}'),
    ];

    if (errorBody && err.response?.data != null) {
      lines.addAll(_bodyRows('📦 Body', err.response!.data));
    }

    lines.add(_bottom());
    _emit(lines);
    handler.next(err);
  }

  // ---------------------------------------------------------------- rendering

  void _emit(List<String> lines) => _print(lines.join('\n'));

  String _top(String title, String id) {
    final label = '─ $title · #$id ';
    final fill = math.max(3, width - _displayWidth(label));
    return '┌$label${'─' * fill}';
  }

  /// Terminals render emoji two cells wide and drop variation selectors, so
  /// `String.length` would make the top border ragged.
  static int _displayWidth(String value) {
    var cells = 0;
    for (final rune in value.runes) {
      if (rune == 0xfe0f) continue; // variation selector, zero width
      cells += rune >= 0x1f300 || (rune >= 0x2600 && rune <= 0x27bf) ? 2 : 1;
    }
    return cells;
  }

  String _bottom() => '└${'─' * (width - 1)}';

  String _row(String content) => '│ $content';

  List<String> _bodyRows(String label, Object? data) {
    final rendered = _truncate(_stringify(data));
    return [
      _row(label),
      ...rendered.split('\n').map((line) => _row('   $line')),
    ];
  }

  String _stringify(Object? data) {
    if (data == null) return 'null';

    if (data is FormData) {
      final fields = data.fields
          .map((entry) => '${entry.key}: ${_redactValue(entry.key, entry.value)}');
      final files = data.files.map(
        (entry) => '${entry.key}: 📎 ${entry.value.filename ?? 'file'} '
            '(${entry.value.length} bytes)',
      );
      return [...fields, ...files].join('\n');
    }

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return trimmed;
      try {
        return _encoder.convert(_redact(jsonDecode(trimmed)));
      } catch (_) {
        return data;
      }
    }

    try {
      return _encoder.convert(_redact(data));
    } catch (_) {
      return data.toString();
    }
  }

  String _truncate(String value) {
    if (value.length <= maxBodyChars) return value;
    final cut = value.substring(0, maxBodyChars);
    final rest = value.length - maxBodyChars;
    return '$cut\n… truncated ($rest more chars)';
  }

  // ---------------------------------------------------------------- redaction

  Object? _redact(Object? value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          _isSensitive(key.toString()) ? _mask(item) : _redact(item),
        ),
      );
    }
    if (value is Iterable) {
      return value.map(_redact).toList();
    }
    return value;
  }

  Object _redactValue(String key, Object? value) =>
      _isSensitive(key) ? _mask(value) : (value ?? 'null');

  String _redactHeader(String key, Object? value) =>
      _redactedHeaders.contains(key.toLowerCase())
          ? _mask(value)
          : '${value ?? ''}';

  bool _isSensitive(String key) => _redactedFields.contains(key.toLowerCase());

  String _mask(Object? value) {
    if (value is String && value.isNotEmpty) {
      return '••••••• (${value.length} chars)';
    }
    return '•••••••';
  }

  // ------------------------------------------------------------------ helpers

  static String _nextId() {
    _counter = (_counter + 1) & 0xffff;
    return _counter.toRadixString(16).padLeft(4, '0');
  }

  String _idOf(RequestOptions options) {
    final id = options.extra[requestIdKey];
    return id is String ? id : '----';
  }

  String _elapsed(RequestOptions options) {
    final startedAt = options.extra[startedAtKey];
    if (startedAt is! int) return '—';
    final ms = DateTime.now().millisecondsSinceEpoch - startedAt;
    return ms < 1000 ? '${ms}ms' : '${(ms / 1000).toStringAsFixed(2)}s';
  }

  String _methodEmoji(String method) => switch (method) {
        'GET' => '🔍',
        'POST' => '📤',
        'PUT' => '✏️',
        'PATCH' => '🩹',
        'DELETE' => '🗑️',
        'HEAD' => '👀',
        _ => '🌐',
      };

  String _statusEmoji(int status) => switch (status) {
        >= 200 && < 300 => '✅',
        >= 300 && < 400 => '↪️',
        >= 400 && < 500 => '⚠️',
        >= 500 => '💥',
        _ => '🛑',
      };
}
