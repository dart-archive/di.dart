#!/bin/sh -v
# Runs type factories generator for test files.

dart bin/generator.dart $DART_SDK test/main.dart di.tests.Injectable test/type_factories_gen.dart packages/

