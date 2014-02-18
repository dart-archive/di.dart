library score_emitter;

import 'dart:convert';
import 'package:benchmark_harness/benchmark_harness.dart';

const DART_CONTEXT="dart";
const JS_CONTEXT="js";

class StdoutScoreEmitter implements ScoreEmitter {
  void emit(String name, double value) {
    var map = {
               "module": "di",
               "name": name,
               "value": value,
               "context": _getContext()
    };
    print(JSON.encode(map));
  }

  String _getContext() {
    return 1.0 is int ? JS_CONTEXT : DART_CONTEXT;
  }
}