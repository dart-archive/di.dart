library score_emitter;

import 'dart:convert';
import 'package:benchmark_harness/benchmark_harness.dart';

class StdoutScoreEmitter implements ScoreEmitter {
  void emit(String name, double value) {
    var map = {
               "module": "di",
               "name": name,
               "value": value
    };
    print(JSON.encode(map));
  }
}