// Run this using Dart, already included with your installed Flutter SDK:
//   cd township_3d
//   dart run serve.dart
// No extra packages or npm installation needed.
// Optional live AI: set OPENAI_API_KEY in the terminal before launching.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

final baseDirectory = Directory.current;
final allowedFiles = <String, String>{
  '/': 'index.html',
  '/index.html': 'index.html',
  '/styles.css': 'styles.css',
  '/app.js': 'app.js',
  '/assistant.js': 'assistant.js',
  '/catalog.js': 'catalog.js',
  '/tool_models.js': 'tool_models.js',
  '/audio/township-theme.wav': 'audio/township-theme.wav',
  '/audio/pickup.wav': 'audio/pickup.wav',
  '/audio/return.wav': 'audio/return.wav',
  '/audio/open.wav': 'audio/open.wav',
  '/audio/step.wav': 'audio/step.wav',
  '/audio/success.wav': 'audio/success.wav',
};
const realToolNames = <String>[
  '4-step safety ladder',
  'Cordless drill-driver kit',
  'Wet & dry vacuum',
  'Carpet & upholstery cleaner',
  'Adjustable pressure washer',
  'Household steam cleaner',
  'Folding hand truck',
  'Furniture moving kit',
  'Laser distance measurer',
  'Self-leveling laser level',
  'Wall stud & wire detector',
  'Folding workbench',
  'Manual drain auger',
  'Portable dehumidifier',
  'Ground-reach window cleaning kit',
];

Future<void> sendJson(HttpResponse response, int status, Object value) async {
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  response.headers.set('Cache-Control', 'no-store');
  response.write(jsonEncode(value));
  await response.close();
}

Future<String?> requestLiveAI(String question, String key) async {
  const safety = 'If there may be dangerous wiring, electricity, gas, fire, severe mould or structural issues, tell the user to contact a professional. ';
  final instructions =
      'You are Tori, ToolVault township tool-rental guide. '
      'Use plain English and reply in at most 100 words. '
      'Recommend ONLY these existing tools: ${realToolNames.join(', ')}. '
      'Explain suitable tools and one concise safety precaution. '
      'Never claim a tool is available or that you booked anything; refer the user to the resident booking website. '
      '$safety'
      'Game instructions: WASD to walk; E anywhere away from the locker opens phone booking; E at the station opens pickup/return; Esc closes the application.';
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    final req = await client.postUrl(Uri.https('api.openai.com', '/v1/responses'));
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({
      'model': Platform.environment['OPENAI_MODEL'] ?? 'gpt-4.1-mini',
      'instructions': instructions,
      'input': question,
      'max_output_tokens': 220,
      'store': false,
    }));
    final res = await req.close().timeout(const Duration(seconds: 22));
    if (res.statusCode != 200) return null;
    final doc = jsonDecode(await utf8.decoder.bind(res).join());
    if (doc is! Map) return null;
    final output = doc['output'];
    if (output is! List) return null;
    final pieces = <String>[];
    for (final item in output) {
      if (item is! Map || item['content'] is! List) continue;
      for (final part in item['content'] as List) {
        if (part is Map && part['type'] == 'output_text' && part['text'] is String) {
          pieces.add(part['text'] as String);
        }
      }
    }
    final result = pieces.join(' ').trim();
    return result.isNotEmpty ? result : null;
  } catch (e) {
    stderr.writeln('Optional AI unavailable: ${e.runtimeType}');
    return null;
  } finally {
    client.close(force: true);
  }
}

Future<void> handle(HttpRequest request) async {
  try {
    final response = request.response;
    final path = request.uri.path;
    if (request.method == 'GET' && path == '/api/assistant/status') {
      final configured = (Platform.environment['OPENAI_API_KEY'] ?? '').trim().isNotEmpty;
      return sendJson(response, 200, {'live_ai': configured});
    }
    if (request.method == 'POST' && path == '/api/assistant') {
      if (request.contentLength > 4096) {
        return sendJson(response, 413, {'error': 'Message too long'});
      }
      final body = await utf8.decoder.bind(request).join();
      if (body.length > 4096) {
        return sendJson(response, 413, {'error': 'Message too long'});
      }
      final decoded = jsonDecode(body);
      final question = decoded is Map ? decoded['question'] : null;
      if (question is! String || question.trim().isEmpty || question.length > 500) {
        return sendJson(response, 400, {'error': 'Enter a question up to 500 characters'});
      }
      final key = (Platform.environment['OPENAI_API_KEY'] ?? '').trim();
      if (key.isEmpty) return sendJson(response, 200, {'live_ai': false, 'answer': null});
      final answer = await requestLiveAI(question, key);
      return sendJson(response, 200, {'live_ai': answer != null, 'answer': answer});
    }
    if (request.method != 'GET' || !allowedFiles.containsKey(path)) {
      response.statusCode = HttpStatus.notFound;
      response.write('Not found');
      return response.close();
    }
    final file = File('${baseDirectory.path}${Platform.pathSeparator}${allowedFiles[path]}');
    if (!await file.exists()) {
      response.statusCode = HttpStatus.notFound;
      return response.close();
    }
    if (path.endsWith('.wav')) {
      response.headers.contentType = ContentType('audio', 'wav');
    } else if (path.endsWith('.js')) {
      response.headers.contentType = ContentType('text', 'javascript', charset: 'utf-8');
    } else if (path.endsWith('.css')) {
      response.headers.contentType = ContentType('text', 'css', charset: 'utf-8');
    } else {
      response.headers.contentType = ContentType.html;
    }
    response.headers.set('Cache-Control', 'no-cache');
    await response.addStream(file.openRead());
    await response.close();
  } catch (error) {
    stderr.writeln('Request issue: ${error.runtimeType}');
    try {
      await sendJson(request.response, 500, {'error': 'Request failed'});
    } catch (_) {}
  }
}

Future<void> main() async {
  final port = int.tryParse(Platform.environment['TOOLVAULT_3D_PORT'] ?? '') ?? 5500;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('');
  print('ToolVault 3D is ready: http://localhost:$port');
  print('Resident Flutter: http://localhost:5000');
  print('Locker Flutter:   http://localhost:5001');
  print('Assistant: ${(Platform.environment['OPENAI_API_KEY'] ?? '').isNotEmpty ? 'Live AI API enabled' : 'Built-in local recommendations'}');
  print('Press Ctrl+C to stop the game server.');
  await for (final request in server) {
    unawaited(handle(request));
  }
}
