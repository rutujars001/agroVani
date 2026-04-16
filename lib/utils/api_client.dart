import 'package:http/http.dart' as http;

const _ngrokHeader = {'ngrok-skip-browser-warning': 'true'};

Future<http.Response> apiGet(String url) =>
    http.get(Uri.parse(url), headers: _ngrokHeader);

Future<http.Response> apiPost(String url, {required String body}) =>
    http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', ..._ngrokHeader},
      body: body,
    );
