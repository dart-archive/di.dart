library score_emitter;

import 'dart:io';
import 'package:benchmark_harness/benchmark_harness.dart';

class HttpScoreEmitter implements ScoreEmitter {
  Uri endpoint;

  HttpScoreEmitter(this.endpoint) {}

  void emit(value) {
    HttpClient client = new HttpClient();
    client.openUrl('POST', endpoint)
      .then((HttpClientRequest request) {
        request.write('{"value": ${value}}');
        return request.close();
      }).then((HttpClientResponse response) {
        print("Status code: ${response.statusCode}");
        client.close(force: true);
      });
  }
}