#!/bin/sh -v

./test_tf_gen.sh
time dart --checked test/main.dart
time dart2js -c test/main.dart -o test/main.dart.js
time node test/main.dart.js
